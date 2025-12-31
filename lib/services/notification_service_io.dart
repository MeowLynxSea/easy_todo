import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/services/timezone_service.dart';
import 'package:easy_todo/models/pomodoro_model.dart';
import 'package:easy_todo/models/notification_settings_model.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/sync_write_service.dart';
import 'package:easy_todo/services/repositories/user_preferences_repository.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_todo/providers/ai_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isPluginInitialized = false;

  AIProvider? _aiProvider;
  BuildContext? _context;

  void setAIProvider(AIProvider? provider) {
    _aiProvider = provider;
  }

  void setContext(BuildContext context) {
    _context = context;
    if (_aiProvider != null) {
      _aiProvider!.updateAIServiceContext(context);
    }
  }

  // Static method to get the instance (for convenience)
  static NotificationService get instance => _instance;

  int _getNotificationId(String todoId) {
    // Convert large todo ID to a valid 32-bit integer for notifications
    final hash = todoId.hashCode;
    // Ensure positive value within 32-bit range
    final notificationId = hash.abs() % 2147483647;
    return notificationId;
  }

  Future<String> _getCurrentLanguageCode() async {
    try {
      final prefs = _hiveService.userPreferencesBox.get(
        UserPreferencesRepository.hiveKey,
      );
      final languageCode = prefs?.languageCode ?? '';
      if (languageCode.isNotEmpty) return languageCode;
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('app_language') ?? '';
      if (languageCode.isNotEmpty) return languageCode;
    } catch (_) {}

    return 'zh';
  }

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final HiveService _hiveService = HiveService();
  NotificationSettingsModel? _settings;

  // Timer-based notification system
  final Map<String, Timer> _activeTimers = {};
  Timer? _dailySummaryTimer;

  // Daily summary state management
  DateTime? _lastDailySummaryDate;
  bool _isDailySummaryProcessing = false;
  static const String _lastSummaryKey = 'last_daily_summary_date';

  // Todo reminder state management to prevent duplicates within same minute
  final Map<String, DateTime> _lastTodoReminderSent = {};
  final Map<String, bool> _isTodoReminderProcessing = {};

  Future<void> initialize() async {
    await _initializeTimeZone();
    if (defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint('Notifications are not supported on Windows, skipping init');
      _isPluginInitialized = false;
    } else {
      try {
        await _initializeNotifications();
        _isPluginInitialized = true;
      } catch (e) {
        debugPrint('Notification plugin initialization failed: $e');
        _isPluginInitialized = false;
      }
    }
    await _loadSettings();
    _debugTimeZoneInfo();
  }

  Future<bool> hasNotificationPermission() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final androidPlugin = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        return await androidPlugin.areNotificationsEnabled() ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final androidPlugin = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        return await androidPlugin.requestNotificationsPermission() ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  // Public methods for safe initialization from background contexts
  Future<void> initializeTimeZone() async => _initializeTimeZone();
  Future<void> initializeNotifications() async => _initializeNotifications();
  Future<void> loadSettings() async => _loadSettings();

  void _debugTimeZoneInfo() {
    // Timezone debugging removed for production
  }

  Future<void> _initializeTimeZone() async {
    try {
      final timezoneService = TimezoneService();
      await timezoneService.initialize();

      // Detect and set the correct timezone
      final detectedTimezone = timezoneService.detectTimezone();
      await timezoneService.setCustomTimezone(detectedTimezone);
    } catch (e) {
      debugPrint(
        'Failed to initialize enhanced timezone service in notification service: $e',
      );
      // Fallback to basic timezone initialization - use system local timezone
      try {
        tz.initializeTimeZones();
        final String timeZoneName = DateTime.now().timeZoneName;
        // Try to find a matching timezone, otherwise use UTC
        try {
          final location = tz.getLocation(timeZoneName);
          tz.setLocalLocation(location);
        } catch (locationError) {
          debugPrint(
            'Could not find timezone $timeZoneName, using UTC: $locationError',
          );
          tz.setLocalLocation(tz.UTC);
        }
      } catch (fallbackError) {
        debugPrint(
          'Fallback timezone initialization also failed: $fallbackError',
        );
      }
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const LinuxInitializationSettings linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _requestPermissions();
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        // Create todo reminder channel
        const AndroidNotificationChannel todoChannel =
            AndroidNotificationChannel(
              'todo_reminder',
              'Todo Reminders',
              description: 'Notifications for individual todo reminders',
              importance: Importance.high,
              enableVibration: true,
              enableLights: true,
              showBadge: true,
            );

        await androidPlugin.createNotificationChannel(todoChannel);

        // Create daily summary channel
        const AndroidNotificationChannel summaryChannel =
            AndroidNotificationChannel(
              'daily_summary',
              'Daily Summary',
              description: 'Daily summary of pending todos',
              importance: Importance.defaultImportance,
              enableVibration: true,
              enableLights: true,
              showBadge: true,
            );

        await androidPlugin.createNotificationChannel(summaryChannel);

        // Create test notification channel
        const AndroidNotificationChannel testChannel =
            AndroidNotificationChannel(
              'test_channel',
              'Test Notifications',
              description: 'Test notification channel',
              importance: Importance.high,
              enableVibration: true,
              enableLights: true,
              showBadge: true,
            );

        await androidPlugin.createNotificationChannel(testChannel);

        // Create pomodoro notification channel
        const AndroidNotificationChannel pomodoroChannel =
            AndroidNotificationChannel(
              'pomodoro_complete',
              'Pomodoro Complete',
              description: 'Notifications when pomodoro sessions are completed',
              importance: Importance.high,
              enableVibration: true,
              enableLights: true,
              showBadge: true,
            );

        await androidPlugin.createNotificationChannel(pomodoroChannel);
      }
    } catch (e) {
      debugPrint('Error creating notification channels: $e');
    }
  }

  Future<void> _requestPermissions() async {
    // Permission requests are now handled by PermissionService.initializePermissions()
    // This method is called from main.dart with a valid BuildContext
    // We don't need to request permissions here to avoid background context issues
  }

  Future<void> _loadSettings() async {
    try {
      // Ensure Hive is initialized before accessing boxes
      if (!Hive.isBoxOpen('notificationSettings')) {
        await Hive.initFlutter();
        await HiveService.init();
      }

      Box<NotificationSettingsModel> settingsBox;
      try {
        settingsBox = _hiveService.notificationSettingsBox;
      } catch (e) {
        // Try to open the box directly
        settingsBox = await Hive.openBox<NotificationSettingsModel>(
          'notificationSettings',
        );
      }

      final settings = settingsBox.get('notificationSettings');

      if (settings != null) {
        _settings = settings;
      } else {
        _settings = NotificationSettingsModel.create();
        await settingsBox.put('notificationSettings', _settings!);
      }

      // Load last daily summary date
      await _loadLastDailySummaryDate();

      // Only schedule if not already scheduled today
      if (_shouldScheduleDailySummary()) {
        await _scheduleDailySummary();
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      _settings = NotificationSettingsModel.create();
    }
  }

  Future<void> updateSettings(NotificationSettingsModel settings) async {
    final oldSettings = _settings;
    _settings = settings;
    try {
      // Ensure Hive is initialized before accessing boxes
      if (!Hive.isBoxOpen('notificationSettings')) {
        await Hive.initFlutter();
        await HiveService.init();
      }

      Box<NotificationSettingsModel> settingsBox;
      try {
        settingsBox = _hiveService.notificationSettingsBox;
      } catch (e) {
        debugPrint(
          'Notification settings box not available for update, attempting to open it: $e',
        );
        // Try to open the box directly
        settingsBox = await Hive.openBox<NotificationSettingsModel>(
          'notificationSettings',
        );
      }

      await settingsBox.put('notificationSettings', settings);

      if (settings.notificationsEnabled == false) {
        for (final timer in _activeTimers.values) {
          timer.cancel();
        }
        _activeTimers.clear();
        await _cancelDailySummary();
        resetTodoReminderStates();
        try {
          await _notificationsPlugin.cancelAll();
        } catch (_) {}
      }

      // Only reschedule if settings actually changed
      final enabledChanged =
          oldSettings?.dailySummaryEnabled != settings.dailySummaryEnabled;
      final timeChanged =
          oldSettings?.dailySummaryTime != settings.dailySummaryTime;

      // If time was changed and daily summary is enabled, clear the "今日已发送" record
      if (settings.dailySummaryEnabled && timeChanged) {
        debugPrint(
          'Daily summary time changed, clearing last sent date record',
        );
        await _clearLastDailySummaryDate();
      }

      if (settings.dailySummaryEnabled && (enabledChanged || timeChanged)) {
        if (_shouldScheduleDailySummary()) {
          await _scheduleDailySummary();
        }
      } else if (!settings.dailySummaryEnabled) {
        await _cancelDailySummary();
      }
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
    }
  }

  Future<void> scheduleTodoReminder(TodoModel todo) async {
    if (_settings?.notificationsEnabled == false) return;
    if (!todo.reminderEnabled || todo.reminderTime == null) return;

    try {
      // 统一使用系统时间，避免时区混乱
      final scheduledTime = todo.reminderTime!;
      final now = DateTime.now();

      // 检查小时和分钟是否相等，相等则立即发送通知
      if (scheduledTime.hour == now.hour &&
          scheduledTime.minute == now.minute) {
        // Check if we should send the reminder now (prevent duplicates within same minute)
        if (_shouldSendTodoReminderNow(todo)) {
          await sendTodoReminderNotification(todo);
        }
        return;
      }

      // Cancel existing timer
      _activeTimers[todo.id]?.cancel();

      final delay = scheduledTime.difference(now);

      // 使用Flutter Local Notifications的zonedSchedule作为主要方法
      try {
        await _scheduleWithFlutterNotifications(todo, scheduledTime);
      } catch (e) {
        debugPrint('Error scheduling with Flutter Local Notifications: $e');

        // 最后降级到Timer，只有未来时间才使用Timer
        if (delay.isNegative) {
          debugPrint('Cannot schedule Timer for past time, skipping');
        } else {
          _activeTimers[todo.id] = Timer(delay, () async {
            await sendTodoReminderNotification(todo);
          });
        }
      }
    } catch (e) {
      debugPrint('Error scheduling todo reminder: $e');
    }
  }

  Future<void> _scheduleWithFlutterNotifications(
    TodoModel todo,
    DateTime scheduledTime,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'todo_reminder',
          'Todo Reminders',
          channelDescription: 'Notifications for individual todo reminders',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
      defaultActionName: 'Open notification',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
      linux: linuxDetails,
    );

    final now = DateTime.now();
    final delay = scheduledTime.difference(now);
    Duration? correctedDelay;

    // 如果是重复任务且时间已过，计算到下一个周期的延迟
    if (delay.isNegative && todo.isGeneratedFromRepeat) {
      // 对于每日重复，计算到明天同一时间的时间
      final nextScheduledTime = scheduledTime.add(const Duration(days: 1));
      correctedDelay = nextScheduledTime.difference(now);

      debugPrint(
        'Rescheduling repeating task: ${todo.title} from $scheduledTime to $nextScheduledTime',
      );

      _activeTimers[todo.id] = Timer(correctedDelay, () async {
        await sendTodoReminderNotification(todo);
      });
    } else if (delay.isNegative) {
      // 普通任务的过期时间，跳过
      debugPrint(
        'Skipping past non-repeating reminder: ${todo.title} at $scheduledTime',
      );
    } else {
      // 未来时间的正常处理
      _activeTimers[todo.id] = Timer(delay, () async {
        await sendTodoReminderNotification(todo);
      });
    }

    // 只有在未来时间才尝试使用zonedSchedule
    final actualDelay = delay.isNegative && todo.isGeneratedFromRepeat
        ? correctedDelay!
        : delay;
    if (actualDelay.isNegative) {
      debugPrint('Skipping zonedSchedule for past time, relying on Timer only');
    } else {
      try {
        await _notificationsPlugin.zonedSchedule(
          _getNotificationId(todo.id) + 1000000, // 使用不同的ID避免冲突
          'Todo Reminder (Scheduled)',
          todo.title,
          tz.TZDateTime.now(tz.local).add(actualDelay),
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('zonedSchedule backup failed (but Timer should work): $e');
      }
    }
  }

  // Android Alarm Manager removed - using Timer instead

  Future<void> sendTestNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notification channel',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
        defaultActionName: 'Open notification',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
        linux: linuxDetails,
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch % 2147483647,
        title,
        body,
        platformDetails,
        payload: 'test_notification',
      );

      // Test notification sent successfully
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  Future<void> sendTodoReminderNotification(TodoModel todo) async {
    // Mark as processing to prevent duplicates
    _isTodoReminderProcessing[todo.id] = true;

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'todo_reminder',
            'Todo Reminders',
            channelDescription: 'Notifications for individual todo reminders',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
        defaultActionName: 'Open notification',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
        linux: linuxDetails,
      );

      // Try to get AI-generated content if smart notifications are enabled
      String title = 'Todo Reminder';
      String body = todo.title;

      try {
        if (_aiProvider?.settings.enableSmartNotifications == true &&
            _aiProvider?.settings.isValid == true) {
          final languageCode = await _getCurrentLanguageCode();
          final aiMessage = await _aiProvider?.generateSmartNotification(
            todo,
            languageCode: languageCode,
            context: _context,
          );
          if (aiMessage != null && aiMessage.isNotEmpty) {
            // Parse the AI response to extract title and message
            // Try multiple formats that AI might return
            String? parsedTitle;
            String? parsedBody;

            // Format 1: TITLE: [title] MESSAGE: [message]
            var titleMatch = RegExp(
              r'TITLE:\s*(.+?)(?:\n|$|\s*MESSAGE:)',
              caseSensitive: false,
            ).firstMatch(aiMessage);
            var messageMatch = RegExp(
              r'MESSAGE:\s*(.+?)(?:\n|$)',
              caseSensitive: false,
            ).firstMatch(aiMessage);

            if (titleMatch != null && messageMatch != null) {
              parsedTitle = titleMatch.group(1)!.trim();
              parsedBody = messageMatch.group(1)!.trim();
            } else {
              // Format 2: **Title:** [title] **Message:** [message] (Markdown format)
              titleMatch = RegExp(
                r'\*\*Title:\*\*\s*(.+?)(?:\n|$|\*\*Message:\*\*)',
                caseSensitive: false,
              ).firstMatch(aiMessage);
              messageMatch = RegExp(
                r'\*\*Message:\*\*\s*(.+?)(?:\n|$)',
                caseSensitive: false,
              ).firstMatch(aiMessage);

              if (titleMatch != null && messageMatch != null) {
                parsedTitle = titleMatch.group(1)!.trim();
                parsedBody = messageMatch.group(1)!.trim();
              } else {
                // Format 3: First line is title, rest is message
                final lines = aiMessage.split('\n');
                if (lines.length >= 2) {
                  parsedTitle = lines[0].trim();
                  parsedBody = lines.sublist(1).join('\n').trim();

                  // Clean up common prefixes from title
                  parsedTitle = parsedTitle
                      .replaceAll(
                        RegExp(
                          r'^(Title:|🤖|Smart Reminder|AI Reminder)\s*',
                          caseSensitive: false,
                        ),
                        '',
                      )
                      .trim();

                  // Clean up common prefixes from message
                  parsedBody = parsedBody
                      .replaceAll(
                        RegExp(
                          r'^(Message:|Body:|Content:)\s*',
                          caseSensitive: false,
                        ),
                        '',
                      )
                      .trim();
                }
              }
            }

            // Use parsed values if successful, otherwise fallback
            if (parsedTitle != null &&
                parsedBody != null &&
                parsedTitle.isNotEmpty &&
                parsedBody.isNotEmpty) {
              title = parsedTitle;
              body = parsedBody;
            } else {
              // Last resort: try to extract any meaningful content
              final cleanMessage = aiMessage
                  .replaceAll(
                    RegExp(
                      r'\*\*?(Title|Message|Content):?\*\*?\s*',
                      caseSensitive: false,
                    ),
                    '',
                  )
                  .trim();
              if (cleanMessage.isNotEmpty) {
                // If it's a long message, split it reasonably
                if (cleanMessage.length > 100) {
                  final firstLineBreak = cleanMessage.indexOf('\n');
                  if (firstLineBreak > 10 && firstLineBreak < 50) {
                    title = cleanMessage.substring(0, firstLineBreak).trim();
                    body = cleanMessage.substring(firstLineBreak + 1).trim();
                  } else {
                    title = '🤖 Smart Reminder';
                    body = cleanMessage.length > 100
                        ? '${cleanMessage.substring(0, 97)}...'
                        : cleanMessage;
                  }
                } else {
                  title = '🤖 Smart Reminder';
                  body = cleanMessage;
                }
              } else {
                // Ultimate fallback
                title = '🤖 Smart Reminder';
                body = aiMessage.length > 100
                    ? '${aiMessage.substring(0, 97)}...'
                    : aiMessage;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error generating AI notification content: $e');
        // Fall back to default content
      }

      final notificationId = _getNotificationId(todo.id);
      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: 'todo_${todo.id}',
      );

      // Mark as successfully sent and remove from active timers
      _markTodoReminderSent(todo.id);
      _activeTimers.remove(todo.id);

      debugPrint('Todo reminder notification sent successfully for ${todo.id}');
    } catch (e) {
      debugPrint('Error sending todo reminder notification: $e');
      // Clear processing state on error
      _isTodoReminderProcessing[todo.id] = false;
    }
  }

  Future<void> cancelTodoReminder(String todoId) async {
    try {
      final notificationId = _getNotificationId(todoId);

      // Cancel the timer
      _activeTimers[todoId]?.cancel();
      _activeTimers.remove(todoId);

      // Cancel any pending notification
      await _notificationsPlugin.cancel(notificationId);

      // Clear the todo reminder state
      _clearTodoReminderState(todoId);

      debugPrint('Todo reminder cancelled and state cleared for $todoId');
    } catch (e) {
      debugPrint('Error canceling todo reminder: $e');
    }
  }

  /// Cancel all scheduled todo reminders and clear in-memory reminder state.
  ///
  /// This is used by "Clear All Data" to ensure no stale notifications remain
  /// after deleting todos.
  Future<void> cancelAllTodoReminders() async {
    try {
      _clearAllTimers();
      await _cancelDailySummary();
      try {
        await _notificationsPlugin.cancelAll();
      } catch (_) {}
      debugPrint('All todo reminders cancelled');
    } catch (e) {
      debugPrint('Error canceling all todo reminders: $e');
    }
  }

  Future<void> _scheduleDailySummary() async {
    if (_settings?.notificationsEnabled == false) return;
    if (_settings?.dailySummaryEnabled == false) return;
    if (_isDailySummaryProcessing) {
      debugPrint(
        'Daily summary already processing, skipping duplicate schedule',
      );
      return;
    }

    try {
      // Cancel existing daily summary timer
      await _cancelDailySummary();

      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        _settings!.dailySummaryTime.hour,
        _settings!.dailySummaryTime.minute,
      );

      // If the time has passed today, schedule for tomorrow
      DateTime nextRun = scheduledTime.isAfter(now)
          ? scheduledTime
          : scheduledTime.add(const Duration(days: 1));

      // Calculate initial delay
      final initialDelay = nextRun.difference(now);

      // Create a timer that runs daily at the specified time
      _dailySummaryTimer = Timer(initialDelay, () async {
        await _sendDailySummaryNotification();
        // Set up periodic timer for daily execution
        _dailySummaryTimer = Timer.periodic(const Duration(days: 1), (
          timer,
        ) async {
          await _sendDailySummaryNotification();
        });
      });

      debugPrint(
        'Daily summary scheduled for: $nextRun (delay: $initialDelay)',
      );
    } catch (e) {
      debugPrint('Error scheduling daily summary: $e');
    }
  }

  Future<void> _cancelDailySummary() async {
    try {
      _dailySummaryTimer?.cancel();
      _dailySummaryTimer = null;
      await _notificationsPlugin.cancel(999999);
    } catch (e) {
      debugPrint('Error canceling daily summary: $e');
    }
  }

  // State management helper methods
  Future<void> _loadLastDailySummaryDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSummaryString = prefs.getString(_lastSummaryKey);
      if (lastSummaryString != null) {
        _lastDailySummaryDate = DateTime.parse(lastSummaryString);
        debugPrint('Loaded last daily summary date: $_lastDailySummaryDate');
      }
    } catch (e) {
      debugPrint('Error loading last daily summary date: $e');
    }
  }

  Future<void> _saveLastDailySummaryDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSummaryKey, date.toIso8601String());
      _lastDailySummaryDate = date;
      debugPrint('Saved last daily summary date: $date');
    } catch (e) {
      debugPrint('Error saving last daily summary date: $e');
    }
  }

  Future<void> _clearLastDailySummaryDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSummaryKey);
      _lastDailySummaryDate = null;
      debugPrint('Cleared last daily summary date record');
    } catch (e) {
      debugPrint('Error clearing last daily summary date: $e');
    }
  }

  bool _shouldScheduleDailySummary() {
    if (_settings?.dailySummaryEnabled != true) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if we already sent daily summary today
    if (_lastDailySummaryDate != null) {
      final lastSummary = DateTime(
        _lastDailySummaryDate!.year,
        _lastDailySummaryDate!.month,
        _lastDailySummaryDate!.day,
      );
      if (lastSummary.isAtSameMomentAs(today)) {
        debugPrint('Daily summary already sent today, skipping schedule');
        return false;
      }
    }

    return true;
  }

  bool _shouldSendDailySummaryNow() {
    if (_isDailySummaryProcessing) {
      debugPrint('Daily summary already processing, skipping duplicate send');
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if we already sent daily summary today
    if (_lastDailySummaryDate != null) {
      final lastSummary = DateTime(
        _lastDailySummaryDate!.year,
        _lastDailySummaryDate!.month,
        _lastDailySummaryDate!.day,
      );
      if (lastSummary.isAtSameMomentAs(today)) {
        debugPrint('Daily summary already sent today, skipping send');
        return false;
      }
    }

    return true;
  }

  // Todo reminder state management methods (similar to daily summary)
  bool _shouldSendTodoReminderNow(TodoModel todo) {
    if (_isTodoReminderProcessing[todo.id] == true) {
      debugPrint(
        'Todo reminder already processing for ${todo.id}, skipping duplicate send',
      );
      return false;
    }

    final now = DateTime.now();
    final currentMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );

    // Check if we already sent a reminder for this todo in the current minute
    if (_lastTodoReminderSent[todo.id] != null) {
      final lastSent = DateTime(
        _lastTodoReminderSent[todo.id]!.year,
        _lastTodoReminderSent[todo.id]!.month,
        _lastTodoReminderSent[todo.id]!.day,
        _lastTodoReminderSent[todo.id]!.hour,
        _lastTodoReminderSent[todo.id]!.minute,
      );
      if (lastSent.isAtSameMomentAs(currentMinute)) {
        debugPrint(
          'Todo reminder already sent this minute for ${todo.id}, skipping duplicate send',
        );
        return false;
      }
    }

    return true;
  }

  void _markTodoReminderSent(String todoId) {
    _lastTodoReminderSent[todoId] = DateTime.now();
    _isTodoReminderProcessing[todoId] = false;
    debugPrint(
      'Marked todo reminder as sent for $todoId at ${_lastTodoReminderSent[todoId]}',
    );
  }

  void _clearTodoReminderState(String todoId) {
    _lastTodoReminderSent.remove(todoId);
    _isTodoReminderProcessing.remove(todoId);
    debugPrint('Cleared todo reminder state for $todoId');
  }

  Future<void> _sendDailySummaryNotification() async {
    if (_settings?.notificationsEnabled == false) return;
    // Check if we should send daily summary now
    if (!_shouldSendDailySummaryNow()) {
      debugPrint('Daily summary send skipped due to state checks');
      return;
    }

    _isDailySummaryProcessing = true;
    debugPrint('Starting daily summary processing');

    try {
      // Ensure Hive is initialized before accessing boxes
      if (!Hive.isBoxOpen('todos')) {
        await Hive.initFlutter();
        await HiveService.init();
      }

      Box<TodoModel> todosBox;
      try {
        todosBox = _hiveService.todosBox;
      } catch (e) {
        debugPrint(
          'Todos box not available for daily summary, attempting to open it: $e',
        );
        // Try to open the box directly
        todosBox = await Hive.openBox<TodoModel>('todos');
      }

      final todos = todosBox.values.where((todo) => !todo.isCompleted).toList();

      if (todos.isEmpty) {
        debugPrint('No pending todos, skipping daily summary');
        return;
      }

      String title =
          await _getLocalizedString('dailyTodoSummary') ?? 'Daily Todo Summary';
      String body =
          await _getLocalizedStringWithCount(
            'youHavePendingTodos',
            todos.length,
          ) ??
          'You have ${todos.length} pending todo${todos.length > 1 ? 's' : ''} to complete';

      // Try to get AI-generated content if smart notifications are enabled
      try {
        if (_aiProvider?.settings.enableSmartNotifications == true &&
            _aiProvider?.settings.isValid == true) {
          debugPrint('Generating AI-powered daily summary content');
          final languageCode = await _getCurrentLanguageCode();
          final aiMessage = await _aiProvider?.generateDailySummary(
            todos,
            languageCode: languageCode,
          );
          if (aiMessage != null && aiMessage.isNotEmpty) {
            // Parse the AI response to extract title and message
            // Try multiple formats that AI might return
            String? parsedTitle;
            String? parsedBody;

            // Format 1: TITLE: [title] MESSAGE: [message]
            var titleMatch = RegExp(
              r'TITLE:\s*(.+?)(?:\n|$|\s*MESSAGE:)',
              caseSensitive: false,
            ).firstMatch(aiMessage);
            var messageMatch = RegExp(
              r'MESSAGE:\s*(.+?)(?:\n|$)',
              caseSensitive: false,
            ).firstMatch(aiMessage);

            if (titleMatch != null && messageMatch != null) {
              parsedTitle = titleMatch.group(1)!.trim();
              parsedBody = messageMatch.group(1)!.trim();
            } else {
              // Format 2: **Title:** [title] **Message:** [message] (Markdown format)
              titleMatch = RegExp(
                r'\*\*Title:\*\*\s*(.+?)(?:\n|$|\*\*Message:\*\*)',
                caseSensitive: false,
              ).firstMatch(aiMessage);
              messageMatch = RegExp(
                r'\*\*Message:\*\*\s*(.+?)(?:\n|$)',
                caseSensitive: false,
              ).firstMatch(aiMessage);

              if (titleMatch != null && messageMatch != null) {
                parsedTitle = titleMatch.group(1)!.trim();
                parsedBody = messageMatch.group(1)!.trim();
              } else {
                // Format 3: First line is title, rest is message
                final lines = aiMessage.split('\n');
                if (lines.length >= 2) {
                  parsedTitle = lines[0].trim();
                  parsedBody = lines.sublist(1).join('\n').trim();

                  // Clean up common prefixes from title
                  parsedTitle = parsedTitle
                      .replaceAll(
                        RegExp(
                          r'^(Title:|🤖|Smart Reminder|AI Reminder|Daily)\s*',
                          caseSensitive: false,
                        ),
                        '',
                      )
                      .trim();

                  // Clean up common prefixes from message
                  parsedBody = parsedBody
                      .replaceAll(
                        RegExp(
                          r'^(Message:|Body:|Content:)\s*',
                          caseSensitive: false,
                        ),
                        '',
                      )
                      .trim();
                }
              }
            }

            // Use parsed values if successful, otherwise fallback
            if (parsedTitle != null &&
                parsedBody != null &&
                parsedTitle.isNotEmpty &&
                parsedBody.isNotEmpty) {
              // For daily summary, we keep the original title and only use AI message
              title = title; // Keep original title
              body = parsedBody;
              debugPrint(
                'AI-generated daily summary content applied successfully',
              );
            } else {
              // Last resort: try to extract any meaningful content
              final cleanMessage = aiMessage
                  .replaceAll(
                    RegExp(
                      r'\*\*?(Title|Message|Content):?\*\*?\s*',
                      caseSensitive: false,
                    ),
                    '',
                  )
                  .trim();
              if (cleanMessage.isNotEmpty) {
                // For daily summary, we keep the original title
                title = title; // Keep original title
                body = cleanMessage.length > 100
                    ? '${cleanMessage.substring(0, 97)}...'
                    : cleanMessage;
              } else {
                // Ultimate fallback - keep original content
                debugPrint(
                  'Could not parse AI daily summary response, using fallback',
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error generating AI summary content: $e');
        // Fall back to default content
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'daily_summary',
            'Daily Summary',
            channelDescription: 'Daily summary of pending todos',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
        defaultActionName: 'Open notification',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
        linux: linuxDetails,
      );

      await _notificationsPlugin.show(
        0,
        title,
        body,
        platformDetails,
        payload: 'daily_summary',
      );

      // Save the date after successful sending
      await _saveLastDailySummaryDate(DateTime.now());
      debugPrint('Daily summary notification sent successfully');
    } catch (e) {
      debugPrint('Error sending daily summary notification: $e');
    } finally {
      _isDailySummaryProcessing = false;
    }
  }

  Future<void> sendDailySummary() async {
    if (_settings?.notificationsEnabled == false) return;

    // Use the same logic as _sendDailySummaryNotification to avoid duplication
    await _sendDailySummaryNotification();

    // Only reschedule if we actually need to
    if (_shouldScheduleDailySummary()) {
      await _scheduleDailySummary();
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap
  }

  NotificationSettingsModel? get settings => _settings;

  // Debug and utility methods
  Future<void> resetDailySummaryState() async {
    debugPrint('Resetting daily summary state');
    _isDailySummaryProcessing = false;
    _lastDailySummaryDate = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSummaryKey);
      debugPrint('Daily summary state reset successfully');
    } catch (e) {
      debugPrint('Error resetting daily summary state: $e');
    }
  }

  void resetTodoReminderStates() {
    debugPrint('Resetting all todo reminder states');
    _lastTodoReminderSent.clear();
    _isTodoReminderProcessing.clear();
    debugPrint('Todo reminder states reset successfully');
  }

  Future<Map<String, dynamic>> getDailySummaryStatus() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool hasSentToday = false;
    if (_lastDailySummaryDate != null) {
      final lastSummary = DateTime(
        _lastDailySummaryDate!.year,
        _lastDailySummaryDate!.month,
        _lastDailySummaryDate!.day,
      );
      hasSentToday = lastSummary.isAtSameMomentAs(today);
    }

    return {
      'isEnabled': _settings?.dailySummaryEnabled ?? false,
      'isProcessing': _isDailySummaryProcessing,
      'hasSentToday': hasSentToday,
      'lastSentDate': _lastDailySummaryDate?.toIso8601String(),
      'scheduledTime': _settings?.dailySummaryTime.toString(),
      'timerActive': _dailySummaryTimer != null,
    };
  }

  // 检查是否是提醒时间
  static bool isTimeForReminder(DateTime reminderTime, DateTime now) {
    // 只检查小时和分钟是否严格相等
    return reminderTime.hour == now.hour && reminderTime.minute == now.minute;
  }

  Future<String?> _getLocalizedString(String key) async {
    try {
      final languageCode = await _getCurrentLanguageCode();
      final locale = Locale(languageCode);

      // 使用Flutter的l10n框架加载本地化字符串
      final l10n = await AppLocalizations.delegate.load(locale);

      switch (key) {
        case 'dailyTodoSummary':
          return l10n.dailyTodoSummary;
        default:
          return null;
      }
    } catch (e) {
      debugPrint('Error getting localized string for key $key: $e');
      return null;
    }
  }

  Future<String?> _getLocalizedStringWithCount(String key, int count) async {
    try {
      final languageCode = await _getCurrentLanguageCode();
      final locale = Locale(languageCode);

      // 使用Flutter的l10n框架加载本地化字符串
      final l10n = await AppLocalizations.delegate.load(locale);

      switch (key) {
        case 'youHavePendingTodos':
          final String pluralForm = count == 1 ? '' : 's';
          return l10n.youHavePendingTodos(count, count, pluralForm);
        default:
          return null;
      }
    } catch (e) {
      debugPrint('Error getting localized string with count for key $key: $e');
      return null;
    }
  }

  Future<AppLocalizations?> _getLocalizations() async {
    try {
      final languageCode = await _getCurrentLanguageCode();
      final locale = Locale(languageCode);
      final l10n = await AppLocalizations.delegate.load(locale);
      debugPrint(
        'NotificationService: Loaded localizations for language: $languageCode',
      );
      return l10n;
    } catch (e) {
      debugPrint('Error getting localizations: $e');
      return null;
    }
  }

  Future<void> rescheduleAllReminders() async {
    if (_settings?.notificationsEnabled == false) {
      debugPrint('Notifications disabled, skipping reschedule');
      return;
    }

    if (!_isPluginInitialized) {
      debugPrint('Notification plugin not initialized, skipping reschedule');
      return;
    }

    try {
      // Clear all existing timers
      _clearAllTimers();

      // Ensure Hive is initialized before accessing boxes
      if (!Hive.isBoxOpen('todos')) {
        await Hive.initFlutter();
        await HiveService.init();
      }

      Box<TodoModel> todosBox;
      try {
        todosBox = _hiveService.todosBox;
      } catch (e) {
        debugPrint(
          'Todos box not available for rescheduling, attempting to open it: $e',
        );
        // Try to open the box directly
        todosBox = await Hive.openBox<TodoModel>('todos');
      }

      final todos = todosBox.values
          .where(
            (todo) =>
                todo.reminderEnabled &&
                todo.reminderTime != null &&
                !todo.isCompleted &&
                !SyncWriteService().isTombstonedSync(SyncTypes.todo, todo.id),
          )
          .toList();

      debugPrint('Rescheduling ${todos.length} todo reminders');

      for (final todo in todos) {
        await scheduleTodoReminder(todo);
      }

      // Also reschedule daily summary if enabled and needed
      if (_settings?.dailySummaryEnabled == true &&
          _shouldScheduleDailySummary()) {
        debugPrint('Rescheduling daily summary');
        await _scheduleDailySummary();
      } else {
        debugPrint('Daily summary not needed, skipping reschedule');
      }
    } catch (e) {
      debugPrint('Error rescheduling reminders: $e');
    }
  }

  void _clearAllTimers() {
    // Cancel all todo reminder timers
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();

    // Clear all todo reminder states
    _lastTodoReminderSent.clear();
    _isTodoReminderProcessing.clear();

    // Cancel daily summary timer
    _dailySummaryTimer?.cancel();
    _dailySummaryTimer = null;
  }

  Future<void> showPomodoroCompleteNotification(
    PomodoroModel session, {
    String? preparedContent,
  }) async {
    try {
      String title;
      String body;

      // Get localized strings or use defaults
      final l10n = await _getLocalizations();
      debugPrint(
        'NotificationService: Session type: ${session.isBreak ? "BREAK" : "WORK"}, Duration: ${session.duration}s, BreakDuration: ${session.breakDuration}s',
      );

      if (session.isBreak) {
        // Break session completed - time to get back to work
        title = l10n?.breakTimeComplete ?? 'Break Time Complete!';
        body = l10n?.timeToGetBackToWork ?? 'Time to get back to work!';
        debugPrint(
          'NotificationService: Break complete notification - Title: $title, Body: $body',
        );
      } else {
        // Work session completed - time for break
        title = l10n?.pomodoroComplete ?? 'Pomodoro Complete!';
        // Determine if it's a short or long break based on the break duration
        final breakType = session.breakDuration >= 900
            ? 'long'
            : 'short'; // 900 seconds = 15 minutes
        body =
            l10n?.greatJobTimeForBreak(breakType) ??
            'Great job! Time for a $breakType break.';
        debugPrint(
          'NotificationService: Work complete notification - Title: $title, Body: $body, BreakType: $breakType',
        );
      }

      // Try to use pre-prepared AI content first, then generate on-demand if not available
      try {
        if (_aiProvider?.settings.enableSmartNotifications == true &&
            _aiProvider?.settings.isValid == true) {
          String? aiMessage = preparedContent;

          // If no pre-prepared content, generate it now (fallback)
          if (aiMessage == null || aiMessage.isEmpty) {
            debugPrint(
              'No pre-prepared AI content available, generating now...',
            );
            final languageCode = await _getCurrentLanguageCode();

            aiMessage = await _aiProvider?.generatePomodoroNotification(
              session,
              languageCode: languageCode,
            );
          } else {
            debugPrint('Using pre-prepared AI notification content');
          }

          if (aiMessage != null && aiMessage.isNotEmpty) {
            // Parse the AI response to extract title and message
            // Try multiple formats that AI might return
            String? parsedTitle;
            String? parsedBody;

            // Format 1: TITLE: [title] MESSAGE: [message]
            var titleMatch = RegExp(
              r'TITLE:\s*(.+?)(?:\n|$|\s*MESSAGE:)',
              caseSensitive: false,
            ).firstMatch(aiMessage);
            var messageMatch = RegExp(
              r'MESSAGE:\s*(.+?)(?:\n|$)',
              caseSensitive: false,
            ).firstMatch(aiMessage);

            if (titleMatch != null && messageMatch != null) {
              parsedTitle = titleMatch.group(1)!.trim();
              parsedBody = messageMatch.group(1)!.trim();
            } else {
              // Format 2: **Title:** [title] **Message:** [message] (Markdown format)
              titleMatch = RegExp(
                r'\*\*Title:\*\*\s*(.+?)(?:\n|$|\*\*Message:\*\*)',
                caseSensitive: false,
              ).firstMatch(aiMessage);
              messageMatch = RegExp(
                r'\*\*Message:\*\*\s*(.+?)(?:\n|$)',
                caseSensitive: false,
              ).firstMatch(aiMessage);

              if (titleMatch != null && messageMatch != null) {
                parsedTitle = titleMatch.group(1)!.trim();
                parsedBody = messageMatch.group(1)!.trim();
              } else {
                // Format 3: First line is title, rest is message
                final lines = aiMessage.split('\n');
                if (lines.length >= 2) {
                  parsedTitle = lines[0].trim();
                  parsedBody = lines.sublist(1).join('\n').trim();

                  // Clean up common prefixes from title
                  parsedTitle = parsedTitle
                      .replaceAll(
                        RegExp(
                          r'^(Title:|🤖|Smart Reminder|AI Reminder|Pomodoro)\s*',
                          caseSensitive: false,
                        ),
                        '',
                      )
                      .trim();

                  // Clean up common prefixes from message
                  parsedBody = parsedBody
                      .replaceAll(
                        RegExp(
                          r'^(Message:|Body:|Content:)\s*',
                          caseSensitive: false,
                        ),
                        '',
                      )
                      .trim();
                }
              }
            }

            // Use parsed values if successful, otherwise fallback
            if (parsedTitle != null &&
                parsedBody != null &&
                parsedTitle.isNotEmpty &&
                parsedBody.isNotEmpty) {
              title = parsedTitle;
              body = parsedBody;
              debugPrint(
                'AI-generated pomodoro notification content applied successfully',
              );
            } else {
              // Last resort: try to extract any meaningful content
              final cleanMessage = aiMessage
                  .replaceAll(
                    RegExp(
                      r'\*\*?(Title|Message|Content):?\*\*?\s*',
                      caseSensitive: false,
                    ),
                    '',
                  )
                  .trim();
              if (cleanMessage.isNotEmpty) {
                // If it's a long message, split it reasonably
                if (cleanMessage.length > 100) {
                  final firstLineBreak = cleanMessage.indexOf('\n');
                  if (firstLineBreak > 10 && firstLineBreak < 50) {
                    title = cleanMessage.substring(0, firstLineBreak).trim();
                    body = cleanMessage.substring(firstLineBreak + 1).trim();
                  } else {
                    title = '🍅 Smart Pomodoro';
                    body = cleanMessage.length > 100
                        ? '${cleanMessage.substring(0, 97)}...'
                        : cleanMessage;
                  }
                } else {
                  title = '🍅 Smart Pomodoro';
                  body = cleanMessage;
                }
              } else {
                // Ultimate fallback
                title = '🍅 Smart Pomodoro';
                body = aiMessage.length > 100
                    ? '${aiMessage.substring(0, 97)}...'
                    : aiMessage;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error with AI pomodoro notification content: $e');
        // Fall back to default localized content
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'pomodoro_complete',
            'Pomodoro Complete',
            channelDescription:
                'Notifications when pomodoro sessions are completed',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
        defaultActionName: 'Open notification',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
        linux: linuxDetails,
      );

      await _notificationsPlugin.show(
        tz.TZDateTime.now(tz.local).millisecondsSinceEpoch % 2147483647,
        title,
        body,
        platformDetails,
        payload: 'pomodoro_${session.id}',
      );

      // Pomodoro complete notification sent successfully
    } catch (e) {
      debugPrint('Error sending pomodoro complete notification: $e');
    }
  }
}
