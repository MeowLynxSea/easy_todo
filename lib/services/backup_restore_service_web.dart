import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:easy_todo/models/pomodoro_model.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/models/statistics_data_model.dart';
import 'package:easy_todo/models/statistics_model.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/services/file_service.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/repositories/pomodoro_repository.dart';
import 'package:easy_todo/services/repositories/repeat_todo_repository.dart';
import 'package:easy_todo/services/repositories/statistics_data_repository.dart';
import 'package:easy_todo/services/repositories/todo_repository.dart';
import 'package:easy_todo/services/sync_write_service.dart';

class BackupRestoreService {
  final HiveService _hiveService = HiveService();
  final SyncWriteService _syncWriteService = SyncWriteService();
  final TodoRepository _todoRepository = TodoRepository();
  final RepeatTodoRepository _repeatTodoRepository = RepeatTodoRepository();
  final PomodoroRepository _pomodoroRepository = PomodoroRepository();
  final StatisticsDataRepository _statisticsDataRepository =
      StatisticsDataRepository();

  Future<Map<String, dynamic>> backupData() async {
    try {
      final todos = _hiveService.todosBox.values
          .where(
            (t) => !_syncWriteService.isTombstonedSync(SyncTypes.todo, t.id),
          )
          .toList();
      final statistics = _hiveService.statisticsBox.values.toList();
      final pomodoroSessions = _hiveService.pomodoroBox.values
          .where(
            (s) =>
                !_syncWriteService.isTombstonedSync(SyncTypes.pomodoro, s.id),
          )
          .toList();
      final repeatTodos = _hiveService.repeatTodosBox.values
          .where(
            (t) =>
                !_syncWriteService.isTombstonedSync(SyncTypes.repeatTodo, t.id),
          )
          .toList();
      final statisticsData = _hiveService.statisticsDataBox.values
          .where(
            (d) => !_syncWriteService.isTombstonedSync(
              SyncTypes.statisticsData,
              d.id,
            ),
          )
          .toList();

      try {
        tz.initializeTimeZones();
      } catch (_) {}

      final backupPayload = {
        'version': '2.0.0',
        'backupDate': tz.TZDateTime.now(tz.local).toIso8601String(),
        'todos': todos.map((todo) => todo.toJson()).toList(),
        'statistics': statistics.map((stat) => stat.toJson()).toList(),
        'pomodoroSessions': pomodoroSessions.map((s) => s.toJson()).toList(),
        'repeatTodos': repeatTodos.map((rt) => rt.toJson()).toList(),
        'statisticsData': statisticsData.map((sd) => sd.toJson()).toList(),
      };

      final jsonString = jsonEncode(backupPayload);
      final fileName = FileService.generateBackupFileName();

      return {
        'success': true,
        'fileName': fileName,
        'backupJson': jsonString,
        'fileSize': utf8.encode(jsonString).length,
        'todosCount': todos.length,
        'statisticsCount': statistics.length,
        'pomodoroCount': pomodoroSessions.length,
        'repeatTodosCount': repeatTodos.length,
        'statisticsDataCount': statisticsData.length,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> restoreData(String filePath) async {
    return {
      'success': false,
      'error': 'restoreData(filePath) is not supported on Web',
    };
  }

  Future<Map<String, dynamic>> restoreFromBackupJson(String jsonContent) async {
    try {
      final backupData = jsonDecode(jsonContent) as Map<String, dynamic>;

      if (!_validateBackupFormat(backupData)) {
        return {'success': false, 'error': 'Invalid backup format'};
      }

      final currentTodos = _hiveService.todosBox.values.toList();
      final currentStatistics = _hiveService.statisticsBox.values.toList();
      final currentPomodoroSessions = _hiveService.pomodoroBox.values.toList();
      final currentRepeatTodos = _hiveService.repeatTodosBox.values.toList();
      final currentStatisticsData = _hiveService.statisticsDataBox.values
          .toList();

      try {
        for (final todo in _hiveService.todosBox.values) {
          await _todoRepository.tombstone(todo.id);
        }
        for (final session in _hiveService.pomodoroBox.values) {
          await _pomodoroRepository.tombstone(session.id);
        }
        for (final repeatTodo in _hiveService.repeatTodosBox.values) {
          await _repeatTodoRepository.tombstone(repeatTodo.id);
        }
        for (final statData in _hiveService.statisticsDataBox.values) {
          await _statisticsDataRepository.tombstone(statData.id);
        }

        await _hiveService.statisticsBox.clear();

        final todosData = backupData['todos'] as List;
        for (final todoData in todosData) {
          final todo = TodoModel.fromJson(todoData);
          await _todoRepository.upsert(todo);
        }

        final statisticsList = backupData['statistics'] as List;
        for (final statData in statisticsList) {
          final statistic = StatisticsModel.fromJson(statData);
          await _hiveService.statisticsBox.add(statistic);
        }

        var pomodoroCount = 0;
        if (backupData.containsKey('pomodoroSessions')) {
          final pomodoroData = backupData['pomodoroSessions'] as List;
          for (final sessionData in pomodoroData) {
            final session = PomodoroModel.fromJson(sessionData);
            await _pomodoroRepository.upsert(session);
            pomodoroCount++;
          }
        }

        var repeatTodosCount = 0;
        if (backupData.containsKey('repeatTodos')) {
          final repeatTodosData = backupData['repeatTodos'] as List;
          for (final repeatTodoData in repeatTodosData) {
            final repeatTodo = RepeatTodoModel.fromJson(repeatTodoData);
            await _repeatTodoRepository.upsert(repeatTodo);
            repeatTodosCount++;
          }
        }

        var statisticsDataCount = 0;
        if (backupData.containsKey('statisticsData')) {
          final statisticsDataList = backupData['statisticsData'] as List;
          for (final statisticsDataJson in statisticsDataList) {
            final statisticsData = StatisticsDataModel.fromJson(
              statisticsDataJson,
            );
            await _statisticsDataRepository.upsert(statisticsData);
            statisticsDataCount++;
          }
        }

        await _ensureRepeatTodoConsistency();

        return {
          'success': true,
          'todosCount': todosData.length,
          'statisticsCount': statisticsList.length,
          'pomodoroCount': pomodoroCount,
          'repeatTodosCount': repeatTodosCount,
          'statisticsDataCount': statisticsDataCount,
          'backupDate': backupData['backupDate'],
        };
      } catch (restoreError) {
        try {
          for (final todo in _hiveService.todosBox.values) {
            await _todoRepository.tombstone(todo.id);
          }
          for (final session in _hiveService.pomodoroBox.values) {
            await _pomodoroRepository.tombstone(session.id);
          }
          for (final repeatTodo in _hiveService.repeatTodosBox.values) {
            await _repeatTodoRepository.tombstone(repeatTodo.id);
          }
          for (final statData in _hiveService.statisticsDataBox.values) {
            await _statisticsDataRepository.tombstone(statData.id);
          }

          await _hiveService.statisticsBox.clear();

          for (final todo in currentTodos) {
            final restoredTodo = TodoModel.fromJson(todo.toJson());
            await _todoRepository.upsert(restoredTodo);
          }
          for (final stat in currentStatistics) {
            await _hiveService.statisticsBox.add(
              StatisticsModel.fromJson(stat.toJson()),
            );
          }
          for (final session in currentPomodoroSessions) {
            final restoredSession = PomodoroModel.fromJson(session.toJson());
            await _pomodoroRepository.upsert(restoredSession);
          }
          for (final repeatTodo in currentRepeatTodos) {
            final restoredRepeatTodo = RepeatTodoModel.fromJson(
              repeatTodo.toJson(),
            );
            await _repeatTodoRepository.upsert(restoredRepeatTodo);
          }
          for (final data in currentStatisticsData) {
            final restoredData = StatisticsDataModel.fromJson(data.toJson());
            await _statisticsDataRepository.upsert(restoredData);
          }
        } catch (_) {}

        return {'success': false, 'error': '恢复失败: ${restoreError.toString()}'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> _ensureRepeatTodoConsistency() async {
    final todos = _hiveService.todosBox.values.toList();
    final repeatTodos = _hiveService.repeatTodosBox.values.toList();

    for (final repeatTodo in repeatTodos) {
      final generatedTodos = todos
          .where(
            (todo) =>
                todo.repeatTodoId == repeatTodo.id &&
                todo.isGeneratedFromRepeat,
          )
          .toList();

      if (generatedTodos.isNotEmpty) {
        final latestGenerated = generatedTodos.reduce(
          (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
        );

        if (repeatTodo.lastGeneratedDate == null ||
            repeatTodo.lastGeneratedDate!.isBefore(latestGenerated.createdAt)) {
          repeatTodo.lastGeneratedDate = latestGenerated.createdAt.toUtc();
          await repeatTodo.save();
        }
      }
    }
  }

  bool _validateBackupFormat(Map<String, dynamic> backupData) {
    try {
      if (!backupData.containsKey('version') ||
          !backupData.containsKey('backupDate') ||
          !backupData.containsKey('todos') ||
          !backupData.containsKey('statistics')) {
        return false;
      }

      if (backupData['todos'] is! List || backupData['statistics'] is! List) {
        return false;
      }

      if (backupData.containsKey('pomodoroSessions') &&
          backupData['pomodoroSessions'] is! List) {
        return false;
      }

      if (backupData.containsKey('repeatTodos') &&
          backupData['repeatTodos'] is! List) {
        return false;
      }

      if (backupData.containsKey('statisticsData') &&
          backupData['statisticsData'] is! List) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final todos = _hiveService.todosBox.values.toList();
      final statistics = _hiveService.statisticsBox.values.toList();
      final pomodoroSessions = _hiveService.pomodoroBox.values.toList();
      final repeatTodos = _hiveService.repeatTodosBox.values.toList();
      final statisticsData = _hiveService.statisticsDataBox.values.toList();

      var estimatedDataSize = 0;
      for (final todo in todos) {
        estimatedDataSize += jsonEncode(todo.toJson()).length;
      }
      for (final stat in statistics) {
        estimatedDataSize += jsonEncode(stat.toJson()).length;
      }
      for (final session in pomodoroSessions) {
        estimatedDataSize += jsonEncode(session.toJson()).length;
      }
      for (final repeatTodo in repeatTodos) {
        estimatedDataSize += jsonEncode(repeatTodo.toJson()).length;
      }
      for (final statData in statisticsData) {
        estimatedDataSize += jsonEncode(statData.toJson()).length;
      }

      final completedTodos = todos.where((todo) => todo.isCompleted).length;
      final pendingTodos = todos.length - completedTodos;

      final completedPomodoroSessions = pomodoroSessions
          .where((session) => session.isCompleted && !session.isBreak)
          .length;
      final totalFocusTime = pomodoroSessions
          .where((session) => session.isCompleted && !session.isBreak)
          .fold<int>(
            0,
            (total, session) => total + (session.actualDuration ?? 0),
          );

      return {
        'success': true,
        'todos': {
          'total': todos.length,
          'completed': completedTodos,
          'pending': pendingTodos,
        },
        'statistics': {'total': statistics.length},
        'pomodoro': {
          'total': pomodoroSessions.length,
          'completed': completedPomodoroSessions,
          'totalFocusTime': totalFocusTime,
        },
        'repeatTodos': {
          'total': repeatTodos.length,
          'dataStatisticsEnabled': repeatTodos
              .where((rt) => rt.dataStatisticsEnabled)
              .length,
        },
        'statisticsData': {'total': statisticsData.length},
        'storage': {
          'dataSize': estimatedDataSize,
          'backupSize': 0,
          'backupFiles': 0,
        },
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getBackupFiles() async => const [];

  Future<Map<String, dynamic>> cleanupData({
    bool clearCompleted = false,
    bool clearOldStatistics = false,
    bool clearOldPomodoroSessions = false,
    bool clearBackupFiles = false,
    int daysToKeep = 30,
  }) async {
    try {
      var todosDeleted = 0;
      var statisticsDeleted = 0;
      var pomodoroSessionsDeleted = 0;

      if (clearCompleted) {
        final completedTodos = _hiveService.todosBox.values
            .where((todo) => todo.isCompleted)
            .toList();

        for (final todo in completedTodos) {
          await _todoRepository.tombstone(todo.id);
          todosDeleted++;
        }
      }

      if (clearOldStatistics) {
        try {
          tz.initializeTimeZones();
        } catch (_) {}

        final now = tz.TZDateTime.now(tz.local);
        final cutoffDate = now.subtract(Duration(days: daysToKeep));

        final oldStatistics = _hiveService.statisticsBox.values
            .where((stat) => stat.date.isBefore(cutoffDate))
            .toList();
        for (final stat in oldStatistics) {
          await _hiveService.statisticsBox.delete(stat.key);
          statisticsDeleted++;
        }

        final oldStatisticsData = _hiveService.statisticsDataBox.values
            .where((sd) => sd.date.isBefore(cutoffDate))
            .toList();
        for (final statData in oldStatisticsData) {
          await _statisticsDataRepository.tombstone(statData.id);
          statisticsDeleted++;
        }
      }

      if (clearOldPomodoroSessions) {
        try {
          tz.initializeTimeZones();
        } catch (_) {}

        final now = tz.TZDateTime.now(tz.local);
        final cutoffDate = now.subtract(Duration(days: daysToKeep));

        final oldPomodoroSessions = _hiveService.pomodoroBox.values
            .where((session) => session.startTime.isBefore(cutoffDate))
            .toList();
        for (final session in oldPomodoroSessions) {
          await _pomodoroRepository.tombstone(session.id);
          pomodoroSessionsDeleted++;
        }
      }

      if (todosDeleted > 10 ||
          statisticsDeleted > 10 ||
          pomodoroSessionsDeleted > 10) {
        try {
          await _hiveService.reinitializeBoxes();
        } catch (e) {
          debugPrint('BackupRestoreService(web): Reinit boxes failed: $e');
        }
      }

      return {
        'success': true,
        'todosDeleted': todosDeleted,
        'statisticsDeleted': statisticsDeleted,
        'pomodoroSessionsDeleted': pomodoroSessionsDeleted,
        'backupFilesDeleted': 0,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
