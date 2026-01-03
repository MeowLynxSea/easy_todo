import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/ai_settings_model.dart';
import '../models/todo_model.dart';
import '../models/pomodoro_model.dart';
import '../models/statistics_model.dart';
import 'api_request_manager.dart';
import '../l10n/generated/app_localizations.dart';

class AIService {
  final AISettingsModel settings;
  final Dio _dio;
  final ApiRequestManager _requestManager;
  BuildContext? _context;

  AIService(this.settings, {BuildContext? context})
    : _dio = Dio(),
      _requestManager = ApiRequestManager(),
      _context = context {
    // Configure rate limiting based on settings
    ApiRequestManager.setMaxRequestsPerMinute(settings.maxRequestsPerMinute);
  }

  // Method to update context after creation (useful when context is not available during initialization)
  void updateContext(BuildContext context) {
    _context = context;
  }

  // Get localized prompt from l10n framework - prioritize user language over app locale
  String _getPromptForLanguage(String promptType, String languageCode) {
    if (_context == null) {
      // Fallback to English if no context is available
      return _getFallbackPrompt(promptType);
    }

    final l10n = AppLocalizations.of(_context!);
    if (l10n == null) {
      return _getFallbackPrompt(promptType);
    }

    // Handle language code variants (e.g., zh_CN, zh-Hans, etc.)
    String normalizedLanguageCode = languageCode;
    if (languageCode.contains('_')) {
      normalizedLanguageCode = languageCode.split('_')[0];
    } else if (languageCode.contains('-')) {
      normalizedLanguageCode = languageCode.split('-')[0];
    }

    // Try to get localized prompts for the requested language
    // This will work if the localization file contains the requested language
    try {
      String localizedPrompt;
      switch (promptType) {
        case 'categorization':
          localizedPrompt = l10n.aiPromptCategorization(
            '{title}',
            '{description}',
          );
          break;
        case 'priority':
          localizedPrompt = l10n.aiPromptPriority(
            '{deadline}',
            '{description}',
            '{hasDeadline}',
            '{title}',
          );
          break;
        case 'importance':
          localizedPrompt = l10n.aiPromptImportance('{description}', '{title}');
          break;
        case 'motivation':
          localizedPrompt = l10n.aiPromptMotivation(
            '{date}',
            '{description}',
            '{name}',
            '{unit}',
            '{value}',
          );
          break;
        case 'notification':
          localizedPrompt = l10n.aiPromptNotification(
            '{category}',
            '{description}',
            '{priority}',
            '{title}',
          );
          break;
        case 'completion':
          localizedPrompt = l10n.aiPromptCompletion(
            '{completed}',
            '{percentage}',
            '{total}',
          );
          break;
        case 'daily_summary':
          localizedPrompt = l10n.aiPromptDailySummary(
            '{avgPriority}',
            '{categories}',
            '{pendingCount}',
          );
          break;
        case 'pomodoro':
          localizedPrompt = l10n.aiPromptPomodoro(
            '{duration}',
            '{isCompleted}',
            '{sessionType}',
            '{taskTitle}',
          );
          break;
        default:
          return _getFallbackPrompt(promptType);
      }

      return localizedPrompt;
    } catch (e) {
      // If localization fails for the requested language, use fallback
      debugPrint(
        'AIService: ❌ Localization failed for $normalizedLanguageCode, using fallback. Error: $e',
      );
      return _getFallbackPrompt(promptType);
    }
  }

