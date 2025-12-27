import 'dart:convert';
import 'dart:io';

import 'package:easy_todo/adapters/repeat_type_adapter.dart';
import 'package:easy_todo/adapters/statistics_mode_adapter.dart';
import 'package:easy_todo/models/pomodoro_model.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/models/statistics_data_model.dart';
import 'package:easy_todo/models/statistics_model.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/services/backup_restore_service.dart';
import 'package:easy_todo/adapters/sync_meta_adapter.dart';
import 'package:easy_todo/adapters/sync_outbox_item_adapter.dart';
import 'package:easy_todo/adapters/sync_state_adapter.dart';
import 'package:easy_todo/models/sync_meta.dart';
import 'package:easy_todo/models/sync_outbox_item.dart';
import 'package:easy_todo/models/sync_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  group('BackupRestoreService.restoreFromBackupJson', () {
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      tempDir = await Directory.systemTemp.createTemp('easy_todo_hive_test_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(RepeatTypeAdapter().typeId)) {
        Hive.registerAdapter(RepeatTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(StatisticsModeAdapter().typeId)) {
        Hive.registerAdapter(StatisticsModeAdapter());
      }
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TodoModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(StatisticsModelAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(PomodoroModelAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(RepeatTodoModelAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(StatisticsDataModelAdapter());
      }
      if (!Hive.isAdapterRegistered(SyncStateAdapter().typeId)) {
        Hive.registerAdapter(SyncStateAdapter());
      }
      if (!Hive.isAdapterRegistered(SyncMetaAdapter().typeId)) {
        Hive.registerAdapter(SyncMetaAdapter());
      }
      if (!Hive.isAdapterRegistered(SyncOutboxItemAdapter().typeId)) {
        Hive.registerAdapter(SyncOutboxItemAdapter());
      }

      await Hive.openBox<TodoModel>('todos');
      await Hive.openBox<StatisticsModel>('statistics');
      await Hive.openBox<PomodoroModel>('pomodoro');
      await Hive.openBox<RepeatTodoModel>('repeatTodos');
      await Hive.openBox<StatisticsDataModel>('statisticsData');
      await Hive.openBox<SyncState>('sync_state_box');
      await Hive.openBox<SyncMeta>('sync_meta_box');
      await Hive.openBox<SyncOutboxItem>('sync_outbox_box');
    });

    setUp(() async {
      await Hive.box<TodoModel>('todos').clear();
      await Hive.box<StatisticsModel>('statistics').clear();
      await Hive.box<PomodoroModel>('pomodoro').clear();
      await Hive.box<RepeatTodoModel>('repeatTodos').clear();
      await Hive.box<StatisticsDataModel>('statisticsData').clear();
      await Hive.box<SyncState>('sync_state_box').clear();
      await Hive.box<SyncMeta>('sync_meta_box').clear();
      await Hive.box<SyncOutboxItem>('sync_outbox_box').clear();
    });

    tearDownAll(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('rolls back all boxes on restore failure', () async {
      final todosBox = Hive.box<TodoModel>('todos');
      final statisticsBox = Hive.box<StatisticsModel>('statistics');
      final pomodoroBox = Hive.box<PomodoroModel>('pomodoro');
      final repeatTodosBox = Hive.box<RepeatTodoModel>('repeatTodos');
      final statisticsDataBox = Hive.box<StatisticsDataModel>('statisticsData');

      final repeatTodo = RepeatTodoModel(
        id: 'rt_1',
        title: 'Repeat',
        repeatType: RepeatType.daily,
        createdAt: DateTime(2025, 1, 1),
        lastGeneratedDate: DateTime(2025, 1, 1, 9),
        aiCategory: 'Work',
        aiPriority: 80,
        aiProcessed: true,
        startTimeMinutes: 60,
        endTimeMinutes: 120,
      );
      await repeatTodosBox.put(repeatTodo.id, repeatTodo);

      final todo1 = TodoModel(
        id: 't_1',
        title: 'Generated',
        description: 'd',
        isCompleted: false,
        createdAt: DateTime(2025, 1, 1, 9),
        order: 0,
        repeatTodoId: repeatTodo.id,
        isGeneratedFromRepeat: true,
        dataUnit: 'kg',
        aiCategory: repeatTodo.aiCategory,
        aiPriority: repeatTodo.aiPriority,
        aiProcessed: repeatTodo.aiProcessed,
        startTime: DateTime(2025, 1, 1, 1),
        endTime: DateTime(2025, 1, 1, 2),
      );
      final todo2 = TodoModel(
        id: 't_2',
        title: 'Normal',
        description: null,
        isCompleted: true,
        createdAt: DateTime(2025, 1, 2, 10),
        completedAt: DateTime(2025, 1, 2, 11),
        order: 1,
        reminderEnabled: false,
      );
      await todosBox.put(todo1.id, todo1);
      await todosBox.put(todo2.id, todo2);

      await statisticsBox.add(
        StatisticsModel(
          date: DateTime(2025, 1, 1),
          tasksCreated: 2,
          tasksCompleted: 1,
          completionRate: 50.0,
        ),
      );
      final originalStatisticJson = statisticsBox.values.single.toJson();

      final pomodoro = PomodoroModel(
        id: 'p_1',
        todoId: todo1.id,
        duration: 1500,
        actualDuration: 1500,
        startTime: DateTime(2025, 1, 1, 9),
        endTime: DateTime(2025, 1, 1, 9, 25),
        isCompleted: true,
        isBreak: false,
        workDuration: 1500,
        breakDuration: 300,
      );
      await pomodoroBox.put(pomodoro.id, pomodoro);

      final dataPoint = StatisticsDataModel(
        id: 'sd_1',
        repeatTodoId: repeatTodo.id,
        todoId: todo1.id,
        value: 1.5,
        unit: 'kg',
        date: DateTime(2025, 1, 1),
        createdAt: DateTime(2025, 1, 1, 12),
        todoCreatedAt: todo1.createdAt,
      );
      await statisticsDataBox.put(dataPoint.id, dataPoint);

      final badBackupJson = jsonEncode({
        'version': '2.0.0',
        'backupDate': DateTime(2025, 1, 3).toIso8601String(),
        'todos': [
          {
            'title': 'bad',
            'description': null,
            'isCompleted': false,
            'createdAt': DateTime(2025, 1, 3).toIso8601String(),
            'completedAt': null,
            'order': 0,
            'reminderTime': null,
            'reminderEnabled': false,
            'timeSpent': null,
            'repeatTodoId': null,
            'isGeneratedFromRepeat': false,
            'dataValue': null,
            'dataUnit': null,
            'aiCategory': null,
            'aiPriority': 0,
            'aiProcessed': false,
            'startTime': null,
            'endTime': null,
          },
        ],
        'statistics': <Map<String, dynamic>>[],
      });

      final service = BackupRestoreService();
      final result = await service.restoreFromBackupJson(badBackupJson);
      expect(result['success'], isFalse);

      expect(todosBox.length, 2);
      expect(todosBox.get(todo1.id)?.toJson(), todo1.toJson());
      expect(todosBox.get(todo2.id)?.toJson(), todo2.toJson());

      expect(repeatTodosBox.length, 1);
      expect(repeatTodosBox.get(repeatTodo.id)?.toJson(), repeatTodo.toJson());

      expect(statisticsBox.length, 1);
      expect(statisticsBox.values.single.toJson(), originalStatisticJson);

      expect(pomodoroBox.length, 1);
      expect(pomodoroBox.get(pomodoro.id)?.toJson(), pomodoro.toJson());

      expect(statisticsDataBox.length, 1);
      expect(statisticsDataBox.get(dataPoint.id)?.toJson(), dataPoint.toJson());
    });

    test('updates repeatTodo.lastGeneratedDate from generated todos', () async {
      final generatedCreatedAt = DateTime(2025, 1, 5, 9, 30);
      final repeatTodo = RepeatTodoModel(
        id: 'rt_1',
        title: 'Repeat',
        repeatType: RepeatType.daily,
        createdAt: DateTime(2025, 1, 1),
        lastGeneratedDate: null,
        aiCategory: 'Work',
        aiPriority: 80,
        aiProcessed: true,
        startTimeMinutes: 60,
        endTimeMinutes: 120,
      );

      final generatedTodo = TodoModel(
        id: 't_1',
        title: 'Generated',
        description: 'd',
        isCompleted: false,
        createdAt: generatedCreatedAt,
        order: 0,
        repeatTodoId: repeatTodo.id,
        isGeneratedFromRepeat: true,
        dataUnit: 'kg',
        aiCategory: repeatTodo.aiCategory,
        aiPriority: repeatTodo.aiPriority,
        aiProcessed: repeatTodo.aiProcessed,
        startTime: DateTime(2025, 1, 5, 1),
        endTime: DateTime(2025, 1, 5, 2),
      );

      final backupJson = jsonEncode({
        'version': '2.0.0',
        'backupDate': DateTime(2025, 1, 6).toIso8601String(),
        'todos': [generatedTodo.toJson()],
        'statistics': <Map<String, dynamic>>[],
        'repeatTodos': [repeatTodo.toJson()],
        'pomodoroSessions': <Map<String, dynamic>>[],
        'statisticsData': <Map<String, dynamic>>[],
      });

      final service = BackupRestoreService();
      final result = await service.restoreFromBackupJson(backupJson);
      expect(result['success'], isTrue);

      final restoredRepeatTodo = Hive.box<RepeatTodoModel>(
        'repeatTodos',
      ).get(repeatTodo.id);
      expect(restoredRepeatTodo, isNotNull);
      expect(restoredRepeatTodo!.lastGeneratedDate, isNotNull);
      expect(
        restoredRepeatTodo.lastGeneratedDate!.isAtSameMomentAs(
          generatedCreatedAt,
        ),
        isTrue,
      );

      final restoredTodo = Hive.box<TodoModel>('todos').get(generatedTodo.id);
      expect(restoredTodo, isNotNull);
      expect(restoredTodo!.repeatTodoId, repeatTodo.id);
      expect(restoredTodo.isGeneratedFromRepeat, isTrue);
      expect(restoredTodo.aiCategory, repeatTodo.aiCategory);
      expect(restoredTodo.aiPriority, repeatTodo.aiPriority);
      expect(restoredTodo.aiProcessed, repeatTodo.aiProcessed);
      expect(restoredTodo.startTime, generatedTodo.startTime);
      expect(restoredTodo.endTime, generatedTodo.endTime);
    });
  });
}
