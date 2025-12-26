import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/notification_settings_model.dart';
import 'package:easy_todo/models/pomodoro_model.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/providers/ai_provider.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/timezone_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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

  static NotificationService get instance => _instance;

  final HiveService _hiveService = HiveService();
  NotificationSettingsModel? _settings;

  final Map<String, Timer> _activeTimers = {};
  Timer? _dailySummaryTimer;

  DateTime? _lastDailySummaryDate;
  bool _isDailySummaryProcessing = false;
  static const String _lastSummaryKey = 'last_daily_summary_date';

  final Map<String, DateTime> _lastTodoReminderSent = {};
  final Map<String, bool> _isTodoReminderProcessing = {};

  Future<void> initialize() async {
    await _initializeTimeZone();
    await _loadSettings();
  }

  Future<void> _initializeTimeZone() async {
    try {
      final timezoneService = TimezoneService();
      await timezoneService.initialize();

      final detectedTimezone = timezoneService.detectTimezone();
      await timezoneService.setCustomTimezone(detectedTimezone);
    } catch (e) {
      debugPrint(
        'NotificationService(web): Failed to initialize timezone service: $e',
      );
      try {
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.UTC);
      } catch (fallbackError) {
        debugPrint(
          'NotificationService(web): Fallback timezone init failed: $fallbackError',
        );
      }
    }
  }

  Future<void> _loadSettings() async {
    try {
      if (!Hive.isBoxOpen('notificationSettings')) {
        await Hive.initFlutter();
        await HiveService.init();
      }

      Box<NotificationSettingsModel> settingsBox;
      try {
        settingsBox = _hiveService.notificationSettingsBox;
      } catch (_) {
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

      await _loadLastDailySummaryDate();
      if (_shouldScheduleDailySummary()) {
        await _scheduleDailySummary();
      }
    } catch (e) {
      debugPrint('NotificationService(web): Error loading settings: $e');
      _settings = NotificationSettingsModel.create();
    }
  }

  Future<bool> hasNotificationPermission() async {
    try {
      return html.Notification.permission == 'granted';
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final result = await html.Notification.requestPermission();
      return result == 'granted';
    } catch (_) {
      return false;
    }
  }

  Future<void> updateSettings(NotificationSettingsModel settings) async {
    final oldSettings = _settings;
    _settings = settings;
    try {
      if (!Hive.isBoxOpen('notificationSettings')) {
        await Hive.initFlutter();
        await HiveService.init();
      }

      Box<NotificationSettingsModel> settingsBox;
      try {
        settingsBox = _hiveService.notificationSettingsBox;
      } catch (_) {
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
      }

      final enabledChanged =
          oldSettings?.dailySummaryEnabled != settings.dailySummaryEnabled;
      final timeChanged =
          oldSettings?.dailySummaryTime != settings.dailySummaryTime;

      if (settings.dailySummaryEnabled && timeChanged) {
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
      debugPrint('NotificationService(web): Error updating settings: $e');
    }
  }

  Future<void> scheduleTodoReminder(TodoModel todo) async {
    if (_settings?.notificationsEnabled == false) return;
    if (!todo.reminderEnabled || todo.reminderTime == null) return;

    final now = DateTime.now();
    final scheduledTime = todo.reminderTime!;

    if (scheduledTime.hour == now.hour && scheduledTime.minute == now.minute) {
      if (_shouldSendTodoReminderNow(todo)) {
        await sendTodoReminderNotification(todo);
      }
      return;
    }

    _activeTimers[todo.id]?.cancel();

    final delay = scheduledTime.difference(now);
    if (delay.isNegative) {
      if (todo.isGeneratedFromRepeat) {
        final nextScheduledTime = scheduledTime.add(const Duration(days: 1));
        final correctedDelay = nextScheduledTime.difference(now);
        if (!correctedDelay.isNegative) {
          _activeTimers[todo.id] = Timer(correctedDelay, () async {
            await sendTodoReminderNotification(todo);
          });
        }
      }
      return;
    }

    _activeTimers[todo.id] = Timer(delay, () async {
      await sendTodoReminderNotification(todo);
    });
  }

  Future<void> sendTodoReminderNotification(TodoModel todo) async {
    if (_settings?.notificationsEnabled == false) return;

    if (!_shouldSendTodoReminderNow(todo)) return;
    _isTodoReminderProcessing[todo.id] = true;

    try {
      if (!await hasNotificationPermission()) {
        _isTodoReminderProcessing[todo.id] = false;
        return;
      }

      String title = 'Todo Reminder';
      String body = todo.title;

      try {
        final languageCode = await _getCurrentLanguageCode();
        final aiMessage = await _aiProvider?.generateSmartNotification(
          todo,
          languageCode: languageCode,
          context: _context,
        );
        if (aiMessage != null && aiMessage.isNotEmpty) {
          final parsed = _parseAiTitleBody(aiMessage);
          if (parsed != null) {
            title = parsed.$1;
            body = parsed.$2;
          } else {
            title = '🤖 Smart Reminder';
            body = aiMessage.length > 100
                ? '${aiMessage.substring(0, 97)}...'
                : aiMessage;
          }
        }
      } catch (e) {
        debugPrint('NotificationService(web): AI content error: $e');
      }

      _showBrowserNotification(title, body, tag: 'todo_${todo.id}');

      _markTodoReminderSent(todo.id);
      _activeTimers.remove(todo.id);
    } catch (e) {
      debugPrint('NotificationService(web): Error sending todo reminder: $e');
      _isTodoReminderProcessing[todo.id] = false;
    }
  }

  Future<void> cancelTodoReminder(String todoId) async {
    _activeTimers[todoId]?.cancel();
    _activeTimers.remove(todoId);
    _clearTodoReminderState(todoId);
  }

  Future<void> sendTestNotification(String title, String body) async {
    if (!await hasNotificationPermission()) return;
    _showBrowserNotification(title, body, tag: 'test_notification');
  }

  Future<void> _scheduleDailySummary() async {
    if (_settings?.notificationsEnabled == false) return;
    if (_settings?.dailySummaryEnabled == false) return;
    if (_isDailySummaryProcessing) return;

    await _cancelDailySummary();

    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      _settings!.dailySummaryTime.hour,
      _settings!.dailySummaryTime.minute,
    );

    final nextRun = scheduledTime.isAfter(now)
        ? scheduledTime
        : scheduledTime.add(const Duration(days: 1));
    final initialDelay = nextRun.difference(now);

    _dailySummaryTimer = Timer(initialDelay, () async {
      await _sendDailySummaryNotification();
      _dailySummaryTimer = Timer.periodic(const Duration(days: 1), (_) async {
        await _sendDailySummaryNotification();
      });
    });
  }

  Future<void> _cancelDailySummary() async {
    _dailySummaryTimer?.cancel();
    _dailySummaryTimer = null;
  }

  Future<void> _sendDailySummaryNotification() async {
    if (_settings?.notificationsEnabled == false) return;
    if (!_shouldSendDailySummaryNow()) return;
    if (!await hasNotificationPermission()) return;

    _isDailySummaryProcessing = true;
    try {
      if (!Hive.isBoxOpen('todos')) {
        await Hive.initFlutter();
        await HiveService.init();
      }

      Box<TodoModel> todosBox;
      try {
        todosBox = _hiveService.todosBox;
      } catch (_) {
        todosBox = await Hive.openBox<TodoModel>('todos');
      }

      final todos = todosBox.values.where((t) => !t.isCompleted).toList();
      if (todos.isEmpty) {
        await _saveLastDailySummaryDate(DateTime.now());
        return;
      }

      var title = 'Daily Summary';
      var body = 'You have ${todos.length} pending todos.';

      try {
        final l10n = await _getLocalizations();
        if (l10n != null) {
          title = l10n.dailyTodoSummary;
          body = l10n.youHavePendingTodos(
            todos.length,
            todos.length,
            todos.length == 1 ? '' : 's',
          );
        }
      } catch (_) {}

      try {
        final languageCode = await _getCurrentLanguageCode();
        final aiContent = await _aiProvider?.generateDailySummary(
          todos,
          languageCode: languageCode,
        );
        if (aiContent != null && aiContent.isNotEmpty) {
          final parsed = _parseAiTitleBody(aiContent);
          if (parsed != null) {
            title = parsed.$1;
            body = parsed.$2;
          }
        }
      } catch (e) {
        debugPrint('NotificationService(web): AI daily summary error: $e');
      }

      _showBrowserNotification(title, body, tag: 'daily_summary');
      await _saveLastDailySummaryDate(DateTime.now());
    } catch (e) {
      debugPrint('NotificationService(web): Daily summary error: $e');
    } finally {
      _isDailySummaryProcessing = false;
    }
  }

  Future<void> sendDailySummary() async {
    if (_settings?.notificationsEnabled == false) return;
    await _sendDailySummaryNotification();
    if (_shouldScheduleDailySummary()) {
      await _scheduleDailySummary();
    }
  }

  Future<void> showPomodoroCompleteNotification(
    PomodoroModel session, {
    String? preparedContent,
  }) async {
    if (_settings?.notificationsEnabled == false) return;
    if (!await hasNotificationPermission()) return;

    var title = 'Pomodoro';
    var body = 'Session complete';

    if (preparedContent != null && preparedContent.isNotEmpty) {
      final parsed = _parseAiTitleBody(preparedContent);
      if (parsed != null) {
        title = parsed.$1;
        body = parsed.$2;
      } else {
        body = preparedContent.length > 120
            ? '${preparedContent.substring(0, 117)}...'
            : preparedContent;
      }
    }

    _showBrowserNotification(title, body, tag: 'pomodoro_${session.id}');
  }

  Future<void> rescheduleAllReminders() async {
    if (_settings?.notificationsEnabled == false) {
      return;
    }

    try {
      for (final timer in _activeTimers.values) {
        timer.cancel();
      }
      _activeTimers.clear();
      resetTodoReminderStates();

      if (!Hive.isBoxOpen('todos')) {
        await Hive.initFlutter();
        await HiveService.init();
      }

      Box<TodoModel> todosBox;
      try {
        todosBox = _hiveService.todosBox;
      } catch (_) {
        todosBox = await Hive.openBox<TodoModel>('todos');
      }

      final todos = todosBox.values.toList();
      for (final todo in todos) {
        if (todo.reminderEnabled &&
            todo.reminderTime != null &&
            !todo.isCompleted) {
          await scheduleTodoReminder(todo);
        }
      }

      if (_shouldScheduleDailySummary()) {
        await _scheduleDailySummary();
      }
    } catch (e) {
      debugPrint('NotificationService(web): Reschedule error: $e');
    }
  }

  NotificationSettingsModel? get settings => _settings;

  Future<void> resetDailySummaryState() async {
    _isDailySummaryProcessing = false;
    _lastDailySummaryDate = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSummaryKey);
    } catch (_) {}
  }

  void resetTodoReminderStates() {
    _lastTodoReminderSent.clear();
    _isTodoReminderProcessing.clear();
  }

  Future<Map<String, dynamic>> getDailySummaryStatus() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var hasSentToday = false;
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

  Future<void> _loadLastDailySummaryDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSummaryString = prefs.getString(_lastSummaryKey);
      if (lastSummaryString != null) {
        _lastDailySummaryDate = DateTime.parse(lastSummaryString);
      }
    } catch (_) {}
  }

  Future<void> _saveLastDailySummaryDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSummaryKey, date.toIso8601String());
      _lastDailySummaryDate = date;
    } catch (_) {}
  }

  Future<void> _clearLastDailySummaryDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSummaryKey);
      _lastDailySummaryDate = null;
    } catch (_) {}
  }

  bool _shouldScheduleDailySummary() {
    if (_settings?.dailySummaryEnabled != true) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastDailySummaryDate != null) {
      final lastSummary = DateTime(
        _lastDailySummaryDate!.year,
        _lastDailySummaryDate!.month,
        _lastDailySummaryDate!.day,
      );
      if (lastSummary.isAtSameMomentAs(today)) {
        return false;
      }
    }
    return true;
  }

  bool _shouldSendDailySummaryNow() {
    if (_isDailySummaryProcessing) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastDailySummaryDate != null) {
      final lastSummary = DateTime(
        _lastDailySummaryDate!.year,
        _lastDailySummaryDate!.month,
        _lastDailySummaryDate!.day,
      );
      if (lastSummary.isAtSameMomentAs(today)) {
        return false;
      }
    }
    return true;
  }

  bool _shouldSendTodoReminderNow(TodoModel todo) {
    if (_isTodoReminderProcessing[todo.id] == true) {
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

    final lastSent = _lastTodoReminderSent[todo.id];
    if (lastSent != null) {
      final lastMinute = DateTime(
        lastSent.year,
        lastSent.month,
        lastSent.day,
        lastSent.hour,
        lastSent.minute,
      );
      if (lastMinute.isAtSameMomentAs(currentMinute)) {
        return false;
      }
    }

    return true;
  }

  void _markTodoReminderSent(String todoId) {
    _lastTodoReminderSent[todoId] = DateTime.now();
    _isTodoReminderProcessing[todoId] = false;
  }

  void _clearTodoReminderState(String todoId) {
    _lastTodoReminderSent.remove(todoId);
    _isTodoReminderProcessing.remove(todoId);
  }

  (String, String)? _parseAiTitleBody(String aiMessage) {
    String? parsedTitle;
    String? parsedBody;

    var titleMatch = RegExp(
      r'TITLE:\\s*(.+?)(?:\\n|$|\\s*MESSAGE:)',
      caseSensitive: false,
    ).firstMatch(aiMessage);
    var messageMatch = RegExp(
      r'MESSAGE:\\s*(.+?)(?:\\n|$)',
      caseSensitive: false,
    ).firstMatch(aiMessage);

    if (titleMatch != null && messageMatch != null) {
      parsedTitle = titleMatch.group(1)?.trim();
      parsedBody = messageMatch.group(1)?.trim();
    } else {
      final lines = aiMessage
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (lines.length >= 2) {
        parsedTitle = lines.first.trim();
        parsedBody = lines.sublist(1).join('\n').trim();
      }
    }

    if (parsedTitle == null || parsedBody == null) return null;
    if (parsedTitle.isEmpty || parsedBody.isEmpty) return null;
    return (parsedTitle, parsedBody);
  }

  Future<String> _getCurrentLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('app_language') ?? 'zh';
    } catch (_) {
      return 'zh';
    }
  }

  Future<AppLocalizations?> _getLocalizations() async {
    try {
      final languageCode = await _getCurrentLanguageCode();
      final locale = Locale(languageCode);
      return AppLocalizations.delegate.load(locale);
    } catch (_) {
      return null;
    }
  }

  void _showBrowserNotification(String title, String body, {String? tag}) {
    try {
      if (html.Notification.permission != 'granted') return;
      html.Notification(title, body: body, tag: tag);
    } catch (e) {
      debugPrint('NotificationService(web): Browser notification failed: $e');
    }
  }
}
