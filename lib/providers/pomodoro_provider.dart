import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:easy_todo/models/pomodoro_model.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/notification_service.dart';
import 'package:easy_todo/providers/ai_provider.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/services/repositories/pomodoro_repository.dart';
import 'package:easy_todo/services/sync_write_service.dart';

enum PomodoroState { idle, running, paused, completed, breakTime }

class PomodoroProvider extends ChangeNotifier {
  final HiveService _hiveService = HiveService();
  final NotificationService _notificationService = NotificationService();
  final PomodoroRepository _pomodoroRepository = PomodoroRepository();
  final SyncWriteService _syncWriteService = SyncWriteService();
  AIProvider? _aiProvider;
  TodoProvider? _todoProvider;

  List<PomodoroModel> _pomodoroSessions = [];
  PomodoroModel? _currentSession;
  Timer? _timer;
  int _remainingSeconds = 0;
  PomodoroState _state = PomodoroState.idle;

  // Default settings
  int _workDuration = 25 * 60; // 25 minutes in seconds
  int _breakDuration = 5 * 60; // 5 minutes in seconds
  int _longBreakDuration = 15 * 60; // 15 minutes in seconds
  int _sessionsUntilLongBreak = 4;
  int _completedSessionsCount = 0;
  int _currentCycleSessionsCount = 0; // 当前番茄钟周期内的会话数

  // Pre-prepared notification content
  String? _preparedNotificationContent;

  // 设置AI Provider的方法
  void setAIProvider(AIProvider? aiProvider) {
    _aiProvider = aiProvider;
    _notificationService.setAIProvider(aiProvider);
  }

  // 设置Todo Provider的方法
  void setTodoProvider(TodoProvider? todoProvider) {
    _todoProvider = todoProvider;
  }

  // 获取本地时间的辅助方法
  DateTime _getLocalNow() {
    try {
      tz.initializeTimeZones();

      // 使用更完整的时区检测逻辑
      final localTimeZoneName = DateTime.now().timeZoneName;
      String? timeZoneId;

      if (localTimeZoneName.contains('CST') ||
          localTimeZoneName.contains('GMT+8') ||
          localTimeZoneName.contains('UTC+8')) {
        timeZoneId = 'Asia/Shanghai';
      } else if (localTimeZoneName.contains('PST') ||
          localTimeZoneName.contains('GMT-8')) {
        timeZoneId = 'America/Los_Angeles';
      } else if (localTimeZoneName.contains('EST') ||
          localTimeZoneName.contains('GMT-5')) {
        timeZoneId = 'America/New_York';
      } else if (localTimeZoneName.contains('JST') ||
          localTimeZoneName.contains('GMT+9')) {
        timeZoneId = 'Asia/Tokyo';
      } else if (localTimeZoneName.contains('GMT')) {
        final offset = DateTime.now().timeZoneOffset.inHours;
        if (offset == 8) {
          timeZoneId = 'Asia/Shanghai';
        } else if (offset == 9) {
          timeZoneId = 'Asia/Tokyo';
        } else if (offset == -5) {
          timeZoneId = 'America/New_York';
        } else if (offset == -8) {
          timeZoneId = 'America/Los_Angeles';
        }
      }

      if (timeZoneId != null) {
        try {
          final location = tz.getLocation(timeZoneId);
          tz.setLocalLocation(location);
          // debugPrint('PomodoroProvider: Set timezone to $timeZoneId');
        } catch (e) {
          debugPrint('PomodoroProvider: Failed to set timezone: $e');
        }
      }

      return tz.TZDateTime.now(tz.local);
    } catch (e) {
      debugPrint('PomodoroProvider: Timezone initialization failed: $e');
      return DateTime.now();
    }
  }

  PomodoroProvider() {
    _loadSettings();
    _loadPomodoroSessions();
  }

  List<PomodoroModel> get pomodoroSessions => _pomodoroSessions;
  PomodoroModel? get currentSession => _currentSession;
  int get remainingSeconds => _remainingSeconds;
  PomodoroState get state => _state;
  int get workDuration => _workDuration;
  int get breakDuration => _breakDuration;
  int get longBreakDuration => _longBreakDuration;
  int get sessionsUntilLongBreak => _sessionsUntilLongBreak;
  int get completedSessionsCount => _completedSessionsCount;

  String get formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get progress {
    if (_currentSession == null) return 0.0;
    return (_currentSession!.duration - _remainingSeconds) /
        _currentSession!.duration;
  }

