import 'package:flutter/material.dart';
import 'dart:async';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/models/statistics_model.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/models/statistics_data_model.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/cache_service.dart';
import 'package:easy_todo/services/ai_cache_service.dart';
import 'package:easy_todo/services/notification_service.dart';
import 'package:easy_todo/providers/filter_provider.dart';
import 'package:easy_todo/providers/ai_provider.dart';
import 'package:easy_todo/providers/language_provider.dart';
import 'package:easy_todo/utils/ai_status_constants.dart';
import 'package:easy_todo/utils/date_utils.dart';
import 'package:easy_todo/utils/repeat_backfill_utils.dart';
import 'package:easy_todo/services/sync_write_service.dart';
import 'package:easy_todo/utils/hlc_clock.dart';
import 'package:easy_todo/services/repositories/todo_repository.dart';
import 'package:easy_todo/services/repositories/repeat_todo_repository.dart';
import 'package:easy_todo/services/repositories/statistics_data_repository.dart';

class TodoProvider extends ChangeNotifier {
  final HiveService _hiveService = HiveService();
  final NotificationService _notificationService = NotificationService();
  final AICacheService _aiCacheService = AICacheService();
  final SyncWriteService _syncWriteService = SyncWriteService();
  final TodoRepository _todoRepository = TodoRepository();
  final RepeatTodoRepository _repeatTodoRepository = RepeatTodoRepository();
  final StatisticsDataRepository _statisticsDataRepository =
      StatisticsDataRepository();
  AIProvider? _aiProvider;
  LanguageProvider? _languageProvider;
  List<TodoModel> _todos = [];
  final Set<String> _processingTodos = {};
  final Map<String, DateTime> _failedAiRequests = {};
  final Map<String, DateTime> _lastRequestTime = {};
  final Map<String, Timer> _debounceTimers = {};
  DateTime? _lastRateLimitError;

  AIProvider? get aiProvider => _aiProvider;
  List<TodoModel> _filteredTodos = [];
  List<StatisticsModel> _statistics = [];
  List<RepeatTodoModel> _repeatTodos = [];
  List<StatisticsDataModel> _statisticsData = [];
  DateTime? _lastRepeatCheck;
  Future<void> _repeatOperation = Future.value();

  // AI processing tracking for repeat todos
  final Set<String> _processingRepeatTodos = {};
  final Map<String, bool> _repeatTodoAILoading = {};
  final Map<String, String> _repeatTodoAIStatus = {};

  // 获取本地时间的辅助方法 (直接使用系统时间)
  DateTime _getLocalDateTime() {
    final systemTime = DateTime.now();
    // debugPrint('System time: $systemTime (timezone offset: ${systemTime.timeZoneOffset}, timezone name: ${systemTime.timeZoneName})');
    return systemTime;
  }

  String _repeatGeneratedKey(String repeatTodoId, DateTime date) {
    final local = localDay(date);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$repeatTodoId:$y$m$d';
  }

  Future<void> _putTodo(TodoModel todo) async {
    await _todoRepository.upsert(todo);
  }

  Future<void> _tombstoneTodo(String todoId) async {
    await _todoRepository.tombstone(todoId);
  }

  Future<void> _putRepeatTodo(RepeatTodoModel repeatTodo) async {
    await _repeatTodoRepository.upsert(repeatTodo);
  }

  Future<void> _tombstoneRepeatTodo(String repeatTodoId) async {
    await _repeatTodoRepository.tombstone(repeatTodoId);
  }

  Future<void> _putStatisticsData(StatisticsDataModel data) async {
    await _statisticsDataRepository.upsert(data);
  }

  Future<void> _tombstoneStatisticsData(String id) async {
    await _statisticsDataRepository.tombstone(id);
  }

  Future<void> _hydrateRepeatGenerationStateIfNeeded() async {
    final todosBox = _hiveService.todosBox;
    if (_todos.isEmpty && todosBox.isNotEmpty) {
      _todos = todosBox.values.toList();
      _todos = _todos
          .where(
            (t) => !_syncWriteService.isTombstonedSync(SyncTypes.todo, t.id),
          )
          .toList();
      _todos.sort((a, b) => a.order.compareTo(b.order));
      _applyFilters();
    }

    final repeatTodosBox = _hiveService.repeatTodosBox;
    if (_repeatTodos.isEmpty && repeatTodosBox.isNotEmpty) {
      _repeatTodos = repeatTodosBox.values.toList();
      _repeatTodos = _repeatTodos
          .where(
            (t) =>
                !_syncWriteService.isTombstonedSync(SyncTypes.repeatTodo, t.id),
          )
          .toList();
      _repeatTodos.sort((a, b) => a.order.compareTo(b.order));
    }
  }

  Future<T> _enqueueRepeatOperation<T>(Future<T> Function() operation) {
    final next = _repeatOperation.then((_) => operation());
    _repeatOperation = next.then((_) {}, onError: (_) {});
    return next;
  }

  bool _isLoading = false;
  bool _isProcessingCategories = false;
  bool _isProcessingPriorities = false;
  String _searchQuery = '';
  TodoFilter _currentFilter = TodoFilter.active;
  DateTimeRange? _dateRange;
  SortOrder _sortOrder = SortOrder.timeAscending;
  Set<String> _selectedCategories = {};

  TodoProvider() {
    // 延迟初始化以避免在构建期间调用 notifyListeners()
    Future.delayed(Duration.zero, () async {
      // 初始化AI缓存服务
      await _aiCacheService.init();

      loadTodos();
      loadRepeatTodos();
      loadStatistics();
      loadStatisticsData();
      // 验证和恢复丢失的AI标签 - 仅在AI服务可用且功能启用时
      if (_aiProvider != null && _aiProvider!.isAIServiceValid) {
        _verifyAndRestoreAILabels();
      }
    });
  }

  void syncWithFilterProvider(FilterProvider filterProvider) {
    _currentFilter = filterProvider.statusFilter;
    _sortOrder = filterProvider.sortOrder;
    _selectedCategories = filterProvider.selectedCategories;

    // Set time filter based on the time filter from FilterProvider
    switch (filterProvider.timeFilter) {
      case TimeFilter.all:
        clearTimeFilter();
        break;
      case TimeFilter.today:
        setTimeFilter(TimeFilter.today);
        break;
      case TimeFilter.yesterday:
        setTimeFilter(TimeFilter.yesterday);
        break;
      case TimeFilter.threeDays:
        setTimeFilter(TimeFilter.threeDays);
        break;
      case TimeFilter.week:
        setTimeFilter(TimeFilter.week);
        break;
      case TimeFilter.month:
        setTimeFilter(TimeFilter.month);
        break;
    }
  }

  List<TodoModel> get todos => _filteredTodos;
  List<TodoModel> get allTodos => _todos;
  List<RepeatTodoModel> get repeatTodos => _repeatTodos;
  List<StatisticsModel> get statistics => _statistics;
  List<StatisticsDataModel> get statisticsData => _statisticsData;
  bool get isLoading => _isLoading;
  bool get isProcessingCategories => _isProcessingCategories;
  bool get isProcessingPriorities => _isProcessingPriorities;
  String get searchQuery => _searchQuery;
  TodoFilter get currentFilter => _currentFilter;
  DateTimeRange? get dateRange => _dateRange;
  SortOrder get sortOrder => _sortOrder;
  Set<String> get selectedCategories => _selectedCategories;

  // AI processing status getters
  bool isRepeatTodoProcessingAI(String repeatTodoId) =>
      _processingRepeatTodos.contains(repeatTodoId);
  bool isRepeatTodoAILoading(String repeatTodoId) =>
      _repeatTodoAILoading[repeatTodoId] ?? false;
  String? getRepeatTodoAIStatus(String repeatTodoId) =>
      _repeatTodoAIStatus[repeatTodoId];
  bool isAnyRepeatTodoProcessingAI() => _processingRepeatTodos.isNotEmpty;

  int get activeTodosCount => _todos.where((todo) => !todo.isCompleted).length;
  int get completedTodosCount =>
      _todos.where((todo) => todo.isCompleted).length;
  double get completionRate =>
      _todos.isNotEmpty ? (completedTodosCount / _todos.length) * 100 : 0.0;

  void setAIProvider(AIProvider aiProvider) {
    _aiProvider = aiProvider;

    // Set up callbacks for processing missing information when settings change
    _aiProvider!.onProcessMissingCategorization = () {
      unawaited(processMissingCategorization());
    };

    _aiProvider!.onProcessMissingPriority = () {
      unawaited(processMissingPriority());
    };
  }

  void setLanguageProvider(LanguageProvider languageProvider) {
    _languageProvider = languageProvider;
  }

  // Verify and restore AI labels that may have been lost due to persistence issues
  Future<void> _verifyAndRestoreAILabels() async {
    if (_aiProvider != null) {}

    bool needsUpdate = false;

    // Skip if AI provider is not available
    if (_aiProvider == null) {
      return;
    }

    for (int i = 0; i < _todos.length; i++) {
      final todo = _todos[i];

      // Skip completed todos - they don't need AI processing
      if (todo.isCompleted) {
        continue;
      }

      // 修复：对重复生成的任务，如果AI数据不一致，直接从重复任务源恢复
      if (todo.isGeneratedFromRepeat && todo.repeatTodoId != null) {
        if (todo.aiProcessed &&
            (todo.aiCategory == null || todo.aiPriority == 0)) {
          // 尝试从重复任务恢复AI数据
          RepeatTodoModel? repeatTodo;
          try {
            repeatTodo = _repeatTodos.firstWhere(
              (rt) => rt.id == todo.repeatTodoId,
            );
          } catch (e) {
            repeatTodo = RepeatTodoModel.create(
              title: '',
              repeatType: RepeatType.daily,
            );
          }

          // 只有当重复任务有有效AI数据时才恢复
          if (repeatTodo.aiProcessed &&
              repeatTodo.aiCategory != null &&
              repeatTodo.aiPriority > 0) {
            final restoredTodo = todo.copyWith(
              aiCategory: repeatTodo.aiCategory,
              aiPriority: repeatTodo.aiPriority,
              aiProcessed: true,
            );

            await _putTodo(restoredTodo);
            _todos[i] = restoredTodo;
            needsUpdate = true;
          } else {}
        }
        continue; // 跳过重复生成任务的其他处理
      }

      // Check if todo has AI processed flag but missing AI data
      if (todo.aiProcessed &&
          (todo.aiCategory == null || todo.aiPriority == 0)) {
        // Only reset if we're missing data for enabled features
        final needsCategory =
            _aiProvider!.settings.enableAutoCategorization &&
            (todo.aiCategory == null || todo.aiCategory!.isEmpty);
        final needsPriority =
            _aiProvider!.settings.enablePrioritySorting &&
            (todo.aiPriority == 0);

        if (needsCategory || needsPriority) {
          // Reset aiProcessed flag only for missing enabled features
          final resetTodo = todo.copyWith(aiProcessed: false);
          await _putTodo(resetTodo);
          _todos[i] = resetTodo;
          needsUpdate = true;
        } else {
          // If features are disabled but data is partially missing, mark as processed with existing data
          final resetTodo = todo.copyWith(aiProcessed: true);
          await _putTodo(resetTodo);
          _todos[i] = resetTodo;
          needsUpdate = true;
        }
        continue;
      }

      // Try to restore missing AI data for incomplete todos
      // Additional check: only process if actually missing required data
      final needsCategory =
          _aiProvider!.settings.enableAutoCategorization &&
          (todo.aiCategory == null || todo.aiCategory!.isEmpty);
      final needsPriority =
          _aiProvider!.settings.enablePrioritySorting && (todo.aiPriority == 0);

      if (!todo.aiProcessed &&
          (needsCategory || needsPriority) &&
          _aiProvider!.isAIServiceValid) {
        try {
          String? restoredCategory = todo.aiCategory;
          int? restoredPriority = todo.aiPriority;
          bool madeChanges = false;

          // Only process if we actually need something that's enabled (already checked in if condition)
          if (needsCategory || needsPriority) {
            // Try to restore category if missing and categorization is enabled
            if (_aiProvider!.settings.enableAutoCategorization &&
                (todo.aiCategory == null || todo.aiCategory!.isEmpty)) {
              final category = await _aiProvider!.categorizeTask(
                todo,
                forceRefresh: false,
              );
              if (category != null && category.isNotEmpty) {
                restoredCategory = category;
                madeChanges = true;
              }
            }

            // Try to restore priority if missing and priority sorting is enabled
            if (_aiProvider!.settings.enablePrioritySorting &&
                (todo.aiPriority == 0)) {
              final priority = await _aiProvider!.assessPriority(
                todo,
                forceRefresh: false,
              );
              if (priority != null && priority > 0) {
                restoredPriority = priority;
                madeChanges = true;
              }
            }

            // Only update if we actually restored something
            if (madeChanges) {
              // Mark as processed only if the enabled features are successfully restored
              final categoryOk =
                  !_aiProvider!.settings.enableAutoCategorization ||
                  restoredCategory?.isNotEmpty == true;
              final priorityOk =
                  !_aiProvider!.settings.enablePrioritySorting ||
                  restoredPriority > 0;

              final updatedTodo = todo.copyWith(
                aiCategory: restoredCategory,
                aiPriority: restoredPriority,
                aiProcessed: categoryOk && priorityOk,
              );

              await _putTodo(updatedTodo);
              _todos[i] = updatedTodo;
              needsUpdate = true;
            }
          } else {
            // No features need processing, mark as processed with existing data
            if (!todo.aiProcessed) {
              final updatedTodo = todo.copyWith(aiProcessed: true);
              await _putTodo(updatedTodo);
              _todos[i] = updatedTodo;
              needsUpdate = true;
            }
          }
        } catch (e) {
          debugPrint(
            'TodoProvider: Error restoring AI data for todo "${todo.title}": $e',
          );
        }
      }
    }

    if (needsUpdate) {
      _applyFilters();
      notifyListeners();
    }

    // Now verify and restore AI labels for repeat todos
    await _verifyAndRestoreRepeatTodoAILabels();
  }

