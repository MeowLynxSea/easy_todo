import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/models/statistics_model.dart';
import 'package:easy_todo/models/notification_settings_model.dart';
import 'package:easy_todo/models/app_settings_model.dart';
import 'package:easy_todo/models/device_settings_model.dart';
import 'package:easy_todo/models/pomodoro_model.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/models/statistics_data_model.dart';
import 'package:easy_todo/models/ai_settings_model.dart';
import 'package:easy_todo/models/todo_attachment_model.dart';
import 'package:easy_todo/models/user_preferences_model.dart';
import 'package:easy_todo/adapters/time_of_day_adapter.dart';
import 'package:easy_todo/adapters/repeat_type_adapter.dart';
import 'package:easy_todo/adapters/statistics_mode_adapter.dart';
import 'package:easy_todo/adapters/device_settings_model_adapter.dart';
import 'package:easy_todo/adapters/sync_meta_adapter.dart';
import 'package:easy_todo/adapters/sync_outbox_item_adapter.dart';
import 'package:easy_todo/adapters/sync_state_adapter.dart';
import 'package:easy_todo/adapters/user_preferences_model_adapter.dart';
import 'package:easy_todo/models/sync_meta.dart';
import 'package:easy_todo/models/sync_outbox_item.dart';
import 'package:easy_todo/models/sync_state.dart';
import 'package:easy_todo/services/cache_service.dart';

class HiveService {
  static const String _todosBoxName = 'todos';
  static const String _todoAttachmentsBoxName = 'todoAttachments';
  static const String _todoAttachmentChunksBoxName = 'todoAttachmentChunks';
  static const String _statisticsBoxName = 'statistics';
  static const String _notificationSettingsBoxName = 'notificationSettings';
  static const String _appSettingsBoxName = 'appSettings';
  static const String _deviceSettingsBoxName = 'deviceSettings';
  static const String _userPreferencesBoxName = 'userPreferences';
  static const String _pomodoroBoxName = 'pomodoro';
  static const String _pomodoroSettingsBoxName = 'pomodoroSettings';
  static const String _repeatTodosBoxName = 'repeatTodos';
  static const String _statisticsDataBoxName = 'statisticsData';
  static const String aiSettingsBoxName = 'aiSettings';

  static const String _syncStateBoxName = 'sync_state_box';
  static const String _syncMetaBoxName = 'sync_meta_box';
  static const String _syncOutboxBoxName = 'sync_outbox_box';

