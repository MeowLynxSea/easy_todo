import 'package:easy_todo/models/pomodoro_model.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/sync_write_service.dart';

class PomodoroRepository {
  static const int schemaVersion = 1;

  final HiveService _hiveService;
  final SyncWriteService _syncWriteService;

  PomodoroRepository({
    HiveService? hiveService,
    SyncWriteService? syncWriteService,
  }) : _hiveService = hiveService ?? HiveService(),
       _syncWriteService = syncWriteService ?? SyncWriteService();

  Future<void> upsert(PomodoroModel session) async {
    await _syncWriteService.upsertRecord(
      type: SyncTypes.pomodoro,
      recordId: session.id,
      schemaVersion: schemaVersion,
      writeBusinessData: () =>
          _hiveService.pomodoroBox.put(session.id, session),
    );
  }

  Future<void> tombstone(String id) async {
    await _syncWriteService.tombstoneRecord(
      type: SyncTypes.pomodoro,
      recordId: id,
      schemaVersion: schemaVersion,
    );
  }
}