  // Verify and restore AI labels for repeat todos
  Future<void> _verifyAndRestoreRepeatTodoAILabels() async {
    bool needsUpdate = false;

    // Skip if AI provider is not available
    if (_aiProvider == null) {
      return;
    }

    for (int i = 0; i < _repeatTodos.length; i++) {
      final repeatTodo = _repeatTodos[i];

      // Check if repeat todo has AI processed flag but missing AI data
      if (repeatTodo.aiProcessed &&
          (repeatTodo.aiCategory == null || repeatTodo.aiPriority == 0)) {
        // Only reset if we're missing data for enabled features
        final needsCategory =
            _aiProvider!.settings.enableAutoCategorization &&
            (repeatTodo.aiCategory == null || repeatTodo.aiCategory!.isEmpty);
        final needsPriority =
            _aiProvider!.settings.enablePrioritySorting &&
            (repeatTodo.aiPriority == 0);

        if (needsCategory || needsPriority) {
          // Reset aiProcessed flag only for missing enabled features
          final resetRepeatTodo = repeatTodo.copyWith(aiProcessed: false);
          await _putRepeatTodo(resetRepeatTodo);
          _repeatTodos[i] = resetRepeatTodo;
          needsUpdate = true;
        } else {
          // If features are disabled but data is partially missing, mark as processed with existing data
          final resetRepeatTodo = repeatTodo.copyWith(aiProcessed: true);
          await _putRepeatTodo(resetRepeatTodo);
          _repeatTodos[i] = resetRepeatTodo;
          needsUpdate = true;
        }
        continue;
      }

      // Try to restore missing AI data for incomplete repeat todos
      // Additional check: only process if actually missing required data
      final needsCategory =
          _aiProvider!.settings.enableAutoCategorization &&
          (repeatTodo.aiCategory == null || repeatTodo.aiCategory!.isEmpty);
      final needsPriority =
          _aiProvider!.settings.enablePrioritySorting &&
          (repeatTodo.aiPriority == 0);

      if (!repeatTodo.aiProcessed &&
          (needsCategory || needsPriority) &&
          _aiProvider!.isAIServiceValid) {
        // Set UI status for startup processing
        _repeatTodoAILoading[repeatTodo.id] = true;
        _repeatTodoAIStatus[repeatTodo.id] = AIStatusConstants.processingAI;
        _processingRepeatTodos.add(repeatTodo.id);
        notifyListeners();

        try {
          String? restoredCategory = repeatTodo.aiCategory;
          int? restoredPriority = repeatTodo.aiPriority;
          bool madeChanges = false;

          // Only process if we actually need something that's enabled (already checked in if condition)
          if (needsCategory || needsPriority) {
            // Create a temporary todo for AI processing
            final tempTodo = TodoModel.create(
              title: repeatTodo.title,
              description: repeatTodo.description,
            );

            // Try to restore category if missing and categorization is enabled
            if (_aiProvider!.settings.enableAutoCategorization &&
                (repeatTodo.aiCategory == null ||
                    repeatTodo.aiCategory!.isEmpty)) {
              _repeatTodoAIStatus[repeatTodo.id] =
                  AIStatusConstants.categorizingTask;
              notifyListeners();

              final category = await _aiProvider!.categorizeTask(
                tempTodo,
                forceRefresh: false,
              );
              if (category != null && category.isNotEmpty) {
                restoredCategory = category;
                madeChanges = true;
              }
            }

            // Try to restore priority if missing and priority sorting is enabled
            if (_aiProvider!.settings.enablePrioritySorting &&
                (repeatTodo.aiPriority == 0)) {
              _repeatTodoAIStatus[repeatTodo.id] = 'Assessing priority...';
              notifyListeners();

              // Add delay between category and priority requests to avoid rate limiting
              await Future.delayed(const Duration(milliseconds: 1000));
              final priority = await _aiProvider!.assessPriority(
                tempTodo,
                forceRefresh: false,
              );
              if (priority != null && priority > 0) {
                restoredPriority = priority;
                madeChanges = true;
              }
            }

            // Only update if we actually restored something
            if (madeChanges) {
              // Mark as processed only if the enabled features are successfully restored
              final categoryOk =
                  !_aiProvider!.settings.enableAutoCategorization ||
                  restoredCategory?.isNotEmpty == true;
              final priorityOk =
                  !_aiProvider!.settings.enablePrioritySorting ||
                  restoredPriority > 0;

              final updatedRepeatTodo = repeatTodo.copyWith(
                aiCategory: restoredCategory,
                aiPriority: restoredPriority,
                aiProcessed: categoryOk && priorityOk,
              );

              await _putRepeatTodo(updatedRepeatTodo);
              _repeatTodos[i] = updatedRepeatTodo;
              needsUpdate = true;
            }
          } else {
            // No features need processing, mark as processed with existing data
            final updatedRepeatTodo = repeatTodo.copyWith(aiProcessed: true);
            await _putRepeatTodo(updatedRepeatTodo);
            _repeatTodos[i] = updatedRepeatTodo;
            needsUpdate = true;
          }

          // Clear UI status after processing
          _repeatTodoAILoading[repeatTodo.id] = false;
          _repeatTodoAIStatus[repeatTodo.id] = 'Completed';
          _processingRepeatTodos.remove(repeatTodo.id);

          // Schedule status clear after a delay
          Future.delayed(const Duration(seconds: 2), () {
            _repeatTodoAIStatus.remove(repeatTodo.id);
            notifyListeners();
          });

          notifyListeners();
        } catch (e) {
          debugPrint(
            'TodoProvider: Error restoring AI data for repeat todo "${repeatTodo.title}": $e',
          );

          // Clear UI status on error
          _repeatTodoAILoading[repeatTodo.id] = false;
          _repeatTodoAIStatus[repeatTodo.id] = 'Error';
          _processingRepeatTodos.remove(repeatTodo.id);
          notifyListeners();

          // Schedule status clear after a delay
          Future.delayed(const Duration(seconds: 2), () {
            _repeatTodoAIStatus.remove(repeatTodo.id);
            notifyListeners();
          });
        }
      }
    }

    if (needsUpdate) {
      notifyListeners();
    }
  }

