import 'dart:io';
import 'dart:typed_data';

import 'package:easy_todo/adapters/device_settings_model_adapter.dart';
import 'package:easy_todo/adapters/repeat_type_adapter.dart';
import 'package:easy_todo/adapters/statistics_mode_adapter.dart';
import 'package:easy_todo/adapters/sync_meta_adapter.dart';
import 'package:easy_todo/adapters/sync_outbox_item_adapter.dart';
import 'package:easy_todo/adapters/sync_state_adapter.dart';
import 'package:easy_todo/adapters/time_of_day_adapter.dart';
import 'package:easy_todo/adapters/user_preferences_model_adapter.dart';
import 'package:easy_todo/models/ai_settings_model.dart';
import 'package:easy_todo/models/app_settings_model.dart';
import 'package:easy_todo/models/device_settings_model.dart';
import 'package:easy_todo/models/notification_settings_model.dart';
import 'package:easy_todo/models/pomodoro_model.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/models/statistics_data_model.dart';
import 'package:easy_todo/models/statistics_model.dart';
import 'package:easy_todo/models/sync_meta.dart';
import 'package:easy_todo/models/sync_outbox_item.dart';
import 'package:easy_todo/models/sync_state.dart';
import 'package:easy_todo/models/todo_attachment_model.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/models/user_preferences_model.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/services/repositories/ai_settings_repository.dart';
import 'package:easy_todo/services/repositories/user_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    tempDir = await Directory.systemTemp.createTemp(
      'easy_todo_clear_all_data_test_',
    );
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(TimeOfDayAdapter().typeId)) {
      Hive.registerAdapter(TimeOfDayAdapter());
    }
    if (!Hive.isAdapterRegistered(RepeatTypeAdapter().typeId)) {
      Hive.registerAdapter(RepeatTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(StatisticsModeAdapter().typeId)) {
      Hive.registerAdapter(StatisticsModeAdapter());
    }
    if (!Hive.isAdapterRegistered(DeviceSettingsModelAdapter().typeId)) {
      Hive.registerAdapter(DeviceSettingsModelAdapter());
    }
    if (!Hive.isAdapterRegistered(UserPreferencesModelAdapter().typeId)) {
      Hive.registerAdapter(UserPreferencesModelAdapter());
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

    // Generated adapters (typeId values are declared on the models).
    if (!Hive.isAdapterRegistered(TodoModelAdapter().typeId)) {
      Hive.registerAdapter(TodoModelAdapter());
    }
    if (!Hive.isAdapterRegistered(StatisticsModelAdapter().typeId)) {
      Hive.registerAdapter(StatisticsModelAdapter());
    }
    if (!Hive.isAdapterRegistered(NotificationSettingsModelAdapter().typeId)) {
      Hive.registerAdapter(NotificationSettingsModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppSettingsModelAdapter().typeId)) {
      Hive.registerAdapter(AppSettingsModelAdapter());
    }
    if (!Hive.isAdapterRegistered(PomodoroModelAdapter().typeId)) {
      Hive.registerAdapter(PomodoroModelAdapter());
    }
    if (!Hive.isAdapterRegistered(RepeatTodoModelAdapter().typeId)) {
      Hive.registerAdapter(RepeatTodoModelAdapter());
    }
    if (!Hive.isAdapterRegistered(StatisticsDataModelAdapter().typeId)) {
      Hive.registerAdapter(StatisticsDataModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AISettingsModelAdapter().typeId)) {
      Hive.registerAdapter(AISettingsModelAdapter());
    }
    if (!Hive.isAdapterRegistered(TodoAttachmentModelAdapter().typeId)) {
      Hive.registerAdapter(TodoAttachmentModelAdapter());
    }

    await Hive.openBox<TodoModel>('todos');
    await Hive.openBox<TodoAttachmentModel>('todoAttachments');
    await Hive.openBox<Uint8List>('todoAttachmentChunks');
    await Hive.openBox<StatisticsModel>('statistics');
    await Hive.openBox<NotificationSettingsModel>('notificationSettings');
    await Hive.openBox<AppSettingsModel>('appSettings');
    await Hive.openBox<DeviceSettingsModel>('deviceSettings');
    await Hive.openBox<UserPreferencesModel>('userPreferences');
    await Hive.openBox<PomodoroModel>('pomodoro');
    await Hive.openBox<dynamic>('pomodoroSettings');
    await Hive.openBox<RepeatTodoModel>('repeatTodos');
    await Hive.openBox<StatisticsDataModel>('statisticsData');
    await Hive.openBox<AISettingsModel>('aiSettings');

    await Hive.openBox<SyncState>('sync_state_box');
    await Hive.openBox<SyncMeta>('sync_meta_box');
    await Hive.openBox<SyncOutboxItem>('sync_outbox_box');

    await Hive.openBox('todo_cache');
    await Hive.openBox('stats_cache');
    await Hive.openBox<String>('ai_cache');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_language': 'en',
      'app_theme': 1,
      'theme_colors': 'primary:4278255360',
      'custom_theme': 'secondary:4294901760',
      'todo_status_filter': 2,
      'todo_time_filter': 3,
      'todo_sort_order': 4,
      'todo_selected_categories': 'Work,Personal',
      'last_daily_summary_date': DateTime(2025, 1, 1).toIso8601String(),
    });

    await Hive.box<TodoModel>('todos').clear();
    await Hive.box<TodoAttachmentModel>('todoAttachments').clear();
    await Hive.box<Uint8List>('todoAttachmentChunks').clear();
    await Hive.box<StatisticsModel>('statistics').clear();
    await Hive.box<NotificationSettingsModel>('notificationSettings').clear();
    await Hive.box<AppSettingsModel>('appSettings').clear();
    await Hive.box<DeviceSettingsModel>('deviceSettings').clear();
    await Hive.box<UserPreferencesModel>('userPreferences').clear();
    await Hive.box<PomodoroModel>('pomodoro').clear();
    await Hive.box<dynamic>('pomodoroSettings').clear();
    await Hive.box<RepeatTodoModel>('repeatTodos').clear();
    await Hive.box<StatisticsDataModel>('statisticsData').clear();
    await Hive.box<AISettingsModel>('aiSettings').clear();

    await Hive.box<SyncState>('sync_state_box').clear();
    await Hive.box<SyncMeta>('sync_meta_box').clear();
    await Hive.box<SyncOutboxItem>('sync_outbox_box').clear();

    await Hive.box('todo_cache').clear();
    await Hive.box('stats_cache').clear();
    await Hive.box<String>('ai_cache').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test(
    'TodoProvider.clearAllData clears todos, attachments, settings and caches',
    () async {
      final todosBox = Hive.box<TodoModel>('todos');
      final attachmentsBox = Hive.box<TodoAttachmentModel>('todoAttachments');
      final chunksBox = Hive.box<Uint8List>('todoAttachmentChunks');
      final statisticsBox = Hive.box<StatisticsModel>('statistics');
      final repeatTodosBox = Hive.box<RepeatTodoModel>('repeatTodos');
      final statisticsDataBox = Hive.box<StatisticsDataModel>('statisticsData');
      final pomodoroBox = Hive.box<PomodoroModel>('pomodoro');
      final notificationSettingsBox = Hive.box<NotificationSettingsModel>(
        'notificationSettings',
      );
      final appSettingsBox = Hive.box<AppSettingsModel>('appSettings');
      final deviceSettingsBox = Hive.box<DeviceSettingsModel>('deviceSettings');
      final pomodoroSettingsBox = Hive.box<dynamic>('pomodoroSettings');
      final userPreferencesBox = Hive.box<UserPreferencesModel>(
        'userPreferences',
      );
      final aiSettingsBox = Hive.box<AISettingsModel>('aiSettings');
      final aiCacheBox = Hive.box<String>('ai_cache');
      final todoCacheBox = Hive.box('todo_cache');
      final statsCacheBox = Hive.box('stats_cache');

      final todo1 = TodoModel(
        id: 't_1',
        title: 'Todo 1',
        description: null,
        isCompleted: false,
        createdAt: DateTime(2025, 1, 1, 9),
        order: 0,
        reminderEnabled: false,
      );
      final todo2 = TodoModel(
        id: 't_2',
        title: 'Todo 2',
        description: 'd',
        isCompleted: true,
        createdAt: DateTime(2025, 1, 1, 10),
        completedAt: DateTime(2025, 1, 1, 11),
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
          completionRate: 50,
        ),
      );

      final repeatTodo = RepeatTodoModel(
        id: 'rt_1',
        title: 'Repeat',
        repeatType: RepeatType.daily,
        createdAt: DateTime(2025, 1, 1),
        lastGeneratedDate: DateTime(2025, 1, 1, 9),
        aiCategory: null,
        aiPriority: 0,
        aiProcessed: false,
        startTimeMinutes: 0,
        endTimeMinutes: 0,
      );
      await repeatTodosBox.put(repeatTodo.id, repeatTodo);

      final statisticsData = StatisticsDataModel(
        id: 'sd_1',
        repeatTodoId: repeatTodo.id,
        todoId: todo1.id,
        value: 1,
        unit: 'kg',
        date: DateTime(2025, 1, 1),
        createdAt: DateTime(2025, 1, 1, 12),
        todoCreatedAt: todo1.createdAt,
      );
      await statisticsDataBox.put(statisticsData.id, statisticsData);

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

      final attachmentFile = File(
        '${tempDir.path}${Platform.pathSeparator}a.bin',
      );
      await attachmentFile.writeAsBytes(<int>[1, 2, 3]);
      final stagingFile = File('${attachmentFile.path}.part');
      await stagingFile.writeAsBytes(<int>[4, 5, 6]);

      final attachment = TodoAttachmentModel(
        id: 'a_1',
        todoId: todo1.id,
        fileName: 'a.bin',
        mimeType: 'application/octet-stream',
        size: 3,
        sha256B64: 'sha',
        chunkSize: 3,
        chunkCount: 1,
        createdAtMsUtc: DateTime(2025, 1, 1).toUtc().millisecondsSinceEpoch,
        localPath: attachmentFile.path,
      );
      await attachmentsBox.put(attachment.id, attachment);
      await chunksBox.put('random_chunk', Uint8List.fromList(<int>[7, 8, 9]));

      await notificationSettingsBox.put(
        'notificationSettings',
        NotificationSettingsModel.create(dailySummaryEnabled: false),
      );
      await appSettingsBox.put(
        'appSettings',
        AppSettingsModel.create().copyWith(viewMode: 'stacking'),
      );
      await deviceSettingsBox.put(
        'deviceSettings',
        DeviceSettingsModel.create().copyWith(biometricLockEnabled: true),
      );
      await pomodoroSettingsBox.put('pomodoroSettings', <String, Object>{
        'workDuration': 10,
        'breakDuration': 20,
        'longBreakDuration': 30,
        'sessionsUntilLongBreak': 2,
      });
      await userPreferencesBox.put(
        UserPreferencesRepository.hiveKey,
        UserPreferencesModel.create().copyWith(languageCode: 'en'),
      );
      await aiSettingsBox.put(
        AISettingsRepository.hiveKey,
        AISettingsModel.create()..enableAIFeatures = true,
      );

      await aiCacheBox.put('k', 'v');
      await todoCacheBox.put('k', 'v');
      await statsCacheBox.put('k', 'v');

      final provider = TodoProvider();
      await provider.clearAllData();

      expect(todosBox.isEmpty, isTrue);
      expect(statisticsBox.isEmpty, isTrue);
      expect(repeatTodosBox.isEmpty, isTrue);
      expect(statisticsDataBox.isEmpty, isTrue);
      expect(pomodoroBox.isEmpty, isTrue);

      expect(attachmentsBox.isEmpty, isTrue);
      expect(chunksBox.isEmpty, isTrue);
      expect(await attachmentFile.exists(), isFalse);
      expect(await stagingFile.exists(), isFalse);

      expect(notificationSettingsBox.isEmpty, isTrue);
      expect(appSettingsBox.isEmpty, isTrue);
      expect(deviceSettingsBox.isEmpty, isTrue);
      expect(pomodoroSettingsBox.isEmpty, isTrue);

      final prefs = userPreferencesBox.get(UserPreferencesRepository.hiveKey);
      expect(prefs, isNotNull);
      expect(prefs!.toJson(), UserPreferencesModel.create().toJson());

      final aiSettings = aiSettingsBox.get(AISettingsRepository.hiveKey);
      expect(aiSettings, isNotNull);
      expect(aiSettings!.toJson(), AISettingsModel.create().toJson());

      expect(aiCacheBox.isEmpty, isTrue);
      expect(todoCacheBox.isEmpty, isTrue);
      expect(statsCacheBox.isEmpty, isTrue);

      final sp = await SharedPreferences.getInstance();
      expect(sp.getString('app_language'), isNull);
      expect(sp.getInt('app_theme'), isNull);
      expect(sp.getString('todo_selected_categories'), isNull);
      expect(sp.getString('last_daily_summary_date'), isNull);
    },
  );
}