  bool get isRunning => _state == PomodoroState.running;
  bool get isPaused => _state == PomodoroState.paused;
  bool get isBreakTime => _state == PomodoroState.breakTime;

  Future<void> _loadSettings() async {
    try {
      final pomodoroSettingsBox = _hiveService.pomodoroSettingsBox;
      final pomodoroSettings = pomodoroSettingsBox.get('pomodoroSettings');

      if (pomodoroSettings != null) {
        _workDuration = pomodoroSettings['workDuration'] ?? _workDuration;
        _breakDuration = pomodoroSettings['breakDuration'] ?? _breakDuration;
        _longBreakDuration =
            pomodoroSettings['longBreakDuration'] ?? _longBreakDuration;
        _sessionsUntilLongBreak =
            pomodoroSettings['sessionsUntilLongBreak'] ??
            _sessionsUntilLongBreak;
      }
    } catch (e) {
      debugPrint('Error loading pomodoro settings: $e');
    }
  }

  Future<void> _loadPomodoroSessions() async {
    try {
      final pomodoroBox = _hiveService.pomodoroBox;
      for (final session in pomodoroBox.values) {
        await _syncWriteService.ensureMetaExists(
          type: SyncTypes.pomodoro,
          recordId: session.id,
          schemaVersion: PomodoroRepository.schemaVersion,
        );
      }
      _pomodoroSessions = pomodoroBox.values
          .where(
            (s) =>
                !_syncWriteService.isTombstonedSync(SyncTypes.pomodoro, s.id),
          )
          .toList();
      _pomodoroSessions.sort((a, b) => b.startTime.compareTo(a.startTime));

      // Calculate completed sessions count
      _completedSessionsCount = _pomodoroSessions
          .where((session) => session.isCompleted && !session.isBreak)
          .length;
    } catch (e) {
      debugPrint('Error loading pomodoro sessions: $e');
    }
  }

  Future<void> startPomodoro(String todoId, {bool isBreak = false}) async {
    // Stop any existing timer
    await stopTimer();

    final duration = isBreak ? _getBreakDuration() : _workDuration;
    _remainingSeconds = duration;

    _currentSession = PomodoroModel.create(
      todoId: todoId,
      duration: duration,
      workDuration: _workDuration,
      breakDuration: _breakDuration,
      isBreak: isBreak,
    );

    _state = isBreak ? PomodoroState.breakTime : PomodoroState.running;

    // Clear previous prepared notification content
    _preparedNotificationContent = null;

    await _saveCurrentSession();
    _startTimer();

    // Prepare AI notification content in advance (non-blocking)
    _prepareNotificationContent(todoId, isBreak);

    notifyListeners();
  }

  int _getBreakDuration() {
    if (_currentCycleSessionsCount > 0 &&
        _currentCycleSessionsCount % _sessionsUntilLongBreak == 0) {
      debugPrint(
        'Long break triggered after $_currentCycleSessionsCount sessions in current cycle',
      );
      return _longBreakDuration;
    }
    debugPrint(
      'Short break after $_currentCycleSessionsCount sessions in current cycle',
    );
    return _breakDuration;
  }

  // Prepare AI notification content in advance (non-blocking)
  void _prepareNotificationContent(String todoId, bool isBreak) {
    if (_aiProvider == null || _currentSession == null) {
      debugPrint(
        'PomodoroProvider: Cannot prepare notification - AI Provider: ${_aiProvider != null}, Current Session: ${_currentSession != null}',
      );
      return;
    }
    // Run in background without blocking the UI
    unawaited(_prepareNotificationContentAsync(todoId, isBreak));
  }

  Future<void> _prepareNotificationContentAsync(
    String todoId,
    bool isBreak,
  ) async {
    try {
      // Get todo title for better AI context
      String? todoTitle;
      if (_todoProvider != null) {
        try {
          final todo = _todoProvider!.allTodos.firstWhere(
            (t) => t.id == todoId,
          );
          todoTitle = todo.title;
        } catch (e) {
          debugPrint('PomodoroProvider: Todo not found for id $todoId: $e');
        }
      } else {
        debugPrint('PomodoroProvider: Todo Provider is null');
      }

      // Prepare notification content in advance
      final preparedContent = await _aiProvider!.preparePomodoroNotification(
        _currentSession!,
        todoTitle: todoTitle,
      );

      if (preparedContent != null && preparedContent.isNotEmpty) {
        _preparedNotificationContent = preparedContent;
      } else {
        debugPrint(
          'PomodoroProvider: AI Provider returned empty or null content',
        );
        _preparedNotificationContent = null;
      }
    } catch (e) {
      debugPrint(
        'PomodoroProvider: Error preparing pomodoro notification content: $e',
      );
      // If preparation fails, we'll fall back to default notifications
    }
  }