  // Fallback prompts in case l10n is not available
  String _getFallbackPrompt(String promptType) {
    switch (promptType) {
      case 'categorization':
        return '''Categorize this todo task into one of these categories:
        work, study, personal, health, finance, shopping, family, social, hobby, travel, fitness, other.

        Task: "{title}"
        Description: "{description}"

        Respond with only the category name in lowercase.''';
      case 'priority':
        return '''Rate the priority of this todo task from 0-100, considering:
        - Urgency: How soon is it needed? (deadline: {deadline})
        - Impact: What are the consequences of not completing it?
        - Effort: How much time/resources will it require?
        - Personal importance: How valuable is this to you?

        Task: "{title}"
        Description: "{description}"
        Has deadline: {hasDeadline}
        Deadline: {deadline}

        Guidelines:
        - 0-20: Low priority, can be postponed
        - 21-40: Moderate priority, should be done soon
        - 41-70: High priority, important to complete
        - 71-100: Critical priority, urgent completion needed

        Respond with only a number from 0-100.''';
      case 'importance':
        return '''Rate the importance of this todo task from 0-100, focusing on long-term value and impact.

        Consider:
        - Impact: How much does this matter if completed?
        - Long-term value: Will it benefit you later?
        - Alignment: Does it support your goals/values?
        - Consequences: What is lost if it is never done?

        Task: "{title}"
        Description: "{description}"

        Guidelines:
        - 0-20: Low importance
        - 21-40: Some importance
        - 41-70: Important
        - 71-100: Extremely important

        Respond with only a number from 0-100.''';
      case 'motivation':
        return '''Generate a motivational message based on this statistics data:
        Name: "{name}"
        Description: "{description}"
        Value: {value}
        Unit: "{unit}"
        Date: {date}

        Requirements:
        - Make it encouraging and data-specific
        - Keep it under 25 characters
        - Focus on achievement and progress
        - Use positive, action-oriented language
        - Example: "Great progress today! 🎯" or "Keep it up! 💪"
        - Respond with only the message, no explanations''';
      case 'notification':
        return '''Create a personalized notification reminder for this task:
        Task: "{title}"
        Description: "{description}"
        Category: {category}
        Priority: {priority}
        Reminder Time: {reminderTime}

        Requirements:
        - Create both a title and message
        - Title: Must be under 20 characters, attention-grabbing
        - Message: Must be under 50 characters, motivating and actionable
        - Use emojis where appropriate for engagement
        - Include urgency based on priority level
        - Make it personal and encouraging
        - If reminder time is provided, tailor the message for that time (e.g., "Good morning", "Afternoon task")
        - Respond with only the title and message in the specified format, no explanations''';
      case 'completion':
        return '''Generate an encouraging message based on today's todo completion:
        Completed: {completed} out of {total} tasks
        Completion rate: {percentage}%

        Requirements:
        - Make it positive and motivating
        - Keep it under 25 characters
        - Celebrate achievement and progress
        - Use encouraging language and/or emojis
        - Example: "Awesome work! 🌟" or "Progress! 👍"
        - Respond with only the message, no explanations''';
      case 'daily_summary':
        return '''Create a daily summary notification for pending todos.

        Pending tasks count: {pendingCount}
        Categories: {categories}
        Average priority: {avgPriority}/100

        Create a personalized summary with:
        1. A catchy title (first line)
        2. An encouraging message that MUST include the count of unfinished todos ({pendingCount})
        3. Keep the message content under 50 characters. Make it motivating and actionable.
        4. Respond with only the title and message, no explanations''';
      case 'pomodoro':
        return '''Create a personalized notification for a completed {sessionType} session.

        Session details:
        - Task: "{taskTitle}"
        - Session type: {sessionType}
        - Duration: {duration} minutes
        - Completed: {isCompleted}

        IMPORTANT: Respond in the same language as this prompt (English).

        Create both a title and message:
        1. Title: Must be under 20 characters, attention-grabbing and celebratory
        2. Message: Must be under 50 characters, encouraging and relevant to the session completion
        3. For focus sessions (work completed): Emphasize work accomplishment and that it's time for a well-deserved break
        4. For break sessions (rest completed): Focus on rest completion and that it's time to get back to focused work
        5. Use emojis where appropriate for engagement
        6. Make it personal and motivating
        7. Respond with only the title and message in the specified format, no explanations

        Format your response as:
        TITLE: [title]
        MESSAGE: [message]''';
      default:
        return '';
    }
  }

  Future<String?> callAI(String prompt, String languageCode) async {
    if (!settings.isValid) {
      return null;
    }

    try {
      return await _requestManager.makeAiRequest(
        prompt,
        settings.modelName,
        () async {
          final response = await _makeApiRequest(prompt);

          if (response.statusCode == 200) {
            final data = response.data;
            final content = _extractContentFromResponse(data);
            return content;
          } else {
            debugPrint(
              'AIService: API Error - Status: ${response.statusCode}, Body: ${response.data}',
            );
            throw Exception('API Error: ${response.statusCode}');
          }
        },
        timeout: Duration(
          milliseconds: settings.requestTimeout + 10000,
        ), // Add buffer
      );
    } on DioException catch (e) {
      debugPrint('AIService: API Error (${e.type}): ${e.message}');
      if (e.type == DioExceptionType.connectionError) {
        debugPrint(
          'AIService: Connection error - check if AI service is running',
        );
      } else if (e.type == DioExceptionType.connectionTimeout) {
        debugPrint(
          'AIService: Request timeout - consider increasing timeout value',
        );
      } else if (e.response?.statusCode == 429) {
        debugPrint('AIService: Rate limited - too many requests');
      } else if (e.response?.statusCode == 401) {
        debugPrint('AIService: Authentication failed - check API key');
      }
      return null;
    } catch (e) {
      debugPrint('AIService: Unexpected API error: $e');
      return null;
    }
  }

