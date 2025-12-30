import 'dart:typed_data';

import 'package:easy_todo/models/todo_attachment_model.dart';
import 'package:easy_todo/services/attachment_storage_service.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/repositories/todo_attachment_repository.dart';
import 'package:easy_todo/services/sync_write_service.dart';
import 'package:easy_todo/utils/base64_utils.dart';
import 'package:easy_todo/utils/random_id.dart';
import 'package:pointycastle/digests/sha256.dart';

class TodoAttachmentService {
  static const int chunkSizeBytes = 256 * 1024;

  final HiveService _hiveService;
  final TodoAttachmentRepository _repository;
  final AttachmentStorageService _storage;

  TodoAttachmentService({
    HiveService? hiveService,
    TodoAttachmentRepository? repository,
    AttachmentStorageService? storage,
  }) : _hiveService = hiveService ?? HiveService(),
       _repository = repository ?? TodoAttachmentRepository(),
       _storage = storage ?? AttachmentStorageService();

  Future<TodoAttachmentModel> addAttachment({
    required String todoId,
    required String fileName,
    String? sourcePath,
    Uint8List? bytes,
    String mimeType = 'application/octet-stream',
  }) async {
    if (bytes == null) {
      throw ArgumentError('bytes is required on web (sourcePath unsupported)');
    }

    final nowMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;
    final attachmentId = generateUrlSafeRandomId(byteLength: 18);
    final localPath = await _storage.buildAttachmentFilePath(
      attachmentId: attachmentId,
      fileName: fileName,
    );

    final size = bytes.length;
    final chunkCount = ((size + chunkSizeBytes - 1) / chunkSizeBytes).floor();
    final sha256B64 = _sha256B64(bytes);

    for (var i = 0; i < chunkCount; i++) {
      final start = i * chunkSizeBytes;
      final end = (start + chunkSizeBytes).clamp(0, size);
      final chunk = Uint8List.fromList(bytes.sublist(start, end));
      await _storage.writeChunk(
        filePath: localPath,
        offset: start,
        bytes: chunk,
      );
    }

    final attachment = TodoAttachmentModel(
      id: attachmentId,
      todoId: todoId,
      fileName: fileName,
      mimeType: mimeType,
      size: size,
      sha256B64: sha256B64,
      chunkSize: chunkSizeBytes,
      chunkCount: chunkCount,
      createdAtMsUtc: nowMsUtc,
      localPath: localPath,
      receivedChunkCount: chunkCount,
      isComplete: true,
    );

    await _repository.upsertAttachment(attachment);
    await _repository.upsertAllChunks(
      attachmentId: attachmentId,
      chunkCount: chunkCount,
    );

    return attachment;
  }

  Future<void> removeAttachment(String attachmentId) async {
    final attachment = _hiveService.todoAttachmentsBox.get(attachmentId);
    final localPath = attachment?.localPath;

    await _repository.tombstoneAttachment(attachmentId);
    // Deleting an attachment should be a single tombstone push. The server
    // performs cascading cleanup/compaction of chunk records.
    //
    // Also drop any in-flight outbox entries for this attachment's chunks or
    // commit marker (e.g. upload in progress) to avoid redundant pushes.
    final outbox = _hiveService.syncOutboxBox;
    final chunkPrefix = '${SyncTypes.todoAttachmentChunk}:$attachmentId:';
    final keys = outbox.keys.whereType<String>().toList(growable: false);
    for (final key in keys) {
      if (key.startsWith(chunkPrefix)) {
        await outbox.delete(key);
      }
    }
    await _hiveService.syncOutboxBox.delete(
      SyncWriteService.metaKeyOf(SyncTypes.todoAttachmentCommit, attachmentId),
    );
    await _storage.deleteFileIfExists(localPath);
    final staging = localPath == null
        ? null
        : _storage.stagingFilePathFor(localPath);
    if (staging != null && staging != localPath) {
      await _storage.deleteFileIfExists(staging);
    }
    await _hiveService.todoAttachmentsBox.delete(attachmentId);
  }

  String _sha256B64(Uint8List bytes) {
    final digest = SHA256Digest();
    digest.update(bytes, 0, bytes.length);
    final out = Uint8List(digest.digestSize);
    digest.doFinal(out, 0);
    return base64UrlNoPadEncode(out);
  }
}
