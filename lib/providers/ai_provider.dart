import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ai_settings_model.dart';
import '../models/todo_model.dart';
import '../models/pomodoro_model.dart';
import '../models/statistics_model.dart';
import '../services/ai_service.dart';
import '../services/ai_cache_service.dart';
import '../services/hive_service.dart';
import '../services/secure_storage_service.dart';
import '../services/repositories/ai_settings_repository.dart';
import 'language_provider.dart';

class AIProvider extends ChangeNotifier {
  AISettingsModel _settings = AISettingsModel.create();
  AIService? _aiService;
  final AICacheService _cacheService = AICacheService();
  final SecureStorageService _secureStorageService = SecureStorageService();
  final AISettingsRepository _settingsRepository = AISettingsRepository();
  LanguageProvider? _languageProvider;

  bool _isLoading = false;
  String? _lastError;
  final Map<String, String> _currentMotivationalMessages = {};
  final Map<String, String> _currentCompletionMessages = {};
  bool _isInitializing =
      false; // Flag to prevent processing during initialization

  Timer? _debugUpdateTimer;

  AIProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadSettings();
    await _initCache();
  }

  void startDebugUpdates() {
    _debugUpdateTimer?.cancel();
    _debugUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners(); // Notify listeners to refresh debug info
    });
  }

  void stopDebugUpdates() {
    _debugUpdateTimer?.cancel();
    _debugUpdateTimer = null;
  }

  Future<void> _loadSettings() async {
    try {
      _isInitializing = true; // Set initialization flag
      final box = HiveService().aiSettingsBox;
      final hasSavedSettings = box.containsKey(AISettingsRepository.hiveKey);
      final savedSettings =
          box.get(AISettingsRepository.hiveKey) ?? AISettingsModel.create();

      final apiKeyFromHive = savedSettings.apiKey;
      final apiKeyFromSecureStorage = await _secureStorageService
          .readAiApiKey();

      final resolvedApiKey = (apiKeyFromSecureStorage ?? '').isNotEmpty
          ? apiKeyFromSecureStorage!
          : apiKeyFromHive;

      if ((apiKeyFromSecureStorage ?? '').isEmpty &&
          apiKeyFromHive.isNotEmpty) {
        await _secureStorageService.writeAiApiKey(apiKeyFromHive);
      }

      if (apiKeyFromHive.isNotEmpty) {
        await _settingsRepository.save(savedSettings.copyWith(apiKey: ''));
      }

      if (!hasSavedSettings) {
        debugPrint('AIProvider: No saved settings found, using defaults');
      }

      updateSettings(savedSettings.copyWith(apiKey: resolvedApiKey));
      _isInitializing = false; // Clear initialization flag
    } catch (e) {
      debugPrint('AIProvider: Error loading settings: $e');
      // If there's a type error (likely due to model changes), clear the corrupted settings
      if (e.toString().contains('type cast') ||
          e.toString().contains('subtype')) {
        debugPrint(
          'AIProvider: Settings corrupted, clearing and using defaults',
        );
        await _clearCorruptedSettings();
      }
      // Initialize with default settings even if loading fails
      updateSettings(_settings);
      _isInitializing = false; // Clear initialization flag on error
    }
  }

  Future<void> reloadFromHive() async {
    await _loadSettings();
  }

  Future<void> _clearCorruptedSettings() async {
    try {
      final box = HiveService().aiSettingsBox;
      await box.clear();
      debugPrint('AIProvider: Corrupted settings cleared');
    } catch (e) {
      debugPrint('AIProvider: Error clearing corrupted settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final apiKey = _settings.apiKey.trim();
      if (apiKey.isEmpty) {
        await _secureStorageService.deleteAiApiKey();
      } else {
        await _secureStorageService.writeAiApiKey(apiKey);
      }

      await _settingsRepository.save(_settings.copyWith(apiKey: ''));
    } catch (e) {
      debugPrint('AIProvider: Error saving settings: $e');
    }
  }

  Future<void> _initCache() async {
    try {
      await _cacheService.init();
      debugPrint('AIProvider: Cache service initialized successfully');
    } catch (e) {
      debugPrint('AIProvider: Error initializing cache service: $e');
    }
  }

  // Ensure cache is initialized before use
  Future<void> _ensureCacheInitialized() async {
    if (!_cacheService.isInitialized) {
      await _initCache();
    }
  }

  AISettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  Map<String, String> get motivationalMessages => _currentMotivationalMessages;
  Map<String, String> get completionMessages => _currentCompletionMessages;
  bool get isAIServiceValid => _settings.isValid && _aiService != null;
  AIService? get aiService => _aiService;

  void updateSettings(AISettingsModel newSettings) {
    updateSettingsWithContext(newSettings);
  }

  void updateSettingsWithContext(
    AISettingsModel newSettings, {
    BuildContext? context,
  }) {
    final oldSettings = _settings;
    _settings = newSettings;

    if (_settings.isValid) {
      _aiService = AIService(_settings, context: context);
    } else {
      _aiService = null;
      debugPrint('AIProvider: AI service set to null (settings invalid)');
    }

    // Save settings to disk
    _saveSettings();

    // Check if categorization was enabled (skip during initialization)
    if (_settings.enableAutoCategorization &&
        !oldSettings.enableAutoCategorization &&
        !_isInitializing) {
      debugPrint(
        'AIProvider: Categorization enabled, processing unprocessed tasks',
      );
      _processMissingCategorization();
    }

    // Check if priority sorting was enabled (skip during initialization)
    if (_settings.enablePrioritySorting &&
        !oldSettings.enablePrioritySorting &&
        !_isInitializing) {
      debugPrint(
        'AIProvider: Priority sorting enabled, processing unprocessed tasks',
      );
      _processMissingPriority();
    }

    // Check if motivational messages setting changed (skip during initialization)
    if (_settings.enableMotivationalMessages !=
            oldSettings.enableMotivationalMessages &&
        !_isInitializing) {
      debugPrint(
        'AIProvider: Motivational messages setting changed, clearing cache',
      );
      clearMotivationalMessageCache();
    }

    // Check if AI features setting changed (which affects motivational messages)
    if (_settings.enableAIFeatures != oldSettings.enableAIFeatures &&
        !_isInitializing) {
      clearMotivationalMessageCache();
    }

    // Check if custom persona prompt changed (which affects motivational messages and smart notifications)
    if (_settings.customPersonaPrompt != oldSettings.customPersonaPrompt &&
        !_isInitializing) {
      debugPrint(
        'AIProvider: Custom persona prompt changed, clearing all AI cache',
      );
      clearAllAICache();
    }

    notifyListeners();
  }

  void setLanguageProvider(LanguageProvider languageProvider) {
    _languageProvider = languageProvider;
  }

  // Method to update AI service context (call when context becomes available)
  void updateAIServiceContext(BuildContext context) {
    if (_aiService != null) {
      _aiService!.updateContext(context);
    }
  }

  // Clear motivational message cache (call when language changes or settings are toggled)
  Future<void> clearMotivationalMessageCache() async {
    try {
      await _cacheService.clearMotivationalMessages();
      _currentMotivationalMessages.clear();
      _currentCompletionMessages.clear();
      debugPrint(
        'AIProvider: Cleared motivational message cache and in-memory messages',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('AIProvider: Error clearing motivational message cache: $e');
    }
  }

  // Clear all AI cache (call when persona changes or other major settings change)
  Future<void> clearAllAICache() async {
    try {
      await _cacheService.clearAllAICache();
      _currentMotivationalMessages.clear();
      _currentCompletionMessages.clear();
      debugPrint('AIProvider: Cleared all AI cache and in-memory messages');
      notifyListeners();
    } catch (e) {
      debugPrint('AIProvider: Error clearing all AI cache: $e');
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // Process missing categorization for tasks when enabled
  void _processMissingCategorization() {
    // This will be called from TodoProvider via a callback
    // to process tasks that are missing categories
    onProcessMissingCategorization?.call();
  }

  // Process missing priority for tasks when enabled
  void _processMissingPriority() {
    // This will be called from TodoProvider via a callback
    // to process tasks that are missing priorities
    onProcessMissingPriority?.call();
  }

  // Callbacks for TodoProvider to handle missing information
  VoidCallback? onProcessMissingCategorization;
  VoidCallback? onProcessMissingPriority;

  Future<bool> testConnection() async {
    if (!isAIServiceValid) {
      _lastError = 'AI service not configured';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Use the existing AI service instance for testing
      final response = await _aiService!.testConnection('en');

      if (response != null) {
        _lastError = null;
        return true;
      } else {
        _lastError = 'No response from AI service';
        return false;
      }
    } catch (e) {
      _lastError = 'Connection test failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> categorizeTask(
    TodoModel todo, {
    bool forceRefresh = false,
  }) async {
    if (!_settings.enableAutoCategorization || !isAIServiceValid) {
      return null;
    }

    // For completed todos, always prefer cached data to avoid unnecessary API calls
    if (todo.isCompleted && !forceRefresh) {
      // Return existing category if available
      if (todo.aiCategory != null && todo.aiCategory!.isNotEmpty) {
        return todo.aiCategory;
      }
    }

    await _ensureCacheInitialized();

    final languageCode = Intl.getCurrentLocale();
    final cacheKey = AICacheService.getCategorizationKey(
      todo.title,
      todo.description ?? '',
      languageCode,
    );

    if (!forceRefresh) {
      final cached = await _cacheService.get<String>(cacheKey);
      if (cached != null) return cached;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final category = await _aiService!.categorizeTask(todo, languageCode);

      if (category != null) {
        await _cacheService.set(cacheKey, category);
        _lastError = null;
        return category;
      } else {
        _lastError = 'Failed to categorize task';
        return null;
      }
    } catch (e) {
      _lastError = 'Error categorizing task: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int?> assessPriority(
    TodoModel todo, {
    bool forceRefresh = false,
  }) async {
    if (!_settings.enablePrioritySorting || !isAIServiceValid) {
      return null;
    }

    // For completed todos, always prefer cached data to avoid unnecessary API calls
    if (todo.isCompleted && !forceRefresh) {
      // Return existing priority if available
      if (todo.aiPriority > 0) {
        return todo.aiPriority;
      }
    }

    await _ensureCacheInitialized();

    final languageCode = Intl.getCurrentLocale();
    final cacheKey = AICacheService.getPriorityKey(
      todo.title,
      todo.description ?? '',
      languageCode,
      hasDeadline: todo.reminderTime != null,
    );

    if (!forceRefresh) {
      final cached = await _cacheService.get<int>(cacheKey);
      if (cached != null) return cached;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final priority = await _aiService!.assessPriority(todo, languageCode);

      if (priority != null) {
        await _cacheService.set(cacheKey, priority);
        _lastError = null;
        return priority;
      } else {
        _lastError = 'Failed to assess priority';
        return null;
      }
    } catch (e) {
      _lastError = 'Error assessing priority: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generateMotivationalMessage(
    StatisticsModel statistics, {
    bool forceRefresh = false,
    String? languageCode,
  }) async {
    if (!_settings.enableMotivationalMessages || !isAIServiceValid) {
      return null;
    }

    await _ensureCacheInitialized();

    final effectiveLanguageCode =
        languageCode ??
        _languageProvider?.currentLanguageCode ??
        Intl.getCurrentLocale();
    final cacheKey = AICacheService.getMotivationKey(
      'Daily Progress',
      'Task completion rate: ${statistics.completionRate.toStringAsFixed(1)}%',
      statistics.completionRate,
      effectiveLanguageCode,
    );

    if (!forceRefresh) {
      final cached = await _cacheService.get<String>(cacheKey);
      if (cached != null) {
        _currentMotivationalMessages[statistics.date.toIso8601String()] =
            cached;
        notifyListeners();
        return cached;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final message = await _aiService!.generateMotivationalMessage(
        statistics,
        effectiveLanguageCode,
      );

      if (message != null) {
        await _cacheService.set(cacheKey, message);
        _currentMotivationalMessages[statistics.date.toIso8601String()] =
            message;
        _lastError = null;
        return message;
      } else {
        _lastError = 'Failed to generate motivational message';
        return null;
      }
    } catch (e) {
      _lastError = 'Error generating motivational message: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generateSmartNotification(
    TodoModel todo, {
    bool forceRefresh = false,
    String? languageCode,
    BuildContext? context,
  }) async {
    if (!_settings.enableSmartNotifications || !isAIServiceValid) {
      return null;
    }

    // Update AI service context if provided
    if (context != null) {
      _aiService!.updateContext(context);
    }

    await _ensureCacheInitialized();

    final effectiveLanguageCode =
        languageCode ??
        _languageProvider?.currentLanguageCode ??
        Intl.getCurrentLocale();
    final cacheKey = AICacheService.getNotificationKey(
      todo.title,
      todo.aiCategory ?? 'general',
      todo.aiPriority,
      effectiveLanguageCode,
      reminderTime: todo.reminderTime,
    );

    if (!forceRefresh) {
      final cached = await _cacheService.get<String>(cacheKey);
      if (cached != null) return cached;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final message = await _aiService!.generateSmartNotification(
        todo,
        effectiveLanguageCode,
      );

      if (message != null) {
        await _cacheService.set(cacheKey, message);
        _lastError = null;
        return message;
      } else {
        _lastError = 'Failed to generate smart notification';
        return null;
      }
    } catch (e) {
      _lastError = 'Error generating smart notification: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generateDailySummary(
    List<TodoModel> todos, {
    bool forceRefresh = false,
    String? languageCode,
  }) async {
    if (!_settings.enableSmartNotifications || !isAIServiceValid) {
      debugPrint(
        'AIProvider: Smart notifications disabled or AI service invalid, skipping daily summary generation',
      );
      return null;
    }

    if (todos.isEmpty) {
      debugPrint(
        'AIProvider: No todos to summarize, skipping daily summary generation',
      );
      return null;
    }

    await _ensureCacheInitialized();

    final effectiveLanguageCode =
        languageCode ??
        _languageProvider?.currentLanguageCode ??
        Intl.getCurrentLocale();

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint(
        'AIProvider: Generating daily summary for ${todos.length} todos',
      );
      final message = await _aiService!.generateDailySummary(
        todos,
        effectiveLanguageCode,
      );

      if (message != null) {
        _lastError = null;
        debugPrint('AIProvider: Daily summary generated successfully');
        return message;
      } else {
        _lastError = 'Failed to generate daily summary';
        debugPrint('AIProvider: Failed to generate daily summary');
        return null;
      }
    } catch (e) {
      _lastError = 'Error generating daily summary: $e';
      debugPrint('AIProvider: Error generating daily summary: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generateIncentiveMessage(
    int completed,
    int total, {
    bool forceRefresh = false,
    String? languageCode,
  }) async {
    if (!_settings.enableAIFeatures || !isAIServiceValid) {
      return 'AI features not enabled, please enable AI features to get personalized incentive messages';
    }

    try {
      await _ensureCacheInitialized();
    } catch (e) {
      debugPrint('AIProvider: Cache initialization failed: $e');
      _lastError = 'Cache initialization failed';
      return null;
    }

    final effectiveLanguageCode =
        languageCode ??
        _languageProvider?.currentLanguageCode ??
        Intl.getCurrentLocale();

    final completionRate = total > 0 ? (completed / total) * 100.0 : 0.0;
    final cacheKey = AICacheService.getIncentiveMessageKey(
      completionRate,
      effectiveLanguageCode,
    );

    if (!forceRefresh) {
      try {
        final cached = await _cacheService.getIncentiveMessage<String>(
          cacheKey,
        );
        if (cached != null) {
          // Only update if the message is different to avoid unnecessary rebuilds
          if (_currentCompletionMessages['${completed}_$total'] != cached) {
            _currentCompletionMessages['${completed}_$total'] = cached;
            notifyListeners();
          }
          return cached;
        }
      } catch (e) {
        // Error reading cached message
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final message = await _aiService!.generateIncentiveMessage(
        completed,
        total,
        effectiveLanguageCode,
      );

      if (message != null && message.isNotEmpty) {
        await _cacheService.setIncentiveMessage(cacheKey, message);
        _currentCompletionMessages['${completed}_$total'] = message;
        _lastError = null;
        return message;
      } else {
        _lastError = 'AI service returned empty message';
        return null;
      }
    } catch (e) {
      _lastError = 'Error generating incentive message: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearIncentiveMessageCache() async {
    await _ensureCacheInitialized();
    await _cacheService.clearIncentiveMessages();
    _currentCompletionMessages.clear();
    notifyListeners();
  }

  Future<String?> generatePomodoroNotification(
    PomodoroModel session, {
    String? languageCode,
  }) async {
    if (!_settings.enableSmartNotifications || !isAIServiceValid) {
      debugPrint(
        'AIProvider: Smart notifications disabled or AI service invalid, skipping pomodoro notification generation',
      );
      return null;
    }

    final effectiveLanguageCode =
        languageCode ??
        _languageProvider?.currentLanguageCode ??
        Intl.getCurrentLocale();

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint(
        'AIProvider: Generating pomodoro notification for session ${session.id}',
      );
      final message = await _aiService!.generatePomodoroNotification(
        session,
        effectiveLanguageCode,
      );

      if (message != null && message.isNotEmpty) {
        _lastError = null;
        return message;
      } else {
        _lastError = 'AI service returned empty message';
        return null;
      }
    } catch (e) {
      _lastError = 'Error generating pomodoro notification: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> preparePomodoroNotification(
    PomodoroModel session, {
    String? languageCode,
    String? todoTitle,
  }) async {
    if (!_settings.enableSmartNotifications || !isAIServiceValid) {
      debugPrint(
        'AIProvider: ❌ Smart notifications disabled or AI service invalid, skipping pomodoro notification preparation',
      );
      return null;
    }

    final effectiveLanguageCode =
        languageCode ??
        _languageProvider?.currentLanguageCode ??
        Intl.getCurrentLocale();

    // Don't show loading state for preparation since it's done in background
    try {
      final message = await _aiService!.preparePomodoroNotification(
        session,
        effectiveLanguageCode,
        todoTitle,
      );

      if (message != null && message.isNotEmpty) {
        debugPrint(
          'AIProvider: ✅ AI service returned message (${message.length} chars)',
        );
        _lastError = null;
        return message;
      } else {
        debugPrint('AIProvider: ❌ AI service returned empty message');
        _lastError = 'AI service returned empty message';
        return null;
      }
    } catch (e) {
      debugPrint('AIProvider: ❌ Error preparing pomodoro notification: $e');
      _lastError = 'Error preparing pomodoro notification: $e';
      return null;
    }
    // No finally block with notifyListeners since this is background preparation
  }

  Future<Map<String, dynamic>> processTasksBatch(List<TodoModel> tasks) async {
    if (!isAIServiceValid || tasks.isEmpty) {
      return {};
    }

    _isLoading = true;
    notifyListeners();

    try {
      final languageCode = Intl.getCurrentLocale();

      if (!isAIServiceValid) {
        debugPrint('AIProvider: AI service not valid, returning empty results');
        return {};
      }

      final results = await _aiService!.processTasksBatch(tasks, languageCode);

      // Cache individual results
      for (final entry in results.entries) {
        try {
          final taskId = entry.key;
          final result = entry.value as Map<String, dynamic>?;

          if (result == null) continue;

          final todo = tasks.firstWhere(
            (t) => t.id == taskId,
            orElse: () => tasks.first,
          );

          if (result['category'] != null) {
            final cacheKey = AICacheService.getCategorizationKey(
              todo.title,
              todo.description ?? '',
              languageCode,
            );
            await _cacheService.set(cacheKey, result['category']);
          }

          if (result['priority'] != null) {
            final cacheKey = AICacheService.getPriorityKey(
              todo.title,
              todo.description ?? '',
              languageCode,
              hasDeadline: todo.reminderTime != null,
            );
            await _cacheService.set(cacheKey, result['priority']);
          }
        } catch (e) {
          debugPrint('Error caching AI result: $e');
          continue;
        }
      }

      _lastError = null;
      return results;
    } catch (e, stackTrace) {
      debugPrint('AIProvider: Error in processTasksBatch: $e');
      debugPrint('AIProvider: Stack trace: $stackTrace');
      _lastError = 'Error processing tasks batch: $e';
      return {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCache() async {
    await _cacheService.clear();
    _currentMotivationalMessages.clear();
    _currentCompletionMessages.clear();
    notifyListeners();
  }

  Map<String, dynamic> getRequestManagerStats() {
    if (_aiService == null) return {};
    return _aiService!.getRequestManagerStats();
  }

  List<Map<String, dynamic>> getRequestQueueInfo() {
    if (_aiService == null) return [];
    return _aiService!.getRequestQueueInfo();
  }

  List<Map<String, dynamic>> getRecentRequests() {
    if (_aiService == null) return [];
    return _aiService!.getRecentRequests();
  }

  @override
  void dispose() {
    stopDebugUpdates();
    _aiService?.dispose();
    _cacheService.close();
    super.dispose();
  }
}