  void _startTimer() {
    // 使用Timer进行前台更新
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
  }

  // Android Alarm Manager removed - using Timer only

  void _onTimerComplete() {
    _timer?.cancel();
    _timer = null;

    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        isCompleted: true,
        endTime: _getLocalNow(),
        actualDuration: _currentSession!.duration - _remainingSeconds,
      );

      if (!_currentSession!.isBreak) {
        _completedSessionsCount++;
        _currentCycleSessionsCount++;
      }

      _saveCurrentSession();

      // If work session completed, automatically start break session
      if (!_currentSession!.isBreak) {
        _state = PomodoroState.completed;
        // Play notification sound for completed work session with pre-prepared content
        _notificationService.showPomodoroCompleteNotification(
          _currentSession!,
          preparedContent: _preparedNotificationContent,
        );

        // Clear prepared content after use
        _preparedNotificationContent = null;

        // Auto-start break session after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (_currentSession != null && _state == PomodoroState.completed) {
            startPomodoro(_currentSession!.todoId, isBreak: true);
          }
        });
      } else {
        _state = PomodoroState.completed;
        _notificationService.showPomodoroCompleteNotification(
          _currentSession!,
          preparedContent: _preparedNotificationContent,
        );

        // Clear prepared content after use
        _preparedNotificationContent = null;

        // Auto-start work session after break completion
        Future.delayed(const Duration(seconds: 2), () {
          if (_currentSession != null && _state == PomodoroState.completed) {
            startPomodoro(_currentSession!.todoId, isBreak: false);
          }
        });
      }

      notifyListeners();
    }
  }

  Future<void> pauseTimer() async {
    if (_state == PomodoroState.running || _state == PomodoroState.breakTime) {
      _timer?.cancel();
      _timer = null;
      _state = PomodoroState.paused;

      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          actualDuration: _currentSession!.duration - _remainingSeconds,
        );
        await _saveCurrentSession();
      }

      notifyListeners();
    }
  }

  Future<void> resumeTimer() async {
    if (_state == PomodoroState.paused) {
      _state = _currentSession?.isBreak == true
          ? PomodoroState.breakTime
          : PomodoroState.running;
      _startTimer();
      notifyListeners();
    }
  }

  Future<void> stopTimer() async {
    _timer?.cancel();
    _timer = null;

    // Exit without saving the session - discard incomplete sessions
    _currentSession = null;
    _remainingSeconds = 0;
    _state = PomodoroState.idle;

    // Clear prepared notification content
    _preparedNotificationContent = null;

    notifyListeners();
  }

  // 重置当前番茄钟周期
  void resetCurrentCycle() {
    _currentCycleSessionsCount = 0;
    notifyListeners();
  }

  Future<void> completePomodoro(TodoModel todo) async {
    if (_currentSession != null) {
      // Calculate actual time spent
      final actualDuration = _currentSession!.duration - _remainingSeconds;

      // Update todo with time spent
      todo.copyWith(
        isCompleted: true,
        completedAt: _getLocalNow(),
        timeSpent: (todo.timeSpent ?? 0) + actualDuration,
      );

      // Update current session
      _currentSession = _currentSession!.copyWith(
        isCompleted: true,
        endTime: _getLocalNow(),
        actualDuration: actualDuration,
      );

      if (!_currentSession!.isBreak) {
        _completedSessionsCount++;
      }

      await _saveCurrentSession();
      await stopTimer();

      // The todo update should be handled by TodoProvider
      // This provider will just return the updated todo
      notifyListeners();
    }
  }

  Future<void> completePomodoroManually(TodoModel todo) async {
    if (_currentSession != null) {
      // Calculate actual time spent (current session duration)
      final actualDuration = _currentSession!.duration - _remainingSeconds;

      // Update current session as completed
      final wasAlreadyCompleted = _currentSession!.isCompleted;
      _currentSession = _currentSession!.copyWith(
        isCompleted: true,
        endTime: _getLocalNow(),
        actualDuration: actualDuration,
      );

      // Only increment count if the session wasn't already completed
      if (!_currentSession!.isBreak && !wasAlreadyCompleted) {
        _completedSessionsCount++;
      }

      await _saveCurrentSession();
      await stopTimer();

      notifyListeners();
    }
  }

  Future<void> _saveCurrentSession() async {
    if (_currentSession != null) {
      try {
        await _pomodoroRepository.upsert(_currentSession!);

        // Reload sessions from database to ensure consistency
        await _loadPomodoroSessions();
      } catch (e) {
        debugPrint('Error saving pomodoro session: $e');
      }
    }
  }

  Future<void> updateSettings({
    int? workDuration,
    int? breakDuration,
    int? longBreakDuration,
    int? sessionsUntilLongBreak,
  }) async {
    if (workDuration != null && workDuration > 0) {
      _workDuration = workDuration;
    }
    if (breakDuration != null && breakDuration > 0) {
      _breakDuration = breakDuration;
    }
    if (longBreakDuration != null && longBreakDuration > 0) {
      _longBreakDuration = longBreakDuration;
    }
    if (sessionsUntilLongBreak != null && sessionsUntilLongBreak > 0) {
      _sessionsUntilLongBreak = sessionsUntilLongBreak;
    }

    // Save settings to Hive
    try {
      final pomodoroSettingsBox = _hiveService.pomodoroSettingsBox;
      await pomodoroSettingsBox.put('pomodoroSettings', {
        'workDuration': _workDuration,
        'breakDuration': _breakDuration,
        'longBreakDuration': _longBreakDuration,
        'sessionsUntilLongBreak': _sessionsUntilLongBreak,
      });
    } catch (e) {
      debugPrint('Error saving pomodoro settings: $e');
    }

    notifyListeners();
  }

  List<PomodoroModel> getSessionsForTodo(String todoId) {
    return _pomodoroSessions
        .where((session) => session.todoId == todoId)
        .toList();
  }

  List<PomodoroModel> getTodaySessions() {
    final now = _getLocalNow();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _pomodoroSessions.where((session) {
      return session.startTime.isAtSameMomentAs(today) ||
          (session.startTime.isAfter(today) &&
              session.startTime.isBefore(tomorrow));
    }).toList();
  }

  List<PomodoroModel> getWeekSessions() {
    final now = _getLocalNow();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return _pomodoroSessions.where((session) {
      return session.startTime.isAtSameMomentAs(weekStart) ||
          session.startTime.isAfter(weekStart);
    }).toList();
  }

  List<PomodoroModel> getMonthSessions() {
    final now = _getLocalNow();
    final monthStart = DateTime(now.year, now.month, 1);
    return _pomodoroSessions.where((session) {
      return session.startTime.isAtSameMomentAs(monthStart) ||
          session.startTime.isAfter(monthStart);
    }).toList();
  }

  int getTotalTimeSpent({
    String? todoId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    List<PomodoroModel> sessions;

    if (todoId != null) {
      sessions = getSessionsForTodo(todoId);
    } else {
      sessions = _pomodoroSessions
          .where((s) => s.isCompleted && s.actualDuration != null && !s.isBreak)
          .toList();

      // Apply date filtering if provided
      if (startDate != null) {
        sessions = sessions
            .where(
              (s) =>
                  s.startTime.isAtSameMomentAs(startDate) ||
                  s.startTime.isAfter(startDate),
            )
            .toList();
      }
      if (endDate != null) {
        sessions = sessions
            .where((s) => s.startTime.isBefore(endDate))
            .toList();
      }
    }

    return sessions.fold<int>(
      0,
      (total, session) => total + (session.actualDuration ?? 0),
    );
  }

  double getAverageTimeSpent({String? todoId}) {
    final sessions = todoId != null
        ? getSessionsForTodo(todoId)
        : _pomodoroSessions
              .where(
                (s) => s.isCompleted && s.actualDuration != null && !s.isBreak,
              )
              .toList();

    if (sessions.isEmpty) return 0.0;
    final totalTime = sessions.fold<int>(
      0,
      (total, session) => total + (session.actualDuration ?? 0),
    );
    return totalTime / sessions.length;
  }

  // 清除所有pomodoro会话数据（用于调试或重置）
  Future<void> clearAllSessions() async {
    try {
      final pomodoroBox = _hiveService.pomodoroBox;
      await pomodoroBox.clear();
      _pomodoroSessions.clear();
      _completedSessionsCount = 0;
      _currentCycleSessionsCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing pomodoro sessions: $e');
    }
  }

  // 重置所有状态（当数据被外部清除时调用）
  void resetAllState() {
    _pomodoroSessions.clear();
    _completedSessionsCount = 0;
    _currentCycleSessionsCount = 0;
    _currentSession = null;
    _remainingSeconds = 0;
    _state = PomodoroState.idle;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
