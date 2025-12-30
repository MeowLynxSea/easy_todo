import 'dart:async';
import 'dart:io';

import 'package:easy_todo/models/todo_attachment_model.dart';
import 'package:easy_todo/services/attachment_storage_service.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/repositories/todo_attachment_repository.dart';
import 'package:easy_todo/services/sync_write_service.dart';
import 'package:easy_todo/utils/base64_utils.dart';
import 'package:easy_todo/utils/random_id.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/digests/sha256.dart';

class TodoAttachmentService {
  static const int chunkSizeBytes = 256 * 1024;
  static const int _yieldEveryChunks = 4;

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
    Stream<List<int>>? readStream,
    ValueChanged<double>? onProgress,
    String mimeType = 'application/octet-stream',
  }) async {
    final normalizedSourcePath = sourcePath?.trim();
    if ((normalizedSourcePath == null || normalizedSourcePath.isEmpty) &&
        bytes == null &&
        readStream == null) {
      throw ArgumentError('sourcePath/bytes/readStream is required on IO');
    }

    final nowMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;
    final attachmentId = generateUrlSafeRandomId(byteLength: 18);

    late final String localPath;
    if (normalizedSourcePath != null && normalizedSourcePath.isNotEmpty) {
      localPath = await _storage.importFile(
        sourcePath: normalizedSourcePath,
        attachmentId: attachmentId,
        fileName: fileName,
      );
    } else if (readStream != null) {
      localPath = await _storage.importStream(
        sourceStream: readStream,
        attachmentId: attachmentId,
        fileName: fileName,
      );
    } else {
      localPath = await _storage.importBytes(
        bytes: bytes!,
        attachmentId: attachmentId,
        fileName: fileName,
      );
    }

    final file = File(localPath);
    final size = await file.length();

    final chunkCount = ((size + chunkSizeBytes - 1) / chunkSizeBytes).floor();
    onProgress?.call(0.05);
    final sha256B64 = await _sha256B64(
      file,
      sizeBytes: size,
      onHashProgress: (p) {
        onProgress?.call(0.05 + 0.9 * p);
      },
    );

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

    onProgress?.call(1);
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

  Future<String> _sha256B64(
    File file, {
    required int sizeBytes,
    ValueChanged<double>? onHashProgress,
  }) async {
    final digest = SHA256Digest();
    final raf = await file.open(mode: FileMode.read);
    var readTotal = 0;
    var chunkIndex = 0;
    try {
      while (true) {
        final chunk = await raf.read(chunkSizeBytes);
        if (chunk.isEmpty) break;
        digest.update(chunk, 0, chunk.length);
        readTotal += chunk.length;
        chunkIndex++;
        if (sizeBytes > 0) {
          onHashProgress?.call((readTotal / sizeBytes).clamp(0, 1));
        }
        if (chunkIndex % _yieldEveryChunks == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
    } finally {
      await raf.close();
    }

    onHashProgress?.call(1);
    final out = Uint8List(digest.digestSize);
    digest.doFinal(out, 0);
    return base64UrlNoPadEncode(out);
  }
}
