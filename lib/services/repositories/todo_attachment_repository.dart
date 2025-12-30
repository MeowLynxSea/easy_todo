import 'package:easy_todo/models/todo_attachment_model.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/sync_write_service.dart';
import 'package:easy_todo/utils/todo_attachment_record_id.dart';

class TodoAttachmentRepository {
  // v2 enables server-side staging + commit gating to avoid other devices
  // observing partially uploaded attachments.
  static const int attachmentSchemaVersion = 2;
  static const int chunkSchemaVersion = 2;
  static const int commitSchemaVersion = 1;

  final HiveService _hiveService;
  final SyncWriteService _syncWriteService;

  TodoAttachmentRepository({
    HiveService? hiveService,
    SyncWriteService? syncWriteService,
  }) : _hiveService = hiveService ?? HiveService(),
       _syncWriteService = syncWriteService ?? SyncWriteService();

  Future<void> upsertAttachment(TodoAttachmentModel attachment) async {
    await _syncWriteService.upsertRecord(
      type: SyncTypes.todoAttachment,
      recordId: attachment.id,
      schemaVersion: attachmentSchemaVersion,
      writeBusinessData: () async {
        await _hiveService.todoAttachmentsBox.put(attachment.id, attachment);
      },
    );
  }

  Future<void> tombstoneAttachment(String attachmentId) async {
    await _syncWriteService.tombstoneRecord(
      type: SyncTypes.todoAttachment,
      recordId: attachmentId,
      schemaVersion: attachmentSchemaVersion,
    );
  }

  Future<void> upsertAttachmentCommit(String attachmentId) async {
    await _syncWriteService.upsertRecord(
      type: SyncTypes.todoAttachmentCommit,
      recordId: attachmentId,
      schemaVersion: commitSchemaVersion,
      writeBusinessData: () async {},
    );
  }

  Future<void> tombstoneAttachmentCommit(String attachmentId) async {
    await _syncWriteService.tombstoneRecord(
      type: SyncTypes.todoAttachmentCommit,
      recordId: attachmentId,
      schemaVersion: commitSchemaVersion,
    );
  }

  Future<void> upsertChunk({
    required String attachmentId,
    required int chunkIndex,
  }) async {
    await _syncWriteService.upsertRecord(
      type: SyncTypes.todoAttachmentChunk,
      recordId: TodoAttachmentChunkRecordId.build(attachmentId, chunkIndex),
      schemaVersion: chunkSchemaVersion,
      writeBusinessData: () async {},
    );
  }

  Future<void> tombstoneChunk({
    required String attachmentId,
    required int chunkIndex,
  }) async {
    await _syncWriteService.tombstoneRecord(
      type: SyncTypes.todoAttachmentChunk,
      recordId: TodoAttachmentChunkRecordId.build(attachmentId, chunkIndex),
      schemaVersion: chunkSchemaVersion,
    );
  }

  Future<void> upsertAllChunks({
    required String attachmentId,
    required int chunkCount,
  }) async {
    for (var i = 0; i < chunkCount; i++) {
      await upsertChunk(attachmentId: attachmentId, chunkIndex: i);
    }
  }

  Future<void> tombstoneAllChunks({
    required String attachmentId,
    required int chunkCount,
  }) async {
    for (var i = 0; i < chunkCount; i++) {
      await tombstoneChunk(attachmentId: attachmentId, chunkIndex: i);
    }
  }
}
