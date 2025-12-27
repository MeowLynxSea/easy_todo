import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/sync_write_service.dart';

class RepeatTodoRepository {
  static const int schemaVersion = 1;

  final HiveService _hiveService;
  final SyncWriteService _syncWriteService;

  RepeatTodoRepository({
    HiveService? hiveService,
    SyncWriteService? syncWriteService,
  }) : _hiveService = hiveService ?? HiveService(),
       _syncWriteService = syncWriteService ?? SyncWriteService();

  Future<void> upsert(RepeatTodoModel repeatTodo) async {
    await _syncWriteService.upsertRecord(
      type: SyncTypes.repeatTodo,
      recordId: repeatTodo.id,
      schemaVersion: schemaVersion,
      writeBusinessData: () =>
          _hiveService.repeatTodosBox.put(repeatTodo.id, repeatTodo),
    );
  }

  Future<void> tombstone(String repeatTodoId) async {
    await _syncWriteService.tombstoneRecord(
      type: SyncTypes.repeatTodo,
      recordId: repeatTodoId,
      schemaVersion: schemaVersion,
    );
  }
}