  static Future<void> init() async {
    try {
      await Hive.initFlutter();

      // Register adapters with error handling
      try {
        Hive.registerAdapter(TimeOfDayAdapter());
        Hive.registerAdapter(RepeatTypeAdapter());
        Hive.registerAdapter(StatisticsModeAdapter());
        Hive.registerAdapter(TodoModelAdapter());
        Hive.registerAdapter(StatisticsModelAdapter());
        Hive.registerAdapter(NotificationSettingsModelAdapter());
        Hive.registerAdapter(AppSettingsModelAdapter());
        Hive.registerAdapter(DeviceSettingsModelAdapter());
        Hive.registerAdapter(UserPreferencesModelAdapter());
        Hive.registerAdapter(PomodoroModelAdapter());
        Hive.registerAdapter(RepeatTodoModelAdapter());
        Hive.registerAdapter(StatisticsDataModelAdapter());
        Hive.registerAdapter(AISettingsModelAdapter());
        Hive.registerAdapter(TodoAttachmentModelAdapter());
        Hive.registerAdapter(SyncStateAdapter());
        Hive.registerAdapter(SyncMetaAdapter());
        Hive.registerAdapter(SyncOutboxItemAdapter());
        // debugPrint('All Hive adapters registered successfully');
      } catch (e) {
        debugPrint('Error registering Hive adapters: $e');
        rethrow;
      }

      // Open boxes with error handling
      try {
        await Hive.openBox<TodoModel>(_todosBoxName);
        await Hive.openBox<TodoAttachmentModel>(_todoAttachmentsBoxName);
        await Hive.openBox<Uint8List>(_todoAttachmentChunksBoxName);
        await Hive.openBox<StatisticsModel>(_statisticsBoxName);
        await Hive.openBox<NotificationSettingsModel>(
          _notificationSettingsBoxName,
        );
        await Hive.openBox<AppSettingsModel>(_appSettingsBoxName);
        await Hive.openBox<DeviceSettingsModel>(_deviceSettingsBoxName);
        await Hive.openBox<UserPreferencesModel>(_userPreferencesBoxName);
        await Hive.openBox<PomodoroModel>(_pomodoroBoxName);
        await Hive.openBox<dynamic>(_pomodoroSettingsBoxName);
        await Hive.openBox<RepeatTodoModel>(_repeatTodosBoxName);
        await Hive.openBox<StatisticsDataModel>(_statisticsDataBoxName);

        // Normalize legacy Hive keys to use the model's `id` as the box key.
        // Older versions might have used auto-increment keys, which breaks sync
        // since sync recordId expects `box.get(recordId)` to work.
        try {
          await _normalizeBoxKeysById<TodoModel>(
            Hive.box<TodoModel>(_todosBoxName),
            (t) => t.id,
          );
          await _normalizeBoxKeysById<TodoAttachmentModel>(
            Hive.box<TodoAttachmentModel>(_todoAttachmentsBoxName),
            (t) => t.id,
          );
          await _normalizeBoxKeysById<RepeatTodoModel>(
            Hive.box<RepeatTodoModel>(_repeatTodosBoxName),
            (t) => t.id,
          );
          await _normalizeBoxKeysById<StatisticsDataModel>(
            Hive.box<StatisticsDataModel>(_statisticsDataBoxName),
            (t) => t.id,
          );
          await _normalizeBoxKeysById<PomodoroModel>(
            Hive.box<PomodoroModel>(_pomodoroBoxName),
            (t) => t.id,
          );
        } catch (e) {
          debugPrint('Error normalizing Hive keys: $e');
        }

        await _openOrRecreateBox<SyncState>(_syncStateBoxName);
        await _openOrRecreateBox<SyncMeta>(_syncMetaBoxName);
        await _openOrRecreateBox<SyncOutboxItem>(_syncOutboxBoxName);

        try {
          await Hive.openBox<AISettingsModel>(aiSettingsBoxName);
        } catch (e) {
          debugPrint('Error opening AI settings box: $e');
          // If opening fails due to schema issues, try to recreate the box
          try {
            await Hive.deleteBoxFromDisk(aiSettingsBoxName);
            await Hive.openBox<AISettingsModel>(aiSettingsBoxName);
            debugPrint('AI settings box recreated after error');
          } catch (e2) {
            debugPrint('Failed to recreate AI settings box: $e2');
            // Continue without AI settings - the app should handle this gracefully
            debugPrint('Continuing without AI settings box');
          }
        }

        // debugPrint('All Hive boxes opened successfully');

        // Initialize cache service
        await CacheService.init();
        // debugPrint('Cache service initialized successfully');
      } catch (e) {
        debugPrint('Error opening Hive boxes: $e');
        // If boxes fail to open due to schema issues, try to recover
        await _recoverFromSchemaError();
        rethrow;
      }
    } catch (e) {
      debugPrint('Fatal error initializing Hive: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  static Future<Box<T>> _openOrRecreateBox<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (e) {
      debugPrint('Error opening Hive box $name: $e');
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (deleteError) {
        debugPrint('Error deleting Hive box $name: $deleteError');
      }
      return Hive.openBox<T>(name);
    }
  }

  static Future<void> _normalizeBoxKeysById<T>(
    Box<T> box,
    String Function(T value) getId,
  ) async {
    final keys = box.keys.toList(growable: false);
    for (final key in keys) {
      final value = box.get(key);
      if (value == null) continue;

      final id = getId(value);
      if (id.isEmpty) continue;
      if (key is String && key == id) continue;

      if (box.containsKey(id)) {
        await box.delete(key);
        continue;
      }

      await box.put(id, value);
      await box.delete(key);
    }
  }

  Box<TodoModel> get todosBox => Hive.box<TodoModel>(_todosBoxName);
  Box<TodoAttachmentModel> get todoAttachmentsBox =>
      Hive.box<TodoAttachmentModel>(_todoAttachmentsBoxName);
  Box<Uint8List> get todoAttachmentChunksBox =>
      Hive.box<Uint8List>(_todoAttachmentChunksBoxName);
  Box<StatisticsModel> get statisticsBox =>
      Hive.box<StatisticsModel>(_statisticsBoxName);
  Box<NotificationSettingsModel> get notificationSettingsBox =>
      Hive.box<NotificationSettingsModel>(_notificationSettingsBoxName);
  Box<AppSettingsModel> get appSettingsBox =>
      Hive.box<AppSettingsModel>(_appSettingsBoxName);
  Box<DeviceSettingsModel> get deviceSettingsBox =>
      Hive.box<DeviceSettingsModel>(_deviceSettingsBoxName);
  Box<UserPreferencesModel> get userPreferencesBox =>
      Hive.box<UserPreferencesModel>(_userPreferencesBoxName);
  Box<PomodoroModel> get pomodoroBox =>
      Hive.box<PomodoroModel>(_pomodoroBoxName);
  Box<dynamic> get pomodoroSettingsBox =>
      Hive.box<dynamic>(_pomodoroSettingsBoxName);
  Box<RepeatTodoModel> get repeatTodosBox =>
      Hive.box<RepeatTodoModel>(_repeatTodosBoxName);
  Box<StatisticsDataModel> get statisticsDataBox =>
      Hive.box<StatisticsDataModel>(_statisticsDataBoxName);
  Box<AISettingsModel> get aiSettingsBox =>
      Hive.box<AISettingsModel>(aiSettingsBoxName);

  Box<SyncState> get syncStateBox => Hive.box<SyncState>(_syncStateBoxName);
  Box<SyncMeta> get syncMetaBox => Hive.box<SyncMeta>(_syncMetaBoxName);
  Box<SyncOutboxItem> get syncOutboxBox =>
      Hive.box<SyncOutboxItem>(_syncOutboxBoxName);

  /// Recover from schema errors by attempting to migrate data
  static Future<void> _recoverFromSchemaError() async {
    try {
      debugPrint('Attempting to recover from schema error...');

      // First, handle AI settings which might be causing the current issue
      await _handleAISettingsRecovery();

      // Try to backup existing data before clearing
      final repeatTodosBackup = <RepeatTodoModel>[];
      final statisticsDataBackup = <StatisticsDataModel>[];

      try {
        // Try to read existing data before clearing
        final repeatBox = await Hive.openBox<dynamic>(_repeatTodosBoxName);
        final statsBox = await Hive.openBox<dynamic>(_statisticsDataBoxName);

        // Backup data if possible
        for (var key in repeatBox.keys) {
          try {
            final value = repeatBox.get(key);
            if (value != null) {
              // Try to convert to proper model if possible
              repeatTodosBackup.add(value as RepeatTodoModel);
            }
          } catch (e) {
            debugPrint('Could not backup repeat todo $key: $e');
          }
        }

        for (var key in statsBox.keys) {
          try {
            final value = statsBox.get(key);
            if (value != null) {
              statisticsDataBackup.add(value as StatisticsDataModel);
            }
          } catch (e) {
            debugPrint('Could not backup statistics data $key: $e');
          }
        }

        await repeatBox.close();
        await statsBox.close();

        debugPrint(
          'Backed up ${repeatTodosBackup.length} repeat todos and ${statisticsDataBackup.length} statistics data',
        );
      } catch (e) {
        debugPrint('Could not backup data: $e');
      }

      // Clear the problematic boxes
      await Hive.deleteBoxFromDisk(_repeatTodosBoxName);
      await Hive.deleteBoxFromDisk(_statisticsDataBoxName);

      // Reopen the boxes
      await Hive.openBox<RepeatTodoModel>(_repeatTodosBoxName);
      await Hive.openBox<StatisticsDataModel>(_statisticsDataBoxName);

      // Restore backed up data if possible
      if (repeatTodosBackup.isNotEmpty) {
        final restoredBox = Hive.box<RepeatTodoModel>(_repeatTodosBoxName);
        for (final todo in repeatTodosBackup) {
          try {
            await restoredBox.put(todo.id, todo);
          } catch (e) {
            debugPrint('Could not restore repeat todo ${todo.id}: $e');
          }
        }
        debugPrint('Restored ${repeatTodosBackup.length} repeat todos');
      }

      if (statisticsDataBackup.isNotEmpty) {
        final restoredBox = Hive.box<StatisticsDataModel>(
          _statisticsDataBoxName,
        );
        for (final data in statisticsDataBackup) {
          try {
            await restoredBox.put(data.id, data);
          } catch (e) {
            debugPrint('Could not restore statistics data ${data.id}: $e');
          }
        }
        debugPrint('Restored ${statisticsDataBackup.length} statistics data');
      }

      debugPrint('Schema recovery completed');
    } catch (e) {
      debugPrint('Error during schema recovery: $e');
      // As a last resort, clear the boxes to allow the app to continue
      await Hive.deleteBoxFromDisk(_repeatTodosBoxName);
      await Hive.deleteBoxFromDisk(_statisticsDataBoxName);
      await Hive.openBox<RepeatTodoModel>(_repeatTodosBoxName);
      await Hive.openBox<StatisticsDataModel>(_statisticsDataBoxName);
    }
  }

  /// Handle AI settings recovery when schema changes occur
  static Future<void> _handleAISettingsRecovery() async {
    try {
      debugPrint('Attempting to recover AI settings...');

      // Try to delete and recreate the AI settings box
      await Hive.deleteBoxFromDisk(aiSettingsBoxName);
      debugPrint('AI settings box deleted and recreated');

      // Create a new default AI settings
      final newBox = await Hive.openBox<AISettingsModel>(aiSettingsBoxName);
      final defaultSettings = AISettingsModel.create();
      await newBox.put('settings', defaultSettings);
      debugPrint('Default AI settings created');
    } catch (e) {
      debugPrint('Error recovering AI settings: $e');
      // As a last resort, try to continue without AI settings
      try {
        await Hive.deleteBoxFromDisk(aiSettingsBoxName);
        await Hive.openBox<AISettingsModel>(aiSettingsBoxName);
      } catch (e2) {
        debugPrint('Failed to recover AI settings: $e2');
      }
    }
  }

  /// Migration method to handle schema changes across all boxes
  static Future<void> _migrateBoxesForSchemaChanges() async {
    try {
      // Migrate RepeatTodoModel box
      await _migrateRepeatTodoBox();

      // Migrate StatisticsDataModel box
      await _migrateStatisticsDataBox();

      debugPrint('All box migrations completed');
    } catch (e) {
      debugPrint('Error during box migrations: $e');
    }
  }

  /// Migrate RepeatTodoModel box if needed
  static Future<void> _migrateRepeatTodoBox() async {
    try {
      final box = Hive.box<RepeatTodoModel>(_repeatTodosBoxName);
      if (box.isEmpty) return;

      // Try to read the first item to check for schema issues
      try {
        final firstItem = box.values.first;
        // Try accessing fields that might be missing in old data
        firstItem.statisticsModes;
        // If successful, no migration needed
        return;
      } catch (e) {
        debugPrint('Migrating repeat todo box: clearing old format data');
        await box.clear();
        debugPrint('Repeat todo box migration completed');
      }
    } catch (e) {
      debugPrint('Error during repeat todo migration: $e');
    }
  }

  /// Migrate StatisticsDataModel box if needed
  static Future<void> _migrateStatisticsDataBox() async {
    try {
      final box = Hive.box<StatisticsDataModel>(_statisticsDataBoxName);
      if (box.isEmpty) return;

      // Check if the first item has the todoCreatedAt field
      final firstItem = box.values.first;
      try {
        // Try to access the todoCreatedAt field
        firstItem.todoCreatedAt;
        // If we get here, the field exists, no migration needed
        return;
      } catch (e) {
        // Field doesn't exist, clear the box to start fresh
        debugPrint('Migrating statistics data box: clearing old format data');
        await box.clear();
        debugPrint('Statistics data box migration completed');
      }
    } catch (e) {
      debugPrint('Error during statistics data migration: $e');
    }
  }

  /// 重新初始化Boxes以释放空间
  Future<void> reinitializeBoxes() async {
    try {
      // 关闭现有的boxes
      await Hive.box<TodoModel>(_todosBoxName).close();
      await Hive.box<StatisticsModel>(_statisticsBoxName).close();
      await Hive.box<PomodoroModel>(_pomodoroBoxName).close();
      await Hive.box<RepeatTodoModel>(_repeatTodosBoxName).close();
      await Hive.box<StatisticsDataModel>(_statisticsDataBoxName).close();

      // 重新打开boxes
      await Hive.openBox<TodoModel>(_todosBoxName);
      await Hive.openBox<StatisticsModel>(_statisticsBoxName);
      await Hive.openBox<PomodoroModel>(_pomodoroBoxName);
      await Hive.openBox<RepeatTodoModel>(_repeatTodosBoxName);
      await Hive.openBox<StatisticsDataModel>(_statisticsDataBoxName);

      // Run migration after reinitialization
      await _migrateBoxesForSchemaChanges();
    } catch (e) {
      // 如果重新初始化失败，忽略错误
    }
  }
}
