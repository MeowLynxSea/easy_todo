import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/sync_write_service.dart';

class TodoRepository {
  static const int schemaVersion = 1;

  final HiveService _hiveService;
  final SyncWriteService _syncWriteService;

  TodoRepository({HiveService? hiveService, SyncWriteService? syncWriteService})
    : _hiveService = hiveService ?? HiveService(),
      _syncWriteService = syncWriteService ?? SyncWriteService();

  Future<void> upsert(TodoModel todo) async {
    await _syncWriteService.upsertRecord(
      type: SyncTypes.todo,
      recordId: todo.id,
      schemaVersion: schemaVersion,
      writeBusinessData: () => _hiveService.todosBox.put(todo.id, todo),
    );
  }

  Future<void> tombstone(String todoId) async {
    await _syncWriteService.tombstoneRecord(
      type: SyncTypes.todo,
      recordId: todoId,
      schemaVersion: schemaVersion,
    );
  }
}