  Future<Response> _makeApiRequest(String prompt) async {
    if (settings.apiFormat == 'ollama') {
      return await _dio.post(
        settings.apiEndpoint,
        data: {
          'model': settings.modelName,
          'prompt': prompt,
          'stream': false,
          'options': {
            'temperature': settings.temperature,
            'num_predict': settings.maxTokens,
          },
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: Duration(milliseconds: settings.requestTimeout),
          sendTimeout: Duration(milliseconds: settings.requestTimeout),
        ),
      );
    } else {
      // OpenAI format (default)
      return await _dio.post(
        settings.apiEndpoint,
        data: {
          'model': settings.modelName,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': settings.temperature,
          'max_tokens': settings.maxTokens,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${settings.apiKey}',
          },
          receiveTimeout: Duration(milliseconds: settings.requestTimeout),
          sendTimeout: Duration(milliseconds: settings.requestTimeout),
        ),
      );
    }
  }

  String? _extractContentFromResponse(Map<String, dynamic> data) {
    if (settings.apiFormat == 'ollama') {
      return data['response']?.toString().trim();
    } else {
      // OpenAI format
      return data['choices']?[0]?['message']?['content']?.toString().trim();
    }
  }

  // Task categorization
  Future<String?> categorizeTask(TodoModel todo, String languageCode) async {
    if (!settings.enableAutoCategorization) return null;

    try {
      final prompt = _getPromptForLanguage('categorization', languageCode)
          .replaceAll('{title}', todo.title)
          .replaceAll('{description}', todo.description ?? '');
      return await callAI(prompt, languageCode);
    } catch (e) {
      debugPrint('Error in categorizeTask: $e');
      rethrow;
    }
  }

  // Task priority assessment
  Future<int?> assessPriority(TodoModel todo, String languageCode) async {
    if (!settings.enablePrioritySorting) return null;

    try {
      final hasDeadline = todo.reminderTime != null;
      final deadline = todo.reminderTime?.toIso8601String() ?? 'none';

      final prompt = _getPromptForLanguage('priority', languageCode)
          .replaceAll('{title}', todo.title)
          .replaceAll('{description}', todo.description ?? '')
          .replaceAll('{hasDeadline}', hasDeadline.toString())
          .replaceAll('{deadline}', deadline);

      final result = await callAI(prompt, languageCode);
      if (result != null) {
        try {
          return int.parse(result);
        } catch (e) {
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error in assessPriority: $e');
      rethrow;
    }
  }

  // Task importance assessment
  Future<int?> assessImportance(TodoModel todo, String languageCode) async {
    if (!settings.enableImportanceRating) return null;

    try {
      final prompt = _getPromptForLanguage('importance', languageCode)
          .replaceAll('{title}', todo.title)
          .replaceAll('{description}', todo.description ?? '');

      final result = await callAI(prompt, languageCode);
      if (result != null) {
        try {
          return int.parse(result);
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error in assessImportance: $e');
      rethrow;
    }
  }

  // Motivational message for statistics
  Future<String?> generateMotivationalMessage(
    StatisticsModel statistics,
    String languageCode,
  ) async {
    if (!settings.enableMotivationalMessages) return null;

    String basePrompt = _getPromptForLanguage('motivation', languageCode)
        .replaceAll('{name}', 'Daily Progress')
        .replaceAll(
          '{description}',
          'Task completion rate: ${statistics.completionRate.toStringAsFixed(1)}%',
        )
        .replaceAll('{value}', statistics.completionRate.toString())
        .replaceAll('{unit}', '%')
        .replaceAll('{date}', statistics.date.toIso8601String());

    // Apply custom persona if provided
    if (settings.customPersonaPrompt.isNotEmpty) {
      basePrompt = '${settings.customPersonaPrompt}\n\n$basePrompt';
    }

    return await callAI(basePrompt, languageCode);
  }

  // Smart notification content
  Future<String?> generateSmartNotification(
    TodoModel todo,
    String languageCode,
  ) async {
    if (!settings.enableSmartNotifications) return null;

    String basePrompt = _getPromptForLanguage('notification', languageCode)
        .replaceAll('{title}', todo.title)
        .replaceAll('{description}', todo.description ?? '')
        .replaceAll('{category}', todo.aiCategory ?? 'general')
        .replaceAll('{priority}', todo.aiPriority.toString())
        .replaceAll(
          '{reminderTime}',
          todo.reminderTime != null
              ? '${todo.reminderTime!.hour}:${todo.reminderTime!.minute.toString().padLeft(2, '0')}'
              : 'no specific time',
        );

    // Apply custom persona if provided
    if (settings.customPersonaPrompt.isNotEmpty) {
      basePrompt = '${settings.customPersonaPrompt}\n\n$basePrompt';
    }

    return await callAI(basePrompt, languageCode);
  }

  // Daily summary notification content
  Future<String?> generateDailySummary(
    List<TodoModel> todos,
    String languageCode,
  ) async {
    if (!settings.enableSmartNotifications) return null;

    // Create summary prompt using multi-language prompts
    final categories = todos
        .map((todo) => todo.aiCategory ?? 'general')
        .toSet()
        .join(', ');
    final totalPriority = todos.fold(0, (sum, todo) => sum + todo.aiPriority);
    final avgPriority = todos.isNotEmpty
        ? (totalPriority / todos.length).round()
        : 50;

    String basePrompt = _getPromptForLanguage('daily_summary', languageCode)
        .replaceAll('{pendingCount}', todos.length.toString())
        .replaceAll('{categories}', categories)
        .replaceAll('{avgPriority}', avgPriority.toString());

    // Apply custom persona if provided
    if (settings.customPersonaPrompt.isNotEmpty) {
      basePrompt = '${settings.customPersonaPrompt}\n\n$basePrompt';
    }

    return await callAI(basePrompt, languageCode);
  }

  // Pomodoro notification content
  Future<String?> generatePomodoroNotification(
    PomodoroModel session,
    String languageCode,
  ) async {
    if (!settings.enableSmartNotifications) return null;

    // Get the todo title if possible
    final taskTitle = "Focus session"; // Default title if todo is not available

    final sessionType = session.isBreak ? 'break' : 'focus';
    final duration = session.duration ~/ 60; // Convert seconds to minutes
    final isCompleted = session.isCompleted.toString();

    String basePrompt = _getPromptForLanguage('pomodoro', languageCode)
        .replaceAll('{taskTitle}', taskTitle)
        .replaceAll('{sessionType}', sessionType)
        .replaceAll('{duration}', duration.toString())
        .replaceAll('{isCompleted}', isCompleted);

    // Apply custom persona if provided
    if (settings.customPersonaPrompt.isNotEmpty) {
      basePrompt = '${settings.customPersonaPrompt}\n\n$basePrompt';
    }

    return await callAI(basePrompt, languageCode);
  }

  // Prepare pomodoro notification content in advance
  Future<String?> preparePomodoroNotification(
    PomodoroModel session,
    String languageCode,
    String? todoTitle,
  ) async {
    if (!settings.enableSmartNotifications) {
      return null;
    }

    // Use provided todo title or default
    final taskTitle = todoTitle ?? "Focus session";

    final sessionType = session.isBreak ? 'break' : 'focus';
    final duration = session.duration ~/ 60; // Convert seconds to minutes
    final isCompleted =
        "true"; // Will be completed when this notification is sent

    String basePrompt = _getPromptForLanguage('pomodoro', languageCode)
        .replaceAll('{taskTitle}', taskTitle)
        .replaceAll('{sessionType}', sessionType)
        .replaceAll('{duration}', duration.toString())
        .replaceAll('{isCompleted}', isCompleted);

    // Apply custom persona if provided
    if (settings.customPersonaPrompt.isNotEmpty) {
      basePrompt = '${settings.customPersonaPrompt}\n\n$basePrompt';
    }

    final result = await callAI(basePrompt, languageCode);
    return result;
  }

  // Incentive message for daily progress
  Future<String?> generateIncentiveMessage(
    int completed,
    int total,
    String languageCode,
  ) async {
    if (!settings.enableAIFeatures) return null;

    final percentage = total > 0 ? ((completed / total) * 100).round() : 0;

    String basePrompt = _getPromptForLanguage('completion', languageCode)
        .replaceAll('{completed}', completed.toString())
        .replaceAll('{total}', total.toString())
        .replaceAll('{percentage}', percentage.toString());

    // Apply custom persona if provided
    if (settings.customPersonaPrompt.isNotEmpty) {
      basePrompt = '${settings.customPersonaPrompt}\n\n$basePrompt';
    }

    return await callAI(basePrompt, languageCode);
  }

  // Batch process tasks for categorization, priority, and importance
  Future<Map<String, dynamic>> processTasksBatch(
    List<TodoModel> tasks,
    String languageCode,
  ) async {
    final results = <String, dynamic>{};

    try {
      for (int i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        if (!task.aiProcessed) {
          try {
            // Remove manual delays - let the request manager handle rate limiting
            // Process with retry mechanism (but with shorter delays since request manager handles rate limiting)
            final category = await _retryWithDelay(
              () => categorizeTask(task, languageCode),
              maxRetries:
                  2, // Reduced retries since request manager handles rate limiting
              initialDelayMs: 1000, // Reduced initial delay
            );

            // Small delay between category and priority requests to avoid conflicts
            await Future.delayed(const Duration(milliseconds: 500));

            final priority = await _retryWithDelay(
              () => assessPriority(task, languageCode),
              maxRetries: 2, // Reduced retries
              initialDelayMs: 1000, // Reduced initial delay
            );

            await Future.delayed(const Duration(milliseconds: 500));

            final importance = await _retryWithDelay(
              () => assessImportance(task, languageCode),
              maxRetries: 2,
              initialDelayMs: 1000,
            );

            results[task.id] = {
              'category': category,
              'priority': priority,
              'importance': importance,
            };
          } catch (e) {
            // Continue with next task
          }
        }
      }
    } catch (e) {
      debugPrint('Error in processTasksBatch loop: $e');
      rethrow;
    }

    return results;
  }

  // Retry mechanism with exponential backoff
  Future<T?> _retryWithDelay<T>(
    Future<T?> Function() operation, {
    int maxRetries = 3,
    int initialDelayMs = 1000,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries) {
          return null; // Return null instead of throwing to allow batch processing to continue
        }

        // Check if it's a rate limit error (429)
        if (e.toString().contains('429') ||
            e.toString().contains('Too Many Requests')) {
          final delay =
              initialDelayMs * (1 << (attempt - 1)); // Exponential backoff
          await Future.delayed(Duration(milliseconds: delay));
        } else {
          // For other errors, wait a shorter time
          final delay = initialDelayMs ~/ 2;
          await Future.delayed(Duration(milliseconds: delay));
        }
      }
    }
    return null;
  }

  // Public method for testing connection - optimized for speed
  Future<String?> testConnection(String languageCode) async {
    try {
      // Simple connectivity test with minimal data and shorter timeout
      final response = await _makeTestRequest();

      if (response.statusCode == 200) {
        final data = response.data;
        final content = _extractContentFromResponse(data);
        return content;
      } else {
        debugPrint(
          'AIService: Test failed with status: ${response.statusCode}',
        );
        return null;
      }
    } on DioException catch (e) {
      debugPrint('AIService: Connection test error: ${e.type} - ${e.message}');
      if (e.type == DioExceptionType.connectionError) {
        debugPrint(
          'AIService: Connection refused - check if Ollama is running on the correct port',
        );
      } else if (e.type == DioExceptionType.connectionTimeout) {
        debugPrint(
          'AIService: Connection timeout - server may be slow or unreachable',
        );
      }
      return null;
    } catch (e) {
      debugPrint('AIService: Unexpected connection test error: $e');
      return null;
    }
  }

  Future<Response> _makeTestRequest() async {
    if (settings.apiFormat == 'ollama') {
      return await _dio.post(
        settings.apiEndpoint,
        data: {
          'model': settings.modelName,
          'prompt': 'OK',
          'stream': false,
          'options': {'temperature': 0.0, 'num_predict': 5},
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
    } else {
      // OpenAI format (default)
      return await _dio.post(
        settings.apiEndpoint,
        data: {
          'model': settings.modelName,
          'messages': [
            {'role': 'user', 'content': 'OK'},
          ],
          'max_tokens': 5, // Minimal response
          'temperature': 0.0, // Deterministic
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${settings.apiKey}',
          },
          receiveTimeout: const Duration(
            seconds: 10,
          ), // Shorter timeout for testing
          sendTimeout: const Duration(seconds: 10),
        ),
      );
    }
  }

  Map<String, dynamic> getRequestManagerStats() {
    return _requestManager.getStats();
  }

  List<Map<String, dynamic>> getRequestQueueInfo() {
    return _requestManager.getRequestQueueInfo();
  }

  List<Map<String, dynamic>> getRecentRequests() {
    return _requestManager.getRecentRequests();
  }

  void dispose() {
    _dio.close();
    _requestManager.dispose();
  }
}