  // Process missing categorization for unprocessed todos
  Future<void> processMissingCategorization() async {
    if (_aiProvider == null || !_aiProvider!.isAIServiceValid) return;

    final unprocessedTodos = _todos
        .where(
          (todo) =>
              !todo.isCompleted &&
              !todo.isGeneratedFromRepeat &&
              (todo.aiCategory == null || !todo.aiProcessed),
        )
        .toList();

    if (unprocessedTodos.isEmpty) return;

    _isProcessingCategories = true;
    notifyListeners();

    try {
      for (final todo in unprocessedTodos) {
        try {
          final languageCode = _languageProvider?.currentLanguageCode ?? 'en';
          final category = await _aiProvider!.aiService?.categorizeTask(
            todo,
            languageCode,
          );

          if (category != null) {
            final updatedTodo = todo.copyWith(
              aiCategory: category,
              aiProcessed: true,
            );

            await _putTodo(updatedTodo);

            // Update the todo in the list
            final index = _todos.indexWhere((t) => t.id == todo.id);
            if (index != -1) {
              _todos[index] = updatedTodo;
            }
          }
        } catch (e) {
          debugPrint(
            'Error processing categorization for todo ${todo.title}: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('Error in categorization process: $e');
    } finally {
      _isProcessingCategories = false;
      _applyFilters();
      notifyListeners();
    }
  }

  // Process missing priority for unprocessed todos
  Future<void> processMissingPriority() async {
    if (_aiProvider == null || !_aiProvider!.isAIServiceValid) return;

    final unprocessedTodos = _todos
        .where(
          (todo) =>
              !todo.isCompleted &&
              !todo.isGeneratedFromRepeat &&
              (todo.aiPriority == 0 || !todo.aiProcessed),
        )
        .toList();

    if (unprocessedTodos.isEmpty) return;

    _isProcessingPriorities = true;
    notifyListeners();

    try {
      for (final todo in unprocessedTodos) {
        try {
          final languageCode = _languageProvider?.currentLanguageCode ?? 'en';
          final priority = await _aiProvider!.aiService?.assessPriority(
            todo,
            languageCode,
          );

          if (priority != null) {
            final updatedTodo = todo.copyWith(
              aiPriority: priority,
              aiProcessed: true,
            );

            await _putTodo(updatedTodo);

            // Update the todo in the list
            final index = _todos.indexWhere((t) => t.id == todo.id);
            if (index != -1) {
              _todos[index] = updatedTodo;
            }
          }
        } catch (e) {
          debugPrint('Error processing priority for todo ${todo.title}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in priority process: $e');
    } finally {
      _isProcessingPriorities = false;
      _applyFilters();
      notifyListeners();
    }
  }

  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 优先从数据库加载以确保数据一致性
      final todosBox = _hiveService.todosBox;
      _todos = todosBox.values.toList();

      for (final todo in _todos) {
        await _syncWriteService.ensureMetaExists(
          type: SyncTypes.todo,
          recordId: todo.id,
          schemaVersion: TodoRepository.schemaVersion,
        );
      }

      // Filter tombstoned records from UI lists.
      _todos = _todos
          .where(
            (t) => !_syncWriteService.isTombstonedSync(SyncTypes.todo, t.id),
          )
          .toList();

      // Backfill repeat-generated stable keys for cross-device dedup.
      for (var i = 0; i < _todos.length; i++) {
        final todo = _todos[i];
        if (!todo.isGeneratedFromRepeat || todo.repeatTodoId == null) continue;
        final expectedKey = _repeatGeneratedKey(
          todo.repeatTodoId!,
          todo.createdAt,
        );
        if (todo.generatedKey == expectedKey) continue;

        final updated = todo.copyWith(generatedKey: expectedKey);
        await _putTodo(updated);
        _todos[i] = updated;
      }

      // Log AI data for each loaded todo
      for (int i = 0; i < _todos.length; i++) {
        final todo = _todos[i];

        // Verify the data was loaded correctly by checking the database directly
        final hiveTodo = todosBox.get(todo.id);
        if (hiveTodo != null) {
          if (hiveTodo.aiPriority != todo.aiPriority ||
              hiveTodo.aiProcessed != todo.aiProcessed ||
              hiveTodo.aiCategory != todo.aiCategory) {}
        }
      }

      _todos.sort((a, b) => a.order.compareTo(b.order));

      await _dedupeRepeatGeneratedTodosByKeyIfNeeded();

      // 仅在数据没有变化时使用缓存来提高性能
      final cacheKey = 'todos_${_currentFilter.name}_$_searchQuery';
      final cachedTodos = CacheService.getCachedTodos(cacheKey);

      // 验证缓存是否仍然有效（比较数据长度和最新更新时间）
      bool isCacheValid = false;
      if (cachedTodos != null && cachedTodos.length == _todos.length) {
        // 详细验证：检查ID、完成状态和AI数据是否匹配
        isCacheValid = cachedTodos.every(
          (cachedTodo) => _todos.any(
            (todo) =>
                todo.id == cachedTodo.id &&
                todo.isCompleted == cachedTodo.isCompleted &&
                todo.aiProcessed == cachedTodo.aiProcessed &&
                todo.aiCategory == cachedTodo.aiCategory &&
                todo.aiPriority == cachedTodo.aiPriority,
          ),
        );
      }

      if (isCacheValid && cachedTodos != null) {
        _todos = cachedTodos;
      } else {
        // 缓存无效，使用数据库数据并更新缓存
        await CacheService.cacheTodos(_todos, cacheKey);
      }

      _applyFilters();

      // Note: AI label verification is already called in constructor, no need to call it again here
    } catch (e) {
      debugPrint('Error loading todos: $e');
      // 如果加载失败，至少尝试从缓存加载
      try {
        final cacheKey = 'todos_${_currentFilter.name}_$_searchQuery';
        final cachedTodos = CacheService.getCachedTodos(cacheKey);
        if (cachedTodos != null) {
          _todos = cachedTodos;
          _applyFilters();
        }
      } catch (cacheError) {
        debugPrint('Failed to load from cache: $cacheError');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _dedupeRepeatGeneratedTodosByKeyIfNeeded() async {
    final groups = <String, List<TodoModel>>{};
    for (final todo in _todos) {
      final key = todo.generatedKey;
      if (key == null || key.isEmpty) continue;
      groups.putIfAbsent(key, () => <TodoModel>[]).add(todo);
    }

    final idsToTombstone = <String>{};

    for (final entry in groups.entries) {
      final candidates = entry.value;
      if (candidates.length <= 1) continue;

      TodoModel winner = candidates.first;
      for (final candidate in candidates.skip(1)) {
        final better = _compareTodoBySyncMeta(candidate, winner) > 0;
        if (better) {
          winner = candidate;
        }
      }

      for (final candidate in candidates) {
        if (candidate.id == winner.id) continue;
        idsToTombstone.add(candidate.id);
      }
    }

    if (idsToTombstone.isEmpty) return;

    for (final id in idsToTombstone) {
      await _notificationService.cancelTodoReminder(id);
      await _tombstoneTodo(id);
    }

    _todos.removeWhere((t) => idsToTombstone.contains(t.id));
  }

  int _compareTodoBySyncMeta(TodoModel a, TodoModel b) {
    final metaA = _syncWriteService.getMetaSync(SyncTypes.todo, a.id);
    final metaB = _syncWriteService.getMetaSync(SyncTypes.todo, b.id);

    final hlcA = HlcTimestamp(
      wallTimeMsUtc: metaA?.hlcWallMsUtc ?? 0,
      counter: metaA?.hlcCounter ?? 0,
      deviceId: metaA?.hlcDeviceId ?? '',
    );
    final hlcB = HlcTimestamp(
      wallTimeMsUtc: metaB?.hlcWallMsUtc ?? 0,
      counter: metaB?.hlcCounter ?? 0,
      deviceId: metaB?.hlcDeviceId ?? '',
    );

    final cmp = HlcClock.compare(hlcA, hlcB);
    if (cmp != 0) return cmp;
    return a.id.compareTo(b.id);
  }

  Future<void> loadRepeatTodos() async {
    try {
      final repeatTodosBox = _hiveService.repeatTodosBox;
      final values = repeatTodosBox.values.toList();

      // Debug logging
      // debugPrint('Loading repeat todos. Box contains ${values.length} items');

      // Validate each repeat todo before adding to list
      final validRepeatTodos = <RepeatTodoModel>[];
      for (final repeatTodo in values) {
        try {
          // Basic validation
          if (repeatTodo.id.isNotEmpty && repeatTodo.title.isNotEmpty) {
            await _syncWriteService.ensureMetaExists(
              type: SyncTypes.repeatTodo,
              recordId: repeatTodo.id,
              schemaVersion: RepeatTodoRepository.schemaVersion,
            );
            if (_syncWriteService.isTombstonedSync(
              SyncTypes.repeatTodo,
              repeatTodo.id,
            )) {
              continue;
            }
            validRepeatTodos.add(repeatTodo);
          } else {
            debugPrint(
              'Invalid repeat todo found: id=${repeatTodo.id}, title=${repeatTodo.title}',
            );
          }
        } catch (e) {
          debugPrint('Error validating repeat todo: $e');
        }
      }

      _repeatTodos = validRepeatTodos;
      _repeatTodos.sort((a, b) => a.order.compareTo(b.order));

      // debugPrint(
      //   'Successfully loaded ${_repeatTodos.length} valid repeat todos',
      // );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading repeat todos: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      // Initialize with empty list to prevent null reference
      _repeatTodos = [];
      notifyListeners();
    }
  }

  Future<void> loadStatistics() async {
    try {
      final statsBox = _hiveService.statisticsBox;
      _statistics = statsBox.values.toList();
      _statistics.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  Future<void> loadStatisticsData() async {
    try {
      final statsDataBox = _hiveService.statisticsDataBox;
      for (final data in statsDataBox.values) {
        await _syncWriteService.ensureMetaExists(
          type: SyncTypes.statisticsData,
          recordId: data.id,
          schemaVersion: StatisticsDataRepository.schemaVersion,
        );
      }

      _statisticsData = statsDataBox.values
          .where(
            (d) => !_syncWriteService.isTombstonedSync(
              SyncTypes.statisticsData,
              d.id,
            ),
          )
          .toList();
      _statisticsData.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics data: $e');
    }
  }

  Future<void> refreshAllData() async {
    // 清除所有缓存以确保加载最新数据
    await _invalidateTodoCache();

    await loadTodos();
    await loadRepeatTodos();
    await loadStatistics();
    await loadStatisticsData();
  }

  Future<void> reloadFromHiveReadOnly({FilterProvider? filterProvider}) async {
    try {
      // Avoid stale persistent caches overriding freshly-synced data on next app
      // start (or web refresh). Cache invalidation is local-only and does not
      // touch sync outbox.
      await _invalidateTodoCache();

      if (filterProvider != null) {
        syncWithFilterProvider(filterProvider);
      }

      final todosBox = _hiveService.todosBox;
      final repeatBox = _hiveService.repeatTodosBox;
      final statsBox = _hiveService.statisticsBox;
      final statsDataBox = _hiveService.statisticsDataBox;

      _todos = todosBox.values
          .where(
            (t) => !_syncWriteService.isTombstonedSync(SyncTypes.todo, t.id),
          )
          .toList();
      _todos.sort((a, b) => a.order.compareTo(b.order));

      _repeatTodos = repeatBox.values
          .where(
            (t) =>
                !_syncWriteService.isTombstonedSync(SyncTypes.repeatTodo, t.id),
          )
          .toList();
      _repeatTodos.sort((a, b) => a.order.compareTo(b.order));

      _statistics = statsBox.values.toList();

      _statisticsData = statsDataBox.values
          .where(
            (d) => !_syncWriteService.isTombstonedSync(
              SyncTypes.statisticsData,
              d.id,
            ),
          )
          .toList();
      _statisticsData.sort((a, b) => b.date.compareTo(a.date));

      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('TodoProvider: Error reloading from hive (read-only): $e');
    }
  }

  Future<void> addTodo(
    String title, {
    String? description,
    DateTime? reminderTime,
    bool reminderEnabled = false,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final newTodo = TodoModel.create(
        title: title,
        description: description,
        order: _todos.length,
        reminderTime: reminderTime,
        reminderEnabled: reminderEnabled,
        startTime: startTime,
        endTime: endTime,
      );

      await _putTodo(newTodo);

      _todos.add(newTodo);
      _applyFilters();
      await _updateStatistics();

      // Schedule notification if reminder is enabled
      if (reminderEnabled && reminderTime != null) {
        await _notificationService.scheduleTodoReminder(newTodo);
      }

      // Trigger AI classification for the new todo if AI features are enabled
      // Skip AI processing for todos generated from repeat templates (they inherit AI data from template)
      if (_aiProvider != null &&
          _aiProvider!.isAIServiceValid &&
          !newTodo.isGeneratedFromRepeat) {
        // Add a small delay to ensure the todo is properly saved before processing
        Future.delayed(const Duration(milliseconds: 500), () {
          processMissingAIDataForTodo(newTodo);
        });
      }

      // 更新缓存以确保数据一致性
      await _invalidateTodoCache();

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding todo: $e');
    }
  }

  Future<void> updateTodo(TodoModel updatedTodo) async {
    try {
      // Get the original todo for comparison
      final originalTodoIndex = _todos.indexWhere(
        (todo) => todo.id == updatedTodo.id,
      );
      TodoModel? originalTodo;
      if (originalTodoIndex != -1) {
        originalTodo = _todos[originalTodoIndex];
      }

      // Check if reminder-related fields changed
      bool reminderChanged = false;
      if (originalTodo != null) {
        reminderChanged =
            originalTodo.reminderEnabled != updatedTodo.reminderEnabled ||
            originalTodo.reminderTime != updatedTodo.reminderTime;
      }

      // Cancel existing notification if needed
      if (originalTodoIndex != -1) {
        await _notificationService.cancelTodoReminder(updatedTodo.id);
      }

      await _putTodo(updatedTodo);

      final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
      if (index != -1) {
        _todos[index] = updatedTodo;
        _applyFilters();
        await _updateStatistics();

        // Schedule new notification if reminder is enabled and todo is not completed
        if (updatedTodo.reminderEnabled &&
            updatedTodo.reminderTime != null &&
            !updatedTodo.isCompleted) {
          await _notificationService.scheduleTodoReminder(updatedTodo);
        }
      }

      // Invalidate cache if reminder fields changed
      if (reminderChanged) {
        await _invalidateTodoCacheForId(updatedTodo.id);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating todo: $e');
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      // Cancel any pending AI processing for this todo
      _debounceTimers[id]?.cancel();
      _debounceTimers.remove(id);
      _processingTodos.remove(id);
      _failedAiRequests.remove(id);
      _lastRequestTime.remove(id);

      // Cancel notification before deleting
      await _notificationService.cancelTodoReminder(id);

      await _tombstoneTodo(id);

      _todos.removeWhere((todo) => todo.id == id);
      _applyFilters();
      await _updateStatistics();

      // 更新缓存以确保数据一致性
      await _invalidateTodoCache();

      // Force notify listeners immediately to ensure UI updates
      notifyListeners();

      // Additional delay to ensure any pending AI operations are fully cancelled
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('Error deleting todo: $e');
    }
  }

  Future<void> toggleTodoCompletion(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;

    final todo = _todos[index];

    // Check if this is a repeat-generated todo with data statistics enabled
    if (todo.isGeneratedFromRepeat && todo.repeatTodoId != null) {
      RepeatTodoModel? repeatTodo;
      try {
        repeatTodo = _repeatTodos.firstWhere(
          (rt) => rt.id == todo.repeatTodoId,
        );
      } catch (e) {
        repeatTodo = RepeatTodoModel.create(
          title: '',
          repeatType: RepeatType.daily,
        );
      }

      if (repeatTodo.dataStatisticsEnabled && !todo.isCompleted) {
        // For data statistics-enabled repeat todos, require data input
        // This will be handled by the UI component
        return;
      }
    }

    // If uncompleting a task, clear completion data to prevent duplicate recording
    final updatedTodo = todo.copyWith(
      isCompleted: !todo.isCompleted,
      completedAt: todo.isCompleted ? null : _getLocalDateTime(),
      dataValue: todo.isCompleted ? null : null, // Clear data when uncompleting
    );

    // Cancel notification if todo is being completed
    if (!todo.isCompleted && todo.reminderEnabled) {
      await _notificationService.cancelTodoReminder(id);
    }

    // If this is a repeat-generated todo being uncompleted, ensure consistency
    if (todo.isGeneratedFromRepeat && todo.isCompleted) {
      // Remove statistics data when uncompleting to prevent duplicate recording
      final existingDataIndex = _statisticsData.indexWhere(
        (data) => data.todoId == todo.id,
      );
      if (existingDataIndex != -1) {
        await _tombstoneStatisticsData(_statisticsData[existingDataIndex].id);
        _statisticsData.removeAt(existingDataIndex);
      }
      await _ensureRepeatTodoConsistency(todo.repeatTodoId!);
    }

    await updateTodo(updatedTodo);

    // If uncompleting a task, check if it needs AI processing
    if (todo.isCompleted && !updatedTodo.isCompleted) {
      await _processWithdrawnTodoWithAI(updatedTodo);
    }
  }

  Future<void> completeTodoWithData(String id, double value) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;

    final todo = _todos[index];

    // Update todo with completion and data
    final updatedTodo = todo.copyWith(
      isCompleted: true,
      completedAt: _getLocalDateTime(),
      dataValue: value,
    );

    // Save statistics data
    if (todo.isGeneratedFromRepeat && todo.repeatTodoId != null) {
      RepeatTodoModel? repeatTodo;
      try {
        repeatTodo = _repeatTodos.firstWhere(
          (rt) => rt.id == todo.repeatTodoId,
        );
      } catch (e) {
        repeatTodo = RepeatTodoModel.create(
          title: '',
          repeatType: RepeatType.daily,
        );
      }

      // Check if there's already statistics data for this todo
      final existingDataIndex = _statisticsData.indexWhere(
        (data) => data.todoId == todo.id,
      );

      StatisticsDataModel statisticsData;

      if (existingDataIndex != -1) {
        // Update existing statistics data
        final existingData = _statisticsData[existingDataIndex];
        statisticsData = existingData.copyWith(
          value: value,
          unit: repeatTodo.dataUnit ?? '',
          date:
              _getLocalDateTime(), // Update timestamp to reflect when data was modified
        );

        await _putStatisticsData(statisticsData);
        _statisticsData[existingDataIndex] = statisticsData;
      } else {
        // Create new statistics data
        statisticsData = StatisticsDataModel.create(
          repeatTodoId: todo.repeatTodoId!,
          todoId: todo.id,
          value: value,
          unit: repeatTodo.dataUnit ?? '',
          todoCreatedAt: todo.createdAt,
        );

        await _putStatisticsData(statisticsData);
        _statisticsData.add(statisticsData);
      }

      _statisticsData.sort((a, b) => b.date.compareTo(a.date));
    }

    // Cancel notification if todo is being completed
    if (todo.reminderEnabled) {
      await _notificationService.cancelTodoReminder(id);
    }

    await updateTodo(updatedTodo);
  }

  List<StatisticsDataModel> getStatisticsDataForRepeatTodo(
    String repeatTodoId,
  ) {
    return _statisticsData
        .where((data) => data.repeatTodoId == repeatTodoId)
        .toList();
  }

  List<StatisticsDataModel> getStatisticsDataForDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _statisticsData
        .where((data) => data.date.isAfter(start) && data.date.isBefore(end))
        .toList();
  }

  Future<void> reorderTodos(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final todo = _todos.removeAt(oldIndex);

    if (newIndex > oldIndex) {
      newIndex--;
    }

    _todos.insert(newIndex, todo);

    for (int i = 0; i < _todos.length; i++) {
      _todos[i] = _todos[i].copyWith(order: i);
      await _putTodo(_todos[i]);
    }

    _applyFilters();

    // 更新缓存以确保数据一致性
    await _invalidateTodoCache();

    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void setFilter(TodoFilter filter) {
    _currentFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    _applyFilters();
    notifyListeners();
  }

  void setSelectedCategories(Set<String> categories) {
    _selectedCategories = categories;
    _applyFilters();
    notifyListeners();
  }

  void toggleCategory(String category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    _applyFilters();
    notifyListeners();
  }

  void clearCategoryFilter() {
    _selectedCategories.clear();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredTodos = _todos.where((todo) {
      bool matchesSearch =
          _searchQuery.isEmpty ||
          todo.title.toLowerCase().contains(_searchQuery) ||
          (todo.description?.toLowerCase().contains(_searchQuery) ?? false);

      bool matchesFilter = true;
      switch (_currentFilter) {
        case TodoFilter.active:
          matchesFilter = !todo.isCompleted;
          break;
        case TodoFilter.completed:
          matchesFilter = todo.isCompleted;
          break;
        case TodoFilter.all:
          matchesFilter = true;
      }

      bool matchesDate = true;
      if (_dateRange != null) {
        matchesDate =
            todo.createdAt.isAfter(_dateRange!.start) &&
            todo.createdAt.isBefore(_dateRange!.end);
      }

      bool matchesCategory = true;
      if (_selectedCategories.isNotEmpty) {
        matchesCategory =
            todo.aiCategory != null &&
            _selectedCategories.contains(todo.aiCategory);
      }

      return matchesSearch && matchesFilter && matchesDate && matchesCategory;
    }).toList();

    // Apply sorting
    switch (_sortOrder) {
      case SortOrder.timeAscending:
        _filteredTodos.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOrder.timeDescending:
        _filteredTodos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOrder.alphabetical:
        _filteredTodos.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SortOrder.importanceAscending:
        _filteredTodos.sort((a, b) => a.aiPriority.compareTo(b.aiPriority));
        break;
      case SortOrder.importanceDescending:
        _filteredTodos.sort((a, b) => b.aiPriority.compareTo(a.aiPriority));
        break;
    }
  }

  Future<void> _updateStatistics() async {
    final today = _getLocalDateTime();
    final todayStats = StatisticsModel.create(
      date: today,
      tasksCreated: _todos
          .where((todo) => _isSameDay(todo.createdAt, today))
          .length,
      tasksCompleted: _todos
          .where((todo) => todo.isCompleted && todo.completedAt != null)
          .where((todo) => _isSameDay(todo.completedAt!, today))
          .length,
    );

    final statsBox = _hiveService.statisticsBox;
    final existingIndex = _statistics.indexWhere(
      (stat) => _isSameDay(stat.date, today),
    );

    if (existingIndex != -1) {
      _statistics[existingIndex] = todayStats;
      await statsBox.put(todayStats.date.toIso8601String(), todayStats);
    } else {
      _statistics.add(todayStats);
      await statsBox.put(todayStats.date.toIso8601String(), todayStats);
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return isSameLocalDay(date1, date2);
  }

  List<TodoModel> getTodayTodos() {
    final today = _getLocalDateTime();
    return _todos.where((todo) => _isSameDay(todo.createdAt, today)).toList();
  }

  List<TodoModel> getWeekTodos() {
    final now = _getLocalDateTime();
    final weekStart = now.subtract(Duration(days: now.weekday));
    return _todos.where((todo) => todo.createdAt.isAfter(weekStart)).toList();
  }

  List<TodoModel> getThisWeekScheduleTodos() {
    final now = _getLocalDateTime();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return _todos
        .where((todo) {
          final start = todo.startTime;
          final end = todo.endTime;

          if (start != null && end != null && end.isAfter(start)) {
            return start.isBefore(weekEnd) && end.isAfter(weekStart);
          }

          final point =
              start ??
              end ??
              ((todo.reminderEnabled && todo.reminderTime != null)
                  ? todo.reminderTime!
                  : todo.createdAt);

          return !point.isBefore(weekStart) && point.isBefore(weekEnd);
        })
        .toList(growable: false);
  }

  List<TodoModel> getMonthTodos() {
    final now = _getLocalDateTime();
    final monthStart = DateTime(now.year, now.month, 1);
    return _todos.where((todo) => todo.createdAt.isAfter(monthStart)).toList();
  }

  List<TodoModel> getAllTodos() {
    return List<TodoModel>.from(_todos);
  }

  void setTimeFilter(TimeFilter timeFilter) {
    final now = _getLocalDateTime();
    DateTimeRange? range;

    switch (timeFilter) {
      case TimeFilter.today:
        final today = DateTime(now.year, now.month, now.day);
        range = DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)),
        );
        break;
      case TimeFilter.yesterday:
        final yesterday = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 1));
        range = DateTimeRange(
          start: yesterday,
          end: yesterday.add(const Duration(days: 1)),
        );
        break;
      case TimeFilter.threeDays:
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        range = DateTimeRange(
          start: threeDaysAgo,
          end: now.add(const Duration(days: 1)),
        );
        break;
      case TimeFilter.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        range = DateTimeRange(
          start: weekStart,
          end: weekStart.add(const Duration(days: 7)),
        );
        break;
      case TimeFilter.month:
        final monthStart = DateTime(now.year, now.month, 1);
        range = DateTimeRange(
          start: monthStart,
          end: monthStart.add(const Duration(days: 31)),
        );
        break;
      case TimeFilter.all:
        range = null;
        break;
    }

    setDateRange(range);
  }

  void clearTimeFilter() {
    setDateRange(null);
  }

  void setSortOrder(SortOrder order) {
    _sortOrder = order;
    _applyFilters();
    notifyListeners();
  }

  Future<void> clearAllData() async {
    try {
      debugPrint('Starting to clear all data...');

      final todosBox = _hiveService.todosBox;
      final statisticsBox = _hiveService.statisticsBox;
      final repeatTodosBox = _hiveService.repeatTodosBox;
      final statisticsDataBox = _hiveService.statisticsDataBox;
      final pomodoroBox = _hiveService.pomodoroBox;

      debugPrint('Tombstoning todos...');
      for (final entry in todosBox.toMap().entries) {
        final todo = entry.value;
        await _tombstoneTodo(todo.id);
        await todosBox.delete(entry.key);
      }

      debugPrint('Clearing statistics box...');
      await statisticsBox.clear();

      debugPrint('Tombstoning repeat todos...');
      for (final entry in repeatTodosBox.toMap().entries) {
        final repeatTodo = entry.value;
        await _tombstoneRepeatTodo(repeatTodo.id);
        await repeatTodosBox.delete(entry.key);
      }

      debugPrint('Tombstoning statistics data...');
      for (final entry in statisticsDataBox.toMap().entries) {
        final statData = entry.value;
        await _tombstoneStatisticsData(statData.id);
        await statisticsDataBox.delete(entry.key);
      }

      debugPrint('Tombstoning pomodoro sessions...');
      for (final entry in pomodoroBox.toMap().entries) {
        final session = entry.value;
        await _syncWriteService.tombstoneRecord(
          type: SyncTypes.pomodoro,
          recordId: session.id,
          schemaVersion: 1,
        );
        await pomodoroBox.delete(entry.key);
      }

      debugPrint('Clearing in-memory lists...');
      _todos = [];
      _filteredTodos = [];
      _statistics = [];
      _repeatTodos = [];
      _statisticsData = [];

      debugPrint('All data cleared successfully');

      // 清除所有缓存
      await _invalidateTodoCache();

      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Repeat Todo Management

  // Process repeat todo AI in background
  Future<void> _processRepeatTodoAIInBackground(
    String repeatTodoId,
    String? createdTodoId, {
    bool isUpdate = false,
  }) async {
    try {
      // Update status
      _repeatTodoAIStatus[repeatTodoId] = 'Analyzing task...';
      notifyListeners();

      // Find the repeat todo
      final repeatTodo = _repeatTodos.firstWhere(
        (rt) => rt.id == repeatTodoId,
        orElse: () => throw Exception('Repeat todo not found'),
      );

      // Check if AI processing is available
      if (_aiProvider == null || !_aiProvider!.isAIServiceValid) {
        _repeatTodoAILoading[repeatTodoId] = false;
        _repeatTodoAIStatus[repeatTodoId] = 'AI service unavailable';
        _processingRepeatTodos.remove(repeatTodoId);
        notifyListeners();
        return;
      }

      // Create a temporary todo for AI processing
      final tempTodo = TodoModel.create(
        title: repeatTodo.title,
        description: repeatTodo.description,
      );

      // Process category with status updates
      String? category = repeatTodo.aiCategory;
      if (_aiProvider!.settings.enableAutoCategorization &&
          (repeatTodo.aiCategory == null || repeatTodo.aiCategory!.isEmpty)) {
        _repeatTodoAIStatus[repeatTodoId] = AIStatusConstants.categorizingTask;
        notifyListeners();

        category = await _aiProvider!.categorizeTask(tempTodo);
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Small delay for status update
      }

      // Process priority with status updates
      int? priority = repeatTodo.aiPriority;
      if (_aiProvider!.settings.enablePrioritySorting &&
          repeatTodo.aiPriority == 0) {
        _repeatTodoAIStatus[repeatTodoId] = 'Assessing priority...';
        notifyListeners();

        // Add delay between category and priority requests to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 1000));
        priority = await _aiProvider!.assessPriority(tempTodo);
      }

      // Update the repeat todo with AI results
      final processedRepeatTodo = repeatTodo.copyWith(
        aiCategory: category,
        aiPriority: priority ?? 0,
        aiProcessed: true,
      );

      // Save to database
      await _putRepeatTodo(processedRepeatTodo);

      // Update in memory
      final index = _repeatTodos.indexWhere((rt) => rt.id == repeatTodoId);
      if (index != -1) {
        _repeatTodos[index] = processedRepeatTodo;
      }

      // Sync AI data to created todo if exists
      if (createdTodoId != null) {
        await _syncAIToCreatedTodo(createdTodoId, processedRepeatTodo);
      }

      // If this is an update, sync changes to existing generated todos (including completed ones)
      if (isUpdate) {
        await _syncRepeatTodoChangesToGeneratedTodos(
          repeatTodo,
          processedRepeatTodo,
          includeCompleted: true,
        );
      }

      // Clear processing status
      _repeatTodoAILoading[repeatTodoId] = false;
      _repeatTodoAIStatus[repeatTodoId] = 'Completed';
      _processingRepeatTodos.remove(repeatTodoId);

      // Schedule status clear after a delay
      Future.delayed(const Duration(seconds: 2), () {
        _repeatTodoAIStatus.remove(repeatTodoId);
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      debugPrint(
        'TodoProvider: Error in background AI processing for repeat todo $repeatTodoId: $e',
      );

      // Clear processing status with error
      _repeatTodoAILoading[repeatTodoId] = false;
      _repeatTodoAIStatus[repeatTodoId] =
          'Error: ${e.toString().substring(0, 50)}...';
      _processingRepeatTodos.remove(repeatTodoId);
      notifyListeners();
    }
  }

  Future<void> addRepeatTodo(RepeatTodoModel repeatTodo) async {
    try {
      // Set order if not set
      final finalRepeatTodo = repeatTodo.order == 0
          ? repeatTodo.copyWith(order: _repeatTodos.length)
          : repeatTodo;

      // Create the repeat todo first without AI processing
      await _putRepeatTodo(finalRepeatTodo);
      _repeatTodos.add(finalRepeatTodo);
      _repeatTodos.sort((a, b) => a.order.compareTo(b.order));

      // Set initial AI processing status
      _repeatTodoAILoading[finalRepeatTodo.id] = true;
      _repeatTodoAIStatus[finalRepeatTodo.id] = AIStatusConstants.processingAI;
      _processingRepeatTodos.add(finalRepeatTodo.id);
      notifyListeners();

      // Only generate initial todo if today matches the repeat condition
      final now = _getLocalDateTime();
      String? createdTodoId;
      if (_shouldGenerateForToday(finalRepeatTodo, now)) {
        createdTodoId = await _generateTodoFromRepeat(finalRepeatTodo);

        // Update last generated date to today
        final updatedRepeatTodo = finalRepeatTodo.copyWith(
          lastGeneratedDate: now,
        );
        await _putRepeatTodo(updatedRepeatTodo);
        final index = _repeatTodos.indexWhere(
          (rt) => rt.id == finalRepeatTodo.id,
        );
        if (index != -1) {
          _repeatTodos[index] = updatedRepeatTodo;
        }
      }

      // Process AI in background without blocking UI
      unawaited(
        _processRepeatTodoAIInBackground(finalRepeatTodo.id, createdTodoId),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding repeat todo: $e');
    }
  }

  Future<void> updateRepeatTodo(
    RepeatTodoModel updatedRepeatTodo, {
    bool skipAIProcessing = false,
  }) async {
    try {
      // Get the original repeat todo for comparison
      final originalRepeatTodo = _repeatTodos.firstWhere(
        (rt) => rt.id == updatedRepeatTodo.id,
        orElse: () => updatedRepeatTodo,
      );

      // Always update the basic todo data first
      await _putRepeatTodo(updatedRepeatTodo);

      final index = _repeatTodos.indexWhere(
        (rt) => rt.id == updatedRepeatTodo.id,
      );
      if (index != -1) {
        _repeatTodos[index] = updatedRepeatTodo;
        _repeatTodos.sort((a, b) => a.order.compareTo(b.order));
      }

      bool sameDayOrBothNull(DateTime? a, DateTime? b) {
        if (a == null && b == null) return true;
        if (a == null || b == null) return false;
        return _normalizeDay(a).isAtSameMomentAs(_normalizeDay(b));
      }

      final startDateChanged = !sameDayOrBothNull(
        originalRepeatTodo.startDate,
        updatedRepeatTodo.startDate,
      );
      final endDateChanged = !sameDayOrBothNull(
        originalRepeatTodo.endDate,
        updatedRepeatTodo.endDate,
      );
      final backfillWindowChanged =
          originalRepeatTodo.backfillEnabled !=
              updatedRepeatTodo.backfillEnabled ||
          originalRepeatTodo.backfillDays != updatedRepeatTodo.backfillDays;

      // If the backfill window changed, remove previously backfilled instances
      // that are now outside the new range.
      if (startDateChanged || endDateChanged || backfillWindowChanged) {
        await _pruneOutOfRangeBackfilledTodosForRepeat(
          updatedRepeatTodo,
          _getLocalDateTime(),
        );
      }

      // Check if we need to process AI (title or description changed and not skipped)
      final titleChanged = originalRepeatTodo.title != updatedRepeatTodo.title;
      final descriptionChanged =
          originalRepeatTodo.description != updatedRepeatTodo.description;
      final needsAIProcessing =
          !skipAIProcessing && (titleChanged || descriptionChanged);

      if (needsAIProcessing &&
          _aiProvider != null &&
          _aiProvider!.isAIServiceValid) {
        // Set AI processing status
        _repeatTodoAILoading[updatedRepeatTodo.id] = true;
        _repeatTodoAIStatus[updatedRepeatTodo.id] = 'Updating AI...';
        _processingRepeatTodos.add(updatedRepeatTodo.id);
        notifyListeners();

        // Process AI in background
        unawaited(
          _processRepeatTodoAIInBackground(
            updatedRepeatTodo.id,
            null,
            isUpdate: true,
          ),
        );
      } else if (!skipAIProcessing) {
        // Sync changes to existing generated todos if critical fields changed
        await _syncRepeatTodoChangesToGeneratedTodos(
          originalRepeatTodo,
          updatedRepeatTodo,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating repeat todo: $e');
    }
  }

  Future<void> deleteRepeatTodo(String id) async {
    try {
      debugPrint('Deleting repeat todo with ID: $id');

      // Delete all todos generated from this repeat
      final generatedTodos = _todos
          .where((todo) => todo.repeatTodoId == id)
          .toList();
      debugPrint(
        'Found ${generatedTodos.length} todos generated from repeat todo $id',
      );

      for (final todo in generatedTodos) {
        debugPrint('Deleting generated todo: ${todo.id}');
        await deleteTodo(todo.id);
      }

      await _tombstoneRepeatTodo(id);
      _repeatTodos.removeWhere((rt) => rt.id == id);

      debugPrint(
        'Successfully deleted repeat todo $id and its generated todos',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting repeat todo: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> toggleRepeatTodoActive(String id) async {
    final index = _repeatTodos.indexWhere((rt) => rt.id == id);
    if (index == -1) return;

    final repeatTodo = _repeatTodos[index];
    final updatedRepeatTodo = repeatTodo.copyWith(
      isActive: !repeatTodo.isActive,
    );

    await updateRepeatTodo(updatedRepeatTodo);
  }

  Future<void> checkAndGenerateRepeatTodos() async {
    return _enqueueRepeatOperation(() async {
      await _hydrateRepeatGenerationStateIfNeeded();

      final now = _getLocalDateTime();
      // final systemTime = DateTime.now();
      // debugPrint('checkAndGenerateRepeatTodos called at: $now');
      // debugPrint('System time: $systemTime');
      // debugPrint('Time difference: ${now.difference(systemTime).inMinutes} minutes');

      final previousRepeatCheck = _lastRepeatCheck;

      // 避免过于频繁的检查（至少间隔30秒）
      if (previousRepeatCheck != null &&
          now.difference(previousRepeatCheck).inSeconds < 30) {
        debugPrint('Skipping repeat todo check - last check was too recent');
        return;
      }

      _lastRepeatCheck = now;

      // 检查是否日期变化了（新的本地日期开始）
      final lastCheckDate = previousRepeatCheck != null
          ? localDay(previousRepeatCheck)
          : null;
      final currentDate = localDay(now);

      final isNewDay =
          lastCheckDate == null || !isSameLocalDay(currentDate, lastCheckDate);
      // debugPrint('Is new day: $isNewDay, Last check date: $lastCheckDate, Current date: $currentDate');
      // debugPrint('Current hour: ${now.hour}, Current minute: ${now.minute}');

      for (final repeatTodo in _repeatTodos) {
        // Check if repeat task has expired and should be deactivated
        if (repeatTodo.isActive &&
            repeatTodo.endDate != null &&
            _normalizeDay(now).isAfter(_normalizeDay(repeatTodo.endDate!))) {
          final deactivatedRepeatTodo = repeatTodo.copyWith(isActive: false);
          await updateRepeatTodo(deactivatedRepeatTodo, skipAIProcessing: true);
          continue;
        }

        // 检查是否需要生成任务
        final shouldCheckGeneration =
            isNewDay || repeatTodo.shouldGenerateTodo(now);

        if (shouldCheckGeneration) {
          final backfilledLatestDay = await _backfillRepeatTodosIfNeeded(
            repeatTodo,
            now,
          );

          // 检查今天是否已经为这个重复模板生成了任务
          final hasGeneratedToday = _hasGeneratedTodoForToday(repeatTodo, now);

          var generatedToday = false;
          if (!hasGeneratedToday) {
            // 检查今天是否符合重复条件
            final shouldGenerateToday = _shouldGenerateForToday(
              repeatTodo,
              now,
            );

            if (shouldGenerateToday) {
              await _generateTodoFromRepeat(repeatTodo);
              generatedToday = true;
            }
          }

          DateTime? newLastGeneratedDate;
          if (generatedToday) {
            newLastGeneratedDate = now;
          } else if (backfilledLatestDay != null) {
            newLastGeneratedDate = DateTime(
              backfilledLatestDay.year,
              backfilledLatestDay.month,
              backfilledLatestDay.day,
              now.hour,
              now.minute,
              now.second,
            );
          }

          if (newLastGeneratedDate != null) {
            final currentLast = repeatTodo.lastGeneratedDate;
            final shouldUpdate =
                currentLast == null ||
                _normalizeDay(
                  currentLast,
                ).isBefore(_normalizeDay(newLastGeneratedDate));

            if (shouldUpdate) {
              // Update last generated date (skip AI processing for this metadata update)
              final updatedRepeatTodo = repeatTodo.copyWith(
                lastGeneratedDate: newLastGeneratedDate,
              );
              await updateRepeatTodo(updatedRepeatTodo, skipAIProcessing: true);
            }
          }
        }
      }
    });
  }

  // 强制检查重复任务（忽略频率限制）
  Future<void> forceCheckRepeatTodos() async {
    return _enqueueRepeatOperation(() async {
      await _hydrateRepeatGenerationStateIfNeeded();

      final now = _getLocalDateTime();
      _lastRepeatCheck = now;

      // 首先清理过期的重复任务
      await _cleanupExpiredRepeatTasks(now);

      // 检查是否日期变化了（新的本地日期开始）
      // final lastCheckDate = _lastRepeatCheck != null
      //     ? DateTime(_lastRepeatCheck!.year, _lastRepeatCheck!.month, _lastRepeatCheck!.day)
      //     : null;
      // final currentDate = DateTime(now.year, now.month, now.day);

      // final isNewDay = lastCheckDate == null || !currentDate.isAtSameMomentAs(lastCheckDate);

      for (final repeatTodo in _repeatTodos) {
        // Check if repeat task has expired and should be deactivated
        if (repeatTodo.isActive &&
            repeatTodo.endDate != null &&
            _normalizeDay(now).isAfter(_normalizeDay(repeatTodo.endDate!))) {
          final deactivatedRepeatTodo = repeatTodo.copyWith(isActive: false);
          await updateRepeatTodo(deactivatedRepeatTodo, skipAIProcessing: true);
          continue;
        }

        // For force refresh, we check if we should generate regardless of timing
        if (repeatTodo.isActive) {
          var currentLastGeneratedDate = repeatTodo.lastGeneratedDate;
          final backfilledLatestDay = await _backfillRepeatTodosIfNeeded(
            repeatTodo,
            now,
          );

          // 检查今天是否已经为这个重复模板生成了任务
          final hasGeneratedToday = _hasGeneratedTodoForToday(repeatTodo, now);

          var generatedToday = false;
          if (!hasGeneratedToday) {
            // 仅在“今天符合重复规则”时生成。
            // 注意：`RepeatTodoModel.shouldGenerateTodo` 表示“是否到期/是否错过过生成”，
            // 不能直接用于“今天是否应生成”，否则 weekly/monthly 可能在不匹配日期时补生成。
            if (_shouldGenerateForToday(repeatTodo, now)) {
              await _generateTodoFromRepeat(repeatTodo);
              generatedToday = true;
            } else {
              // 如果不应该在今天生成，但有未来的 lastGeneratedDate，重置它
              if (currentLastGeneratedDate != null &&
                  currentLastGeneratedDate.isAfter(now)) {
                final correctedRepeatTodo = repeatTodo.copyWith(
                  lastGeneratedDate: null,
                );
                await updateRepeatTodo(
                  correctedRepeatTodo,
                  skipAIProcessing: true,
                );
                currentLastGeneratedDate = null;
              }
            }
          }

          DateTime? newLastGeneratedDate;
          if (generatedToday) {
            newLastGeneratedDate = now;
          } else if (backfilledLatestDay != null) {
            newLastGeneratedDate = DateTime(
              backfilledLatestDay.year,
              backfilledLatestDay.month,
              backfilledLatestDay.day,
              now.hour,
              now.minute,
              now.second,
            );
          }

          if (newLastGeneratedDate != null) {
            final currentLast = currentLastGeneratedDate;
            final shouldUpdate =
                currentLast == null ||
                _normalizeDay(
                  currentLast,
                ).isBefore(_normalizeDay(newLastGeneratedDate));

            if (shouldUpdate) {
              // Update last generated date (skip AI processing for this metadata update)
              final updatedRepeatTodo = repeatTodo.copyWith(
                lastGeneratedDate: newLastGeneratedDate,
              );
              await updateRepeatTodo(updatedRepeatTodo, skipAIProcessing: true);
            }
          }
        }
      }
    });
  }

  // 完全强制刷新：为每个活动重复任务生成今天的任务（只在应该生成的时候）
  Future<void> forceRefreshAllRepeatTasks({
    Future<BackfillStartBasis?> Function(
      RepeatTodoModel repeatTodo,
      DateTime startDate,
      DateTime backfillStartDate,
    )?
    onBackfillStartConflict,
  }) async {
    return _enqueueRepeatOperation(() async {
      await _hydrateRepeatGenerationStateIfNeeded();

      final now = _getLocalDateTime();
      _lastRepeatCheck = now;

      // 首先清理过期的重复任务
      await _cleanupExpiredRepeatTasks(now);

      for (final repeatTodo in _repeatTodos) {
        // Check if repeat task has expired and should be deactivated
        if (repeatTodo.isActive &&
            repeatTodo.endDate != null &&
            _normalizeDay(now).isAfter(_normalizeDay(repeatTodo.endDate!))) {
          final deactivatedRepeatTodo = repeatTodo.copyWith(isActive: false);
          await updateRepeatTodo(deactivatedRepeatTodo, skipAIProcessing: true);
          continue;
        }

        // For complete force refresh, generate task for every active repeat task
        if (repeatTodo.isActive) {
          var effectiveRepeatTodo = repeatTodo;
          var startBasis = BackfillStartBasis.startDate;
          if (onBackfillStartConflict != null &&
              repeatTodo.backfillEnabled &&
              repeatTodo.backfillDays > 0 &&
              repeatTodo.startDate != null) {
            final normalizedStartDate = _normalizeDay(repeatTodo.startDate!);
            final normalizedBackfillStartDate = _normalizeDay(
              now,
            ).subtract(Duration(days: repeatTodo.backfillDays));

            final hasConflict = normalizedStartDate.isAfter(
              normalizedBackfillStartDate,
            );
            if (hasConflict) {
              startBasis =
                  await onBackfillStartConflict(
                    repeatTodo,
                    normalizedStartDate,
                    normalizedBackfillStartDate,
                  ) ??
                  BackfillStartBasis.startDate;
            }
          }

          DateTime? alignedStartDate = computeAlignedStartDateForBackfillChoice(
            repeatTodo: effectiveRepeatTodo,
            now: now,
            startBasis: startBasis,
          );
          alignedStartDate ??= onBackfillStartConflict == null
              ? _inferAlignedStartDateFromExistingBackfilledTodos(
                  effectiveRepeatTodo,
                  now,
                )
              : null;
          if (alignedStartDate != null) {
            final updated = effectiveRepeatTodo.copyWith(
              startDate: alignedStartDate,
            );
            await updateRepeatTodo(updated, skipAIProcessing: true);
            effectiveRepeatTodo = updated;
            startBasis = BackfillStartBasis.startDate;
          }

          await _pruneOutOfRangeBackfilledTodosForRepeat(
            effectiveRepeatTodo,
            now,
            startBasis: startBasis,
          );

          final backfilledLatestDay = await _backfillRepeatTodosIfNeeded(
            effectiveRepeatTodo,
            now,
            startBasis: startBasis,
          );

          // 检查今天是否已经为这个重复模板生成了任务
          final hasGeneratedToday = _hasGeneratedTodoForToday(
            effectiveRepeatTodo,
            now,
          );

          var generatedToday = false;
          if (!hasGeneratedToday) {
            // 检查重复任务是否应该在今天生成
            if (_shouldGenerateForToday(effectiveRepeatTodo, now)) {
              await _generateTodoFromRepeat(effectiveRepeatTodo);
              generatedToday = true;
            } else {
              // 如果不应该在今天生成，但有未来的 lastGeneratedDate，重置它
              if (effectiveRepeatTodo.lastGeneratedDate != null &&
                  effectiveRepeatTodo.lastGeneratedDate!.isAfter(now)) {
                effectiveRepeatTodo = effectiveRepeatTodo.copyWith(
                  lastGeneratedDate: null,
                );
                await updateRepeatTodo(
                  effectiveRepeatTodo,
                  skipAIProcessing: true,
                );
              }
            }
          }

          DateTime? newLastGeneratedDate;
          if (generatedToday) {
            newLastGeneratedDate = now;
          } else if (backfilledLatestDay != null) {
            newLastGeneratedDate = DateTime(
              backfilledLatestDay.year,
              backfilledLatestDay.month,
              backfilledLatestDay.day,
              now.hour,
              now.minute,
              now.second,
            );
          }

          if (newLastGeneratedDate != null) {
            final currentLast = effectiveRepeatTodo.lastGeneratedDate;
            final shouldUpdate =
                currentLast == null ||
                _normalizeDay(
                  currentLast,
                ).isBefore(_normalizeDay(newLastGeneratedDate));

            if (shouldUpdate) {
              // Update last generated date (skip AI processing for this metadata update)
              final updatedRepeatTodo = effectiveRepeatTodo.copyWith(
                lastGeneratedDate: newLastGeneratedDate,
              );
              await updateRepeatTodo(updatedRepeatTodo, skipAIProcessing: true);
            }
          }
        }
      }
    });
  }

  // 只刷新今天的重复任务：删除今天的任务并重新生成（如果应该生成）
  Future<void> refreshTodayRepeatTasks() async {
    return _enqueueRepeatOperation(() async {
      await _hydrateRepeatGenerationStateIfNeeded();

      final now = _getLocalDateTime();
      debugPrint(
        'refreshTodayRepeatTasks called at: $now (local hour: ${now.hour}:${now.minute})',
      );
      _lastRepeatCheck = now;

      // 清理今天的过期重复任务
      await _cleanupExpiredRepeatTasks(now);

      // 重要：在清理后重新加载 todos 以确保数据一致性
      await loadTodos();

      debugPrint('Processing ${_repeatTodos.length} repeat tasks');

      for (final repeatTodo in _repeatTodos) {
        // Check if repeat task has expired and should be deactivated
        if (repeatTodo.isActive &&
            repeatTodo.endDate != null &&
            _normalizeDay(now).isAfter(_normalizeDay(repeatTodo.endDate!))) {
          debugPrint('Deactivating expired repeat task: "${repeatTodo.title}"');
          final deactivatedRepeatTodo = repeatTodo.copyWith(isActive: false);
          await updateRepeatTodo(deactivatedRepeatTodo, skipAIProcessing: true);
          continue;
        }

        // Only process active repeat tasks
        if (repeatTodo.isActive) {
          // 检查今天是否已经为这个重复模板生成了任务
          final hasGeneratedToday = _hasGeneratedTodoForToday(repeatTodo, now);

          debugPrint(
            'Refresh: Repeat task "${repeatTodo.title}" - hasGeneratedToday: $hasGeneratedToday',
          );

          if (!hasGeneratedToday) {
            // 检查重复任务是否应该在今天生成
            final shouldGenerate = _shouldGenerateForToday(repeatTodo, now);

            debugPrint(
              'Repeat task "${repeatTodo.title}" - should generate today: $shouldGenerate',
            );
            debugPrint('  - Repeat type: ${repeatTodo.repeatType}');
            debugPrint('  - Current date: $now');
            debugPrint(
              '  - Current local time: ${now.hour}:${now.minute}:${now.second}',
            );
            debugPrint('  - Start date: ${repeatTodo.startDate}');
            debugPrint('  - End date: ${repeatTodo.endDate}');
            debugPrint('  - Last generated: ${repeatTodo.lastGeneratedDate}');

            if (shouldGenerate) {
              // 在生成前，再次检查以确保没有重复
              final hasGenerated = _hasGeneratedTodoForRepeatToday(
                repeatTodo,
                now,
              );
              if (!hasGenerated) {
                debugPrint(
                  'Generating todo for repeat task "${repeatTodo.title}" at ${now.hour}:${now.minute}',
                );
                await _generateTodoFromRepeat(repeatTodo);

                // Update last generated date to today (skip AI processing for this metadata update)
                final updatedRepeatTodo = repeatTodo.copyWith(
                  lastGeneratedDate: now,
                );
                await updateRepeatTodo(
                  updatedRepeatTodo,
                  skipAIProcessing: true,
                );
              } else {
                debugPrint(
                  'Task already generated for today for "${repeatTodo.title}"',
                );
              }
            } else {
              debugPrint(
                'Should not generate today for "${repeatTodo.title}" - current time ${now.hour}:${now.minute} may not meet repeat conditions',
              );
              // 如果不应该在今天生成，但有未来的 lastGeneratedDate，重置它
              if (repeatTodo.lastGeneratedDate != null &&
                  repeatTodo.lastGeneratedDate!.isAfter(now)) {
                debugPrint(
                  'Resetting future lastGeneratedDate for "${repeatTodo.title}"',
                );
                final correctedRepeatTodo = repeatTodo.copyWith(
                  lastGeneratedDate: null,
                );
                await updateRepeatTodo(
                  correctedRepeatTodo,
                  skipAIProcessing: true,
                );
              }
            }
          } else {
            debugPrint('Already generated today for "${repeatTodo.title}"');
          }
        }
      }
    });
  }

  // 检查重复任务是否应该在今天生成
  bool _shouldGenerateForToday(
    RepeatTodoModel repeatTodo,
    DateTime currentDate,
  ) {
    return repeatTodo.shouldGenerateForDate(currentDate);
  }

  Future<void> _cleanupExpiredRepeatTasks(DateTime currentDate) async {
    // 清理已过期重复任务生成的待办事项
    final expiredRepeatTodoIds = _repeatTodos
        .where(
          (repeatTodo) =>
              repeatTodo.endDate != null &&
              _normalizeDay(
                currentDate,
              ).isAfter(_normalizeDay(repeatTodo.endDate!)),
        )
        .map((repeatTodo) => repeatTodo.id)
        .toSet();

    if (expiredRepeatTodoIds.isEmpty) return;

    final todosToRemove = _todos
        .where(
          (todo) =>
              todo.isGeneratedFromRepeat &&
              todo.repeatTodoId != null &&
              expiredRepeatTodoIds.contains(todo.repeatTodoId),
        )
        .toList();

    for (final todo in todosToRemove) {
      await deleteTodo(todo.id);
    }
  }

  bool _hasGeneratedTodoForToday(
    RepeatTodoModel repeatTodo,
    DateTime currentDate,
  ) {
    // 检查今天是否已经为这个重复模板生成了任务
    final today = _normalizeDay(currentDate);

    final todayTodos = _todos
        .where(
          (todo) =>
              todo.repeatTodoId == repeatTodo.id &&
              todo.isGeneratedFromRepeat &&
              _isSameDay(todo.createdAt, today),
        )
        .toList();

    return todayTodos.isNotEmpty;
  }

  // 检查是否已经为指定的重复模板在今天生成了任务（更严格检查）
  bool _hasGeneratedTodoForRepeatToday(
    RepeatTodoModel repeatTodo,
    DateTime currentDate,
  ) {
    // 检查今天是否已经为这个重复模板生成了任务
    final today = _normalizeDay(currentDate);

    final todayTodos = _todos
        .where(
          (todo) =>
              todo.repeatTodoId == repeatTodo.id &&
              todo.isGeneratedFromRepeat &&
              _isSameDay(todo.createdAt, today),
        )
        .toList();

    return todayTodos.isNotEmpty;
  }

  // Generate todo from repeat and return the created todo ID
  Future<String?> _generateTodoFromRepeat(
    RepeatTodoModel repeatTodo, {
    DateTime? forDate,
    bool markCompleted = false,
  }) async {
    final now = _getLocalDateTime();
    debugPrint('Generating todo from repeat template at local time: $now');
    debugPrint(
      'Current local time details - Hour: ${now.hour}, Minute: ${now.minute}, Second: ${now.second}',
    );

    final targetDateTime = forDate ?? now;
    final targetDate = _normalizeDay(targetDateTime);

    if (_hasGeneratedTodoForDate(repeatTodo, targetDate)) {
      debugPrint(
        'Skip generating repeat todo "${repeatTodo.title}" for $targetDate: already exists',
      );
      return null;
    }

    final createdAt = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    // 直接继承重复任务模板的AI数据，不进行重新处理
    String? inheritedCategory = repeatTodo.aiCategory;
    int inheritedPriority = repeatTodo.aiPriority;
    bool inheritedProcessed = repeatTodo.aiProcessed;

    final generatedDate = targetDate;
    DateTime? inheritedStartTime;
    if (repeatTodo.startTimeMinutes != null) {
      inheritedStartTime = generatedDate.add(
        Duration(minutes: repeatTodo.startTimeMinutes!),
      );
    }
    DateTime? inheritedEndTime;
    if (repeatTodo.endTimeMinutes != null) {
      inheritedEndTime = generatedDate.add(
        Duration(minutes: repeatTodo.endTimeMinutes!),
      );
    }

    // 直接使用当前本地时间创建任务，不进行任何标准化
    final generatedKey = _repeatGeneratedKey(repeatTodo.id, targetDate);
    final newTodo = TodoModel.create(
      title: repeatTodo.title,
      description: repeatTodo.description,
      order: _todos.length,
      repeatTodoId: repeatTodo.id,
      isGeneratedFromRepeat: true,
      generatedKey: generatedKey,
      dataUnit: repeatTodo.dataUnit,
      aiCategory: inheritedCategory,
      aiPriority: inheritedPriority,
      aiProcessed: inheritedProcessed,
      startTime: inheritedStartTime,
      endTime: inheritedEndTime,
    );

    // 确保创建的任务使用指定日期，但保留当前时刻的时间分量（避免标准化为00:00）
    final correctedTodo = newTodo.copyWith(
      createdAt: createdAt,
      isCompleted: markCompleted,
      completedAt: markCompleted ? createdAt : null,
    );

    debugPrint('Todo created with timestamp: ${correctedTodo.createdAt}');
    debugPrint(
      'Todo creation time - Hour: ${correctedTodo.createdAt.hour}, Minute: ${correctedTodo.createdAt.minute}',
    );

    await _putTodo(correctedTodo);

    _todos.add(correctedTodo);
    _applyFilters();
    await _updateStatistics();

    // 更新缓存以确保数据一致性
    await _invalidateTodoCache();

    notifyListeners();

    // Return the created todo ID for potential AI syncing
    return correctedTodo.id;
  }

  DateTime _normalizeDay(DateTime dateTime) => localDay(dateTime);

  bool _isLikelyBackfilledRepeatTodoInstance(TodoModel todo) {
    if (!todo.isGeneratedFromRepeat || todo.repeatTodoId == null) return false;
    return isLikelyBackfilledRepeatTodoInstance(
      todoId: todo.id,
      todoCreatedAt: todo.createdAt,
    );
  }

  Future<void> _deleteTodosBatch(Iterable<TodoModel> todos) async {
    final todosBox = _hiveService.todosBox;
    if (_todos.isEmpty && todosBox.isNotEmpty) {
      _todos = todosBox.values.toList();
      _todos = _todos
          .where(
            (t) => !_syncWriteService.isTombstonedSync(SyncTypes.todo, t.id),
          )
          .toList();
      _todos.sort((a, b) => a.order.compareTo(b.order));
    }

    final todoList = todos.toList(growable: false);
    if (todoList.isEmpty) return;

    for (final todo in todoList) {
      final id = todo.id;
      _debounceTimers[id]?.cancel();
      _debounceTimers.remove(id);
      _processingTodos.remove(id);
      _failedAiRequests.remove(id);
      _lastRequestTime.remove(id);
      await _notificationService.cancelTodoReminder(id);
    }

    final idsToDelete = todoList.map((t) => t.id).toList(growable: false);
    for (final id in idsToDelete) {
      await _tombstoneTodo(id);
    }

    final idSet = idsToDelete.toSet();
    _todos.removeWhere((todo) => idSet.contains(todo.id));

    _applyFilters();
    await _updateStatistics();
    await _invalidateTodoCache();
    notifyListeners();
  }

  Future<int> _pruneOutOfRangeBackfilledTodosForRepeat(
    RepeatTodoModel repeatTodo,
    DateTime now, {
    BackfillStartBasis startBasis = BackfillStartBasis.startDate,
  }) async {
    final todosBox = _hiveService.todosBox;
    if (_todos.isEmpty && todosBox.isNotEmpty) {
      _todos = todosBox.values.toList();
      _todos = _todos
          .where(
            (t) => !_syncWriteService.isTombstonedSync(SyncTypes.todo, t.id),
          )
          .toList();
      _todos.sort((a, b) => a.order.compareTo(b.order));
    }

    final window = computeBackfillWindow(
      repeatTodo: repeatTodo,
      now: now,
      startBasis: startBasis,
    );

    final start = window.start;
    final end = window.end;

    final toDelete = _todos
        .where((todo) {
          if (todo.repeatTodoId != repeatTodo.id) return false;
          if (!_isLikelyBackfilledRepeatTodoInstance(todo)) return false;

          final day = _normalizeDay(todo.createdAt);
          if (start != null && day.isBefore(start)) return true;
          if (day.isAfter(end)) return true;
          return false;
        })
        .toList(growable: false);

    if (toDelete.isEmpty) return 0;
    await _deleteTodosBatch(toDelete);
    return toDelete.length;
  }

  DateTime? _inferAlignedStartDateFromExistingBackfilledTodos(
    RepeatTodoModel repeatTodo,
    DateTime now,
  ) {
    if (!repeatTodo.backfillEnabled || repeatTodo.backfillDays < 1) return null;
    if (repeatTodo.startDate == null) return null;

    final normalizedStartDate = _normalizeDay(repeatTodo.startDate!);
    final backfillStart = _normalizeDay(
      now,
    ).subtract(Duration(days: repeatTodo.backfillDays));

    if (!normalizedStartDate.isAfter(backfillStart)) return null;

    final hasExistingBackfilledBeforeStart = _todos.any((todo) {
      if (!todo.isGeneratedFromRepeat || todo.repeatTodoId != repeatTodo.id) {
        return false;
      }
      if (!_isLikelyBackfilledRepeatTodoInstance(todo)) return false;

      final day = _normalizeDay(todo.createdAt);
      return day.isBefore(normalizedStartDate) && !day.isBefore(backfillStart);
    });

    return hasExistingBackfilledBeforeStart ? backfillStart : null;
  }

  bool _hasGeneratedTodoForDate(RepeatTodoModel repeatTodo, DateTime dateTime) {
    final date = _normalizeDay(dateTime);
    final expectedKey = _repeatGeneratedKey(repeatTodo.id, date);

    return _todos.any(
      (todo) =>
          todo.repeatTodoId == repeatTodo.id &&
          todo.isGeneratedFromRepeat &&
          (todo.generatedKey == expectedKey ||
              _isSameDay(todo.createdAt, date)),
    );
  }

  Future<DateTime?> _backfillRepeatTodosIfNeeded(
    RepeatTodoModel repeatTodo,
    DateTime now, {
    BackfillStartBasis startBasis = BackfillStartBasis.startDate,
  }) async {
    if (!repeatTodo.backfillEnabled) return null;

    final backfillDays = repeatTodo.backfillDays;
    if (backfillDays < 1) return null;

    final today = _normalizeDay(now);
    final end = today.subtract(const Duration(days: 1));

    final earliestBySetting = today.subtract(Duration(days: backfillDays));
    final earliestByStart = startBasis == BackfillStartBasis.backfillDays
        ? earliestBySetting
        : (repeatTodo.startDate != null
              ? _normalizeDay(repeatTodo.startDate!)
              : earliestBySetting);

    var start = earliestByStart.isAfter(earliestBySetting)
        ? earliestByStart
        : earliestBySetting;

    var effectiveEnd = end;
    if (repeatTodo.endDate != null) {
      final normalizedEndDate = _normalizeDay(repeatTodo.endDate!);
      if (normalizedEndDate.isBefore(effectiveEnd)) {
        effectiveEnd = normalizedEndDate;
      }
    }

    if (effectiveEnd.isBefore(start)) return null;

    DateTime? latestGeneratedDay;
    for (
      var date = start;
      !date.isAfter(effectiveEnd);
      date = date.add(const Duration(days: 1))
    ) {
      final shouldGenerate = repeatTodo.shouldGenerateForDate(
        date,
        ignoreStartDate: startBasis == BackfillStartBasis.backfillDays,
      );
      if (!shouldGenerate) continue;
      if (_hasGeneratedTodoForDate(repeatTodo, date)) continue;

      await _generateTodoFromRepeat(
        repeatTodo,
        forDate: date,
        markCompleted: repeatTodo.backfillAutoComplete,
      );
      latestGeneratedDay = date;
    }

    return latestGeneratedDay;
  }

  // 同步重复任务模板的变更到已生成的待办事项
  Future<void> _syncRepeatTodoChangesToGeneratedTodos(
    RepeatTodoModel originalTodo,
    RepeatTodoModel updatedTodo, {
    bool includeCompleted = false,
  }) async {
    // 检查关键字段是否有变更
    final titleChanged = originalTodo.title != updatedTodo.title;
    final descriptionChanged =
        originalTodo.description != updatedTodo.description;
    final categoryChanged = originalTodo.aiCategory != updatedTodo.aiCategory;
    final priorityChanged = originalTodo.aiPriority != updatedTodo.aiPriority;
    final dataUnitChanged = originalTodo.dataUnit != updatedTodo.dataUnit;
    final startTimeChanged =
        originalTodo.startTimeMinutes != updatedTodo.startTimeMinutes;
    final endTimeChanged =
        originalTodo.endTimeMinutes != updatedTodo.endTimeMinutes;

    // 如果没有关键字段变更，则不需要同步
    if (!titleChanged &&
        !descriptionChanged &&
        !categoryChanged &&
        !priorityChanged &&
        !dataUnitChanged &&
        !startTimeChanged &&
        !endTimeChanged) {
      return;
    }

    // 获取所有已生成的待办事项（根据参数决定是否包含已完成任务）
    final generatedTodos = _todos
        .where(
          (todo) =>
              todo.repeatTodoId == updatedTodo.id &&
              todo.isGeneratedFromRepeat &&
              (includeCompleted || !todo.isCompleted),
        )
        .toList();

    if (generatedTodos.isEmpty) {
      return;
    }

    for (final todo in generatedTodos) {
      // 只更新发生变化的字段
      TodoModel updatedGeneratedTodo = todo;

      final todoDate = localDay(todo.createdAt);

      if (titleChanged) {
        updatedGeneratedTodo = updatedGeneratedTodo.copyWith(
          title: updatedTodo.title,
        );
      }
      if (descriptionChanged) {
        updatedGeneratedTodo = updatedGeneratedTodo.copyWith(
          description: updatedTodo.description,
        );
      }
      if (categoryChanged) {
        updatedGeneratedTodo = updatedGeneratedTodo.copyWith(
          aiCategory: updatedTodo.aiCategory,
        );
      }
      if (priorityChanged) {
        updatedGeneratedTodo = updatedGeneratedTodo.copyWith(
          aiPriority: updatedTodo.aiPriority,
        );
      }
      if (dataUnitChanged) {
        updatedGeneratedTodo = updatedGeneratedTodo.copyWith(
          dataUnit: updatedTodo.dataUnit,
        );
      }
      if (startTimeChanged) {
        final newStartTime = updatedTodo.startTimeMinutes != null
            ? todoDate.add(Duration(minutes: updatedTodo.startTimeMinutes!))
            : null;
        updatedGeneratedTodo = updatedGeneratedTodo.copyWith(
          startTime: newStartTime,
        );
      }
      if (endTimeChanged) {
        final newEndTime = updatedTodo.endTimeMinutes != null
            ? todoDate.add(Duration(minutes: updatedTodo.endTimeMinutes!))
            : null;
        updatedGeneratedTodo = updatedGeneratedTodo.copyWith(
          endTime: newEndTime,
        );
      }

      // 更新AI处理状态
      if (categoryChanged || priorityChanged) {
        final isCategoryValid =
            updatedGeneratedTodo.aiCategory?.isNotEmpty == true;
        final isPriorityValid = updatedGeneratedTodo.aiPriority > 0;
        updatedGeneratedTodo = updatedGeneratedTodo.copyWith(
          aiProcessed: isCategoryValid && isPriorityValid,
        );
      }

      // 保存更新
      await _putTodo(updatedGeneratedTodo);

      // 更新内存中的列表
      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _todos[index] = updatedGeneratedTodo;
      }
    }

    _applyFilters();
    await _invalidateTodoCache();
  }

  // 同步AI数据到刚创建的任务
  Future<void> _syncAIToCreatedTodo(
    String todoId,
    RepeatTodoModel processedTemplate,
  ) async {
    try {
      final todosBox = _hiveService.todosBox;
      final todo = todosBox.get(todoId);

      if (todo == null) {
        return;
      }

      // 更新任务的AI数据
      final updatedTodo = todo.copyWith(
        aiCategory: processedTemplate.aiCategory,
        aiPriority: processedTemplate.aiPriority,
        aiProcessed: processedTemplate.aiProcessed,
      );

      await _putTodo(updatedTodo);

      // 更新内存中的列表
      final index = _todos.indexWhere((t) => t.id == todoId);
      if (index != -1) {
        _todos[index] = updatedTodo;
        _applyFilters();
      }

      // 通知UI更新
      notifyListeners();
    } catch (e) {
      debugPrint('TodoProvider: Error syncing AI data to created todo: $e');
    }
  }

  // 确保重复任务的一致性
  Future<void> _ensureRepeatTodoConsistency(String repeatTodoId) async {
    RepeatTodoModel? repeatTodo;
    try {
      repeatTodo = _repeatTodos.firstWhere((rt) => rt.id == repeatTodoId);
    } catch (e) {
      debugPrint(
        'TodoProvider: Repeat todo not found for id $repeatTodoId in _ensureRepeatTodoConsistency, creating default: $e',
      );
      repeatTodo = RepeatTodoModel.create(
        title: '',
        repeatType: RepeatType.daily,
      );
    }

    // 获取该重复任务生成的所有任务
    final generatedTodos = _todos
        .where(
          (todo) =>
              todo.repeatTodoId == repeatTodoId && todo.isGeneratedFromRepeat,
        )
        .toList();

    if (generatedTodos.isNotEmpty) {
      // 找到最新的生成任务
      final latestGenerated = generatedTodos.reduce(
        (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
      );

      // 确保重复任务的 lastGeneratedDate 不晚于最新生成的任务
      if (repeatTodo.lastGeneratedDate == null ||
          repeatTodo.lastGeneratedDate!.isBefore(latestGenerated.createdAt)) {
        final updatedRepeatTodo = repeatTodo.copyWith(
          lastGeneratedDate: latestGenerated.createdAt,
        );
        await updateRepeatTodo(updatedRepeatTodo);
      }
    }
  }

  // 使缓存失效以确保数据一致性
  Future<void> _invalidateTodoCache() async {
    try {
      // 清除所有缓存以确保完全一致性
      await CacheService.clearCache();

      // 清除内存缓存
      CacheService.clearMemoryCache();

      debugPrint('All todo cache invalidated successfully');
    } catch (e) {
      debugPrint('Error invalidating cache: $e');
    }
  }

  // 使特定待办项的缓存失效（用于提醒更改）
  Future<void> _invalidateTodoCacheForId(String todoId) async {
    try {
      // 获取待办项信息
      final todoIndex = _todos.indexWhere((t) => t.id == todoId);
      if (todoIndex == -1) {
        debugPrint('Todo not found for cache invalidation: $todoId');
        return;
      }
      final todo = _todos[todoIndex];

      // 清除包含此待办项的缓存
      await CacheService.clearTodoCache(todoId);

      // 对于已完成的待办事项，不清除AI缓存以保留其分类和优先级数据
      if (!todo.isCompleted) {
        // 清除AI缓存（当提醒时间改变时，需要重新计算优先级等）
        final languageCode = _languageProvider?.currentLanguageCode ?? 'en';
        await _aiCacheService.clearTodoAICache(todo, languageCode);
        debugPrint('AI cache invalidated for active todo $todoId');
      } else {
        debugPrint('Preserving AI cache for completed todo $todoId');
      }

      // 清除内存缓存
      CacheService.clearMemoryCache();

      debugPrint('Cache invalidated for todo $todoId');
    } catch (e) {
      debugPrint('Error invalidating cache for todo $todoId: $e');
    }
  }

  Future<void> reorderRepeatTodos(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final repeatTodo = _repeatTodos.removeAt(oldIndex);

    if (newIndex > oldIndex) {
      newIndex--;
    }

    _repeatTodos.insert(newIndex, repeatTodo);

    for (int i = 0; i < _repeatTodos.length; i++) {
      _repeatTodos[i] = _repeatTodos[i].copyWith(order: i);
      await _putRepeatTodo(_repeatTodos[i]);
    }

    notifyListeners();
  }

  // Process missing AI data for a specific todo
  void processMissingAIDataForTodo(TodoModel todo) {
    if (_aiProvider == null ||
        !_aiProvider!.isAIServiceValid ||
        todo.isCompleted) {
      return;
    }

    // Skip AI processing for todos generated from repeat templates (they inherit AI data from template)
    if (todo.isGeneratedFromRepeat) {
      return;
    }

    // Check if we recently had a rate limit error (within 2 minutes)
    final now = DateTime.now();
    if (_lastRateLimitError != null) {
      final timeSinceRateLimit = now.difference(_lastRateLimitError!);
      if (timeSinceRateLimit.inMinutes < 2) {
        debugPrint(
          'Skipping all AI processing due to recent rate limit error (${timeSinceRateLimit.inMinutes}m ago)',
        );
        return;
      }
    }

    // Check if we're already processing this todo to avoid duplicate requests
    if (_processingTodos.contains(todo.id)) return;

    // Check if this todo recently failed AI processing (within 5 minutes)
    final lastFailure = _failedAiRequests[todo.id];
    if (lastFailure != null) {
      final timeSinceFailure = now.difference(lastFailure);
      if (timeSinceFailure.inMinutes < 5) {
        debugPrint(
          'Skipping AI processing for ${todo.id} due to recent failure (${timeSinceFailure.inMinutes}m ago)',
        );
        return;
      }
    }

    // Check if we made a request recently (within 30 seconds) to avoid UI spam
    final lastRequest = _lastRequestTime[todo.id];
    if (lastRequest != null) {
      final timeSinceRequest = now.difference(lastRequest);
      if (timeSinceRequest.inSeconds < 30) {
        debugPrint(
          'Skipping AI processing for ${todo.id} due to recent request (${timeSinceRequest.inSeconds}s ago)',
        );
        return;
      }
    }

    // Cancel any existing debounce timer for this todo
    _debounceTimers[todo.id]?.cancel();

    // Add to processing set and update last request time
    _processingTodos.add(todo.id);
    _lastRequestTime[todo.id] = now;

    // Create a debounce timer to actually process the request
    _debounceTimers[todo.id] = Timer(Duration(milliseconds: 500), () {
      _debounceTimers.remove(todo.id);
      // Use unawaited to avoid blocking the UI
      unawaited(_processTodoWithAIBackground(todo));
    });
  }

  // Process todo with AI in background
  Future<void> _processTodoWithAIBackground(TodoModel todo) async {
    if (_aiProvider == null || !_aiProvider!.isAIServiceValid) return;

    try {
      // Double-check if todo is still in memory list (might have been deleted)
      if (!_todos.any((t) => t.id == todo.id)) {
        _processingTodos.remove(todo.id);
        return;
      }

      // Check if todo still exists in the database
      final todosBox = _hiveService.todosBox;
      final existingTodo = todosBox.get(todo.id);
      if (existingTodo == null) {
        _processingTodos.remove(todo.id);
        return;
      }

      // Get current language code
      final languageCode = _languageProvider?.currentLanguageCode ?? 'en';
      bool needsUpdate = false;

      // Check what needs to be processed
      bool needsCategory =
          _aiProvider!.settings.enableAutoCategorization &&
          (todo.aiCategory == null || todo.aiCategory!.isEmpty);
      bool needsPriority =
          _aiProvider!.settings.enablePrioritySorting && (todo.aiPriority == 0);

      if (!needsCategory && !needsPriority) return; // Nothing to process

      // Process categorization if needed
      String? newCategory;
      if (needsCategory) {
        final category = await _aiProvider!.aiService?.categorizeTask(
          todo,
          languageCode,
        );
        if (category != null && category.isNotEmpty) {
          newCategory = category;
          needsUpdate = true;
        }
      }

      // Process priority if needed
      int? newPriority;
      if (needsPriority) {
        final priority = await _aiProvider!.aiService?.assessPriority(
          todo,
          languageCode,
        );
        if (priority != null && priority > 0) {
          newPriority = priority;
          needsUpdate = true;
        }
      }

      // Final check before updating - todo might have been deleted during AI processing
      if (!_todos.any((t) => t.id == todo.id)) {
        return;
      }

      // Update if we made changes
      if (needsUpdate) {
        // Only mark as processed if both required fields are properly set
        final categoryOk =
            (newCategory != null && newCategory.isNotEmpty) ||
            (todo.aiCategory != null &&
                todo.aiCategory!.isNotEmpty &&
                !needsCategory);
        final priorityOk =
            (newPriority != null && newPriority > 0) ||
            (todo.aiPriority > 0 && !needsPriority);

        final updatedTodo = todo.copyWith(
          aiCategory: newCategory ?? todo.aiCategory,
          aiPriority: newPriority ?? todo.aiPriority,
          aiProcessed: categoryOk && priorityOk,
        );

        // Save to Hive database
        await _putTodo(updatedTodo);

        // Ensure Hive flushes to disk
        await _hiveService.todosBox.flush();

        // Update the todo in the in-memory list
        final index = _todos.indexWhere((t) => t.id == todo.id);
        if (index != -1) {
          _todos[index] = updatedTodo;
          _applyFilters();
        }

        // Refresh UI
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error processing todo with AI in background: $e');
      // Mark this todo as failed to prevent immediate retry
      _failedAiRequests[todo.id] = DateTime.now();

      // Check if this is a rate limit error (429)
      if (e.toString().contains('429') ||
          e.toString().contains('Too Many Requests')) {
        debugPrint('Rate limit detected, setting global cooldown');
        _lastRateLimitError = DateTime.now();
      }
    }
    // Removed finally block since we remove from processing set early

    // Clean up old failure records periodically
    _cleanupOldFailureRecords();
  }

  void _cleanupOldFailureRecords() {
    final now = DateTime.now();
    _failedAiRequests.removeWhere((todoId, failureTime) {
      final timeSinceFailure = now.difference(failureTime);
      return timeSinceFailure.inMinutes >=
          10; // Remove records older than 10 minutes
    });
  }

  // Process withdrawn todo with AI
  Future<void> _processWithdrawnTodoWithAI(TodoModel todo) async {
    if (_aiProvider == null || !_aiProvider!.isAIServiceValid) return;

    bool needsProcessing = false;
    bool needsCategory = false;
    bool needsPriority = false;

    // Check if AI features are enabled and if the todo is missing information
    if (_aiProvider!.settings.enableAutoCategorization &&
        (todo.aiCategory == null || !todo.aiProcessed)) {
      needsCategory = true;
      needsProcessing = true;
    }

    if (_aiProvider!.settings.enablePrioritySorting &&
        (todo.aiPriority == 0 || !todo.aiProcessed)) {
      needsPriority = true;
      needsProcessing = true;
    }

    if (!needsProcessing) return;

    try {
      // Get current language code
      final languageCode = _languageProvider?.currentLanguageCode ?? 'en';
      bool needsUpdate = false;

      // Process categorization if needed
      String? newCategory;
      if (needsCategory) {
        final category = await _aiProvider!.aiService?.categorizeTask(
          todo,
          languageCode,
        );
        if (category != null) {
          newCategory = category;
          needsUpdate = true;
        }
      }

      // Process priority if needed
      int? newPriority;
      if (needsPriority) {
        final priority = await _aiProvider!.aiService?.assessPriority(
          todo,
          languageCode,
        );
        if (priority != null) {
          newPriority = priority;
          needsUpdate = true;
        }
      }

      // Update if we made changes
      if (needsUpdate) {
        // Only mark as processed if both required fields are properly set
        final categoryOk =
            (newCategory != null && newCategory.isNotEmpty) ||
            (todo.aiCategory != null &&
                todo.aiCategory!.isNotEmpty &&
                !needsCategory);
        final priorityOk =
            (newPriority != null && newPriority > 0) ||
            (todo.aiPriority > 0 && !needsPriority);

        final updatedTodo = todo.copyWith(
          aiCategory: newCategory ?? todo.aiCategory,
          aiPriority: newPriority ?? todo.aiPriority,
          aiProcessed: categoryOk && priorityOk,
        );

        // Save to Hive database
        await _putTodo(updatedTodo);

        // Ensure Hive flushes to disk
        await _hiveService.todosBox.flush();

        // Update the todo in the in-memory list
        final index = _todos.indexWhere((t) => t.id == todo.id);
        if (index != -1) {
          _todos[index] = updatedTodo;
          _applyFilters();
        }

        // Refresh UI
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error processing withdrawn todo with AI: $e');
    }
  }

  // Batch process unprocessed todos with AI
  Future<void> processUnprocessedTodosWithAI() async {
    final isAiProviderNull = _aiProvider == null;
    final isAiServiceValid = _aiProvider?.isAIServiceValid ?? false;

    if (isAiProviderNull || !isAiServiceValid) {
      // Add more detailed debugging
      if (_aiProvider != null) {}
      return;
    }

    final unprocessedTodos = _todos
        .where(
          (todo) =>
              !todo.aiProcessed &&
              !todo.isCompleted &&
              !(todo.isGeneratedFromRepeat && todo.repeatTodoId != null),
        )
        .toList();
    if (unprocessedTodos.isEmpty) return;

    try {
      final results = await _aiProvider!.processTasksBatch(unprocessedTodos);

      // Update todos with AI results
      for (final entry in results.entries) {
        try {
          final todoId = entry.key;
          final result = entry.value as Map<String, dynamic>?;

          if (result == null) continue;

          final todoIndex = _todos.indexWhere((t) => t.id == todoId);
          if (todoIndex == -1) continue;

          final todo = _todos[todoIndex];
          final category = result['category'] as String?;
          final priority = (result['priority'] as int?) ?? 0;

          // Only mark as processed if both category and priority are valid
          final isCategoryValid = category?.isNotEmpty == true;
          final isPriorityValid = priority > 0;

          final updatedTodo = todo.copyWith(
            aiCategory: category,
            aiPriority: priority,
            aiProcessed: isCategoryValid && isPriorityValid,
          );

          final todosBox = _hiveService.todosBox;
          await _putTodo(updatedTodo);

          // Ensure Hive flushes to disk for batch processing
          await _hiveService.todosBox.flush();

          _todos[todoIndex] = updatedTodo;

          // Verify the save was successful
          final savedTodo = todosBox.get(updatedTodo.id);

          if (savedTodo?.aiCategory != updatedTodo.aiCategory ||
              savedTodo?.aiPriority != updatedTodo.aiPriority ||
              savedTodo?.aiProcessed != updatedTodo.aiProcessed) {
            debugPrint(
              'TodoProvider: *** BATCH SAVE VERIFICATION FAILED FOR TODO: ${todo.title} ***',
            );
          }
        } catch (e) {
          debugPrint('Error processing AI result for todo: $e');
          continue;
        }
      }

      _applyFilters();
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error batch processing todos with AI: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Get AI-generated motivational message for statistics
  Future<String?> getMotivationalMessageForStatistics(
    StatisticsModel statistics,
  ) async {
    if (_aiProvider == null || !_aiProvider!.isAIServiceValid) return null;

    try {
      final languageCode = _languageProvider?.currentLanguageCode;
      return await _aiProvider!.generateMotivationalMessage(
        statistics,
        languageCode: languageCode,
      );
    } catch (e) {
      // Error generating motivational message
      return null;
    }
  }

  // Get AI-generated completion motivation message
  Future<String?> getCompletionMotivationMessage() async {
    if (_aiProvider == null || !_aiProvider!.isAIServiceValid) return null;

    try {
      final languageCode = _languageProvider?.currentLanguageCode;
      return await _aiProvider!.generateIncentiveMessage(
        completedTodosCount,
        _todos.length,
        languageCode: languageCode,
      );
    } catch (e) {
      // Error generating completion motivation
      return null;
    }
  }

  // Get AI-generated smart notification for a todo
  Future<String?> getSmartNotificationForTodo(TodoModel todo) async {
    if (_aiProvider == null || !_aiProvider!.isAIServiceValid) return null;

    try {
      final languageCode = _languageProvider?.currentLanguageCode;
      return await _aiProvider!.generateSmartNotification(
        todo,
        languageCode: languageCode,
      );
    } catch (e) {
      debugPrint('Error generating smart notification: $e');
      return null;
    }
  }

  // Debug method to check actual Hive persistence
  Future<void> debugCheckHivePersistence() async {
    debugPrint('=== DEBUG: Checking Hive Persistence ===');

    try {
      final todosBox = _hiveService.todosBox;
      debugPrint('Todos box contains ${todosBox.length} items');

      for (final key in todosBox.keys) {
        final hiveTodo = todosBox.get(key);
        if (hiveTodo != null) {
          final memoryTodo = _todos.firstWhere(
            (t) => t.id == hiveTodo.id,
            orElse: () => hiveTodo,
          );

          debugPrint('Todo ID: ${hiveTodo.id}');
          debugPrint('  Title: ${hiveTodo.title}');
          debugPrint(
            '  Hive - Category: ${hiveTodo.aiCategory}, Priority: ${hiveTodo.aiPriority}, Processed: ${hiveTodo.aiProcessed}',
          );
          debugPrint(
            '  Memory - Category: ${memoryTodo.aiCategory}, Priority: ${memoryTodo.aiPriority}, Processed: ${memoryTodo.aiProcessed}',
          );

          if (hiveTodo.aiCategory != memoryTodo.aiCategory ||
              hiveTodo.aiPriority != memoryTodo.aiPriority ||
              hiveTodo.aiProcessed != memoryTodo.aiProcessed) {
            debugPrint('  *** INCONSISTENCY DETECTED ***');
          }
        }
      }

      debugPrint('=== END DEBUG ===');
    } catch (e) {
      debugPrint('Error in debugCheckHivePersistence: $e');
    }
  }

  @override
  void dispose() {
    // Cancel all debounce timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _processingTodos.clear();
    _failedAiRequests.clear();
    _lastRequestTime.clear();

    // Clear repeat todo AI processing state
    _processingRepeatTodos.clear();
    _repeatTodoAILoading.clear();
    _repeatTodoAIStatus.clear();

    super.dispose();
  }
}

enum TodoFilter { all, active, completed }

enum TimeFilter { all, today, yesterday, threeDays, week, month }

enum SortOrder {
  timeAscending,
  timeDescending,
  alphabetical,
  importanceAscending,
  importanceDescending,
}
