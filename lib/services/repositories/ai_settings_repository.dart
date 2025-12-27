import 'package:easy_todo/models/ai_settings_model.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/sync_write_service.dart';

class AISettingsRepository {
  static const int schemaVersion = 1;
  static const String hiveKey = 'settings';

  final HiveService _hiveService;
  final SyncWriteService _syncWriteService;

  AISettingsRepository({
    HiveService? hiveService,
    SyncWriteService? syncWriteService,
  }) : _hiveService = hiveService ?? HiveService(),
       _syncWriteService = syncWriteService ?? SyncWriteService();

  AISettingsModel loadSync() {
    final box = _hiveService.aiSettingsBox;
    return box.get(hiveKey) ?? AISettingsModel.create();
  }

  Future<AISettingsModel> load() async {
    final box = _hiveService.aiSettingsBox;
    return box.get(hiveKey) ?? AISettingsModel.create();
  }

  Future<void> save(AISettingsModel settings) async {
    await _syncWriteService.upsertRecord(
      type: SyncTypes.aiSettings,
      recordId: SyncRecordIds.singleton,
      schemaVersion: schemaVersion,
      writeBusinessData: () =>
          _hiveService.aiSettingsBox.put(hiveKey, settings),
    );
  }
}
