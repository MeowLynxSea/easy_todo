import 'dart:convert';
import 'dart:io';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/models/statistics_model.dart';
import 'package:easy_todo/models/pomodoro_model.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/models/statistics_data_model.dart';
import 'package:easy_todo/services/file_service.dart';
import 'package:easy_todo/services/hive_service.dart';

class BackupRestoreService {
  final HiveService _hiveService = HiveService();

  /// 备份数据
  Future<Map<String, dynamic>> backupData() async {
    try {
      // 获取所有数据
      final todos = _hiveService.todosBox.values.toList();
      final statistics = _hiveService.statisticsBox.values.toList();
      final pomodoroSessions = _hiveService.pomodoroBox.values.toList();
      final repeatTodos = _hiveService.repeatTodosBox.values.toList();
      final statisticsData = _hiveService.statisticsDataBox.values.toList();

      // 转换为JSON
      // 确保时区已初始化
      try {
        tz.initializeTimeZones();
      } catch (e) {
        // 时区初始化失败时继续使用默认时区
      }
      final backupData = {
        'version': '2.0.0',
        'backupDate': tz.TZDateTime.now(tz.local).toIso8601String(),
        'todos': todos.map((todo) => todo.toJson()).toList(),
        'statistics': statistics.map((stat) => stat.toJson()).toList(),
        'pomodoroSessions': pomodoroSessions
            .map((session) => session.toJson())
            .toList(),
        'repeatTodos': repeatTodos.map((rt) => rt.toJson()).toList(),
        'statisticsData': statisticsData.map((sd) => sd.toJson()).toList(),
      };

      // 生成文件名并保存
      final fileName = FileService.generateBackupFileName();
      final backupDir = await FileService.getAppDirectory();
      final backupFile = File('${backupDir.path}/$fileName');

      await backupFile.writeAsString(jsonEncode(backupData));

      return {
        'success': true,
        'fileName': fileName,
        'filePath': backupFile.path,
        'fileSize': await backupFile.length(),
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

  /// 恢复数据
  Future<Map<String, dynamic>> restoreData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return {'success': false, 'error': 'Backup file not found'};
      }

      final content = await file.readAsString();
      return restoreFromBackupJson(content);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 从JSON字符串恢复数据（用于Web导入/通用恢复入口）
  Future<Map<String, dynamic>> restoreFromBackupJson(String jsonContent) async {
    try {
      final backupData = jsonDecode(jsonContent) as Map<String, dynamic>;

      // 验证备份格式
      if (!_validateBackupFormat(backupData)) {
        return {'success': false, 'error': 'Invalid backup format'};
      }

      // 备份当前数据以防恢复失败时可以回滚
      final currentTodos = _hiveService.todosBox.values.toList();
      final currentRepeatTodos = _hiveService.repeatTodosBox.values.toList();

      try {
        // 清空现有数据
        await _hiveService.todosBox.clear();
        await _hiveService.statisticsBox.clear();
        await _hiveService.pomodoroBox.clear();
        await _hiveService.repeatTodosBox.clear();
        await _hiveService.statisticsDataBox.clear();

        // 恢复todos
        final todosData = backupData['todos'] as List;
        for (var todoData in todosData) {
          final todo = TodoModel.fromJson(todoData);
          await _hiveService.todosBox.put(todo.id, todo);
        }

        // 恢复statistics
        final statisticsData = backupData['statistics'] as List;
        for (var statData in statisticsData) {
          final statistic = StatisticsModel.fromJson(statData);
          await _hiveService.statisticsBox.add(statistic);
        }

        // 恢复pomodoroSessions (如果存在，兼容旧版本)
        int pomodoroCount = 0;
        if (backupData.containsKey('pomodoroSessions')) {
          final pomodoroData = backupData['pomodoroSessions'] as List;
          for (var sessionData in pomodoroData) {
            final session = PomodoroModel.fromJson(sessionData);
            await _hiveService.pomodoroBox.put(session.id, session);
            pomodoroCount++;
          }
        }

        // 恢复repeatTodos (如果存在，兼容新版本)
        int repeatTodosCount = 0;
        if (backupData.containsKey('repeatTodos')) {
          final repeatTodosData = backupData['repeatTodos'] as List;
          for (var repeatTodoData in repeatTodosData) {
            final repeatTodo = RepeatTodoModel.fromJson(repeatTodoData);
            await _hiveService.repeatTodosBox.put(repeatTodo.id, repeatTodo);
            repeatTodosCount++;
          }
        }

        // 恢复statisticsData (如果存在，兼容新版本)
        int statisticsDataCount = 0;
        if (backupData.containsKey('statisticsData')) {
          final statisticsDataList = backupData['statisticsData'] as List;
          for (var statisticsDataJson in statisticsDataList) {
            final statisticsData = StatisticsDataModel.fromJson(
              statisticsDataJson,
            );
            await _hiveService.statisticsDataBox.put(
              statisticsData.id,
              statisticsData,
            );
            statisticsDataCount++;
          }
        }

        // 数据一致性检查：确保重复任务和生成的任务状态一致
        _ensureRepeatTodoConsistency();

        return {
          'success': true,
          'todosCount': todosData.length,
          'statisticsCount': statisticsData.length,
          'pomodoroCount': pomodoroCount,
          'repeatTodosCount': repeatTodosCount,
          'statisticsDataCount': statisticsDataCount,
          'backupDate': backupData['backupDate'],
        };
      } catch (restoreError) {
        // 恢复失败时，尝试恢复原始数据
        try {
          await _hiveService.todosBox.clear();
          await _hiveService.repeatTodosBox.clear();

          for (var todo in currentTodos) {
            await _hiveService.todosBox.put(todo.id, todo);
          }
          for (var repeatTodo in currentRepeatTodos) {
            await _hiveService.repeatTodosBox.put(repeatTodo.id, repeatTodo);
          }
        } catch (rollbackError) {
          // 回滚也失败了，至少不要丢失数据
        }

        return {'success': false, 'error': '恢复失败: ${restoreError.toString()}'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 确保重复任务和生成任务的数据一致性
  void _ensureRepeatTodoConsistency() {
    final todos = _hiveService.todosBox.values.toList();
    final repeatTodos = _hiveService.repeatTodosBox.values.toList();

    for (final repeatTodo in repeatTodos) {
      // 检查是否有对应的已生成的任务
      final generatedTodos = todos
          .where(
            (todo) =>
                todo.repeatTodoId == repeatTodo.id &&
                todo.isGeneratedFromRepeat,
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
          repeatTodo.lastGeneratedDate = latestGenerated.createdAt;
          repeatTodo.save();
        }
      }
    }
  }

  /// 验证备份格式
  bool _validateBackupFormat(Map<String, dynamic> backupData) {
    try {
      // 基本字段验证
      if (!backupData.containsKey('version') ||
          !backupData.containsKey('backupDate') ||
          !backupData.containsKey('todos') ||
          !backupData.containsKey('statistics')) {
        return false;
      }

      // 数据类型验证
      if (backupData['todos'] is! List || backupData['statistics'] is! List) {
        return false;
      }

      // pomodoroSessions 是可选的（为了向后兼容）
      if (backupData.containsKey('pomodoroSessions') &&
          backupData['pomodoroSessions'] is! List) {
        return false;
      }

      // repeatTodos 和 statisticsData 是可选的（为了向后兼容）
      if (backupData.containsKey('repeatTodos') &&
          backupData['repeatTodos'] is! List) {
        return false;
      }

      if (backupData.containsKey('statisticsData') &&
          backupData['statisticsData'] is! List) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 检查两个日期是否是同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    // 使用标准化日期比较，确保时区一致性
    final normalizedDate1 = DateTime(date1.year, date1.month, date1.day);
    final normalizedDate2 = DateTime(date2.year, date2.month, date2.day);
    return normalizedDate1.isAtSameMomentAs(normalizedDate2);
  }

  /// 获取存储统计信息
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final todos = _hiveService.todosBox.values.toList();
      final statistics = _hiveService.statisticsBox.values.toList();
      final pomodoroSessions = _hiveService.pomodoroBox.values.toList();
      final repeatTodos = _hiveService.repeatTodosBox.values.toList();
      final statisticsData = _hiveService.statisticsDataBox.values.toList();
      final storageInfo = await FileService.getStorageInfo();

      // 计算数据大小（估算）
      int estimatedDataSize = 0;
      for (var todo in todos) {
        estimatedDataSize += jsonEncode(todo.toJson()).length;
      }
      for (var stat in statistics) {
        estimatedDataSize += jsonEncode(stat.toJson()).length;
      }
      for (var session in pomodoroSessions) {
        estimatedDataSize += jsonEncode(session.toJson()).length;
      }
      for (var repeatTodo in repeatTodos) {
        estimatedDataSize += jsonEncode(repeatTodo.toJson()).length;
      }
      for (var statData in statisticsData) {
        estimatedDataSize += jsonEncode(statData.toJson()).length;
      }

      // 完成的任务数量
      final completedTodos = todos.where((todo) => todo.isCompleted).length;
      final pendingTodos = todos.length - completedTodos;

      // 番茄钟统计
      final completedPomodoroSessions = pomodoroSessions
          .where((session) => session.isCompleted && !session.isBreak)
          .length;
      final totalFocusTime = pomodoroSessions
          .where((session) => session.isCompleted && !session.isBreak)
          .fold<int>(
            0,
            (total, session) => total + (session.actualDuration ?? 0),
          );

      // 统计数据统计
      final statisticsDataCount = statisticsData.length;

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
        'statisticsData': {'total': statisticsDataCount},
        'storage': {
          'dataSize': estimatedDataSize,
          'backupSize': storageInfo['backupSize'],
          'backupFiles': storageInfo['totalFiles'],
        },
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 获取备份文件列表
  Future<List<Map<String, dynamic>>> getBackupFiles() async {
    try {
      final backupDir = await FileService.getAppDirectory();
      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      final backupFiles = <Map<String, dynamic>>[];
      for (final file in files) {
        final stat = await file.stat();
        backupFiles.add({
          'fileName': file.uri.pathSegments.last,
          'filePath': file.path,
          'fileSize': stat.size,
          'fileDate': stat.modified.toIso8601String(),
        });
      }

      // 按修改时间倒序排列
      backupFiles.sort(
        (a, b) => DateTime.parse(
          b['fileDate'],
        ).compareTo(DateTime.parse(a['fileDate'])),
      );

      return backupFiles;
    } catch (e) {
      return [];
    }
  }

  /// 清理数据
  Future<Map<String, dynamic>> cleanupData({
    bool clearCompleted = false,
    bool clearOldStatistics = false,
    bool clearOldPomodoroSessions = false,
    bool clearBackupFiles = false,
    int daysToKeep = 30,
  }) async {
    try {
      int todosDeleted = 0;
      int statisticsDeleted = 0;
      int pomodoroSessionsDeleted = 0;

      // 清理已完成的任务
      if (clearCompleted) {
        final completedTodos = _hiveService.todosBox.values
            .where((todo) => todo.isCompleted)
            .toList();

        for (var todo in completedTodos) {
          await _hiveService.todosBox.delete(todo.id);
          todosDeleted++;
        }

        // 删除与已删除任务相关的番茄钟会话
        if (completedTodos.isNotEmpty) {
          final completedTodoIds = completedTodos
              .map((todo) => todo.id)
              .toSet();
          final relatedPomodoroSessions = _hiveService.pomodoroBox.values
              .where((session) => completedTodoIds.contains(session.todoId))
              .toList();

          for (var session in relatedPomodoroSessions) {
            await _hiveService.pomodoroBox.delete(session.id);
            pomodoroSessionsDeleted++;
          }

          // 更新统计数据：减少已完成任务数量
          final statistics = _hiveService.statisticsBox.values.toList();
          for (var stat in statistics) {
            if (stat.tasksCompleted > 0) {
              final completedOnThisDate = completedTodos
                  .where(
                    (todo) =>
                        todo.completedAt != null &&
                        _isSameDay(todo.completedAt!, stat.date),
                  )
                  .length;

              if (completedOnThisDate > 0) {
                stat.tasksCompleted =
                    (stat.tasksCompleted - completedOnThisDate).clamp(
                      0,
                      stat.tasksCompleted,
                    );
                // 重新计算完成率
                if (stat.tasksCreated > 0) {
                  stat.completionRate =
                      (stat.tasksCompleted / stat.tasksCreated) * 100;
                } else {
                  stat.completionRate = 0.0;
                }
                await stat.save();
              }
            }
          }
        }
      }

      // 清理旧的统计数据
      if (clearOldStatistics) {
        final now = tz.TZDateTime.now(tz.local);
        final cutoffDate = now.subtract(Duration(days: daysToKeep));
        final oldStatistics = _hiveService.statisticsBox.values
            .where((stat) => stat.date.isBefore(cutoffDate))
            .toList();

        for (var stat in oldStatistics) {
          await _hiveService.statisticsBox.delete(stat.key);
          statisticsDeleted++;
        }
      }

      // 清理旧的统计数据
      if (clearOldStatistics) {
        final now = tz.TZDateTime.now(tz.local);
        final cutoffDate = now.subtract(Duration(days: daysToKeep));
        final oldStatisticsData = _hiveService.statisticsDataBox.values
            .where((sd) => sd.date.isBefore(cutoffDate))
            .toList();

        for (var statData in oldStatisticsData) {
          await _hiveService.statisticsDataBox.delete(statData.id);
          statisticsDeleted++;
        }
      }

      // 清理旧的番茄钟会话
      if (clearOldPomodoroSessions) {
        final now = tz.TZDateTime.now(tz.local);
        final cutoffDate = now.subtract(Duration(days: daysToKeep));
        final oldPomodoroSessions = _hiveService.pomodoroBox.values
            .where((session) => session.startTime.isBefore(cutoffDate))
            .toList();

        for (var session in oldPomodoroSessions) {
          await _hiveService.pomodoroBox.delete(session.id);
          pomodoroSessionsDeleted++;
        }
      }

      // 清理备份文件
      int backupFilesDeleted = 0;
      if (clearBackupFiles) {
        final backupFiles = await getBackupFiles();
        for (final file in backupFiles) {
          try {
            final backupFile = File(file['filePath']);
            if (await backupFile.exists()) {
              await backupFile.delete();
              backupFilesDeleted++;
            }
          } catch (e) {
            // 继续删除其他文件，忽略单个文件的错误
          }
        }
      }

      // 压缩数据库（Hive会自动处理）
      await _hiveService.todosBox.compact();
      await _hiveService.statisticsBox.compact();
      await _hiveService.pomodoroBox.compact();
      await _hiveService.repeatTodosBox.compact();
      await _hiveService.statisticsDataBox.compact();

      // 如果删除了大量数据，建议重新打开数据库以释放更多空间
      if (todosDeleted > 10 ||
          statisticsDeleted > 10 ||
          pomodoroSessionsDeleted > 10) {
        try {
          // 重新初始化Hive boxes以确保彻底清理
          await _hiveService.reinitializeBoxes();
        } catch (e) {
          // 忽略重新初始化的错误，不影响主要功能
        }
      }

      return {
        'success': true,
        'todosDeleted': todosDeleted,
        'statisticsDeleted': statisticsDeleted,
        'pomodoroSessionsDeleted': pomodoroSessionsDeleted,
        'backupFilesDeleted': backupFilesDeleted,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
