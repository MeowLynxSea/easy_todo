import 'dart:typed_data';

import 'package:easy_todo/models/todo_attachment_model.dart';
import 'package:easy_todo/services/attachment_storage_service.dart';

class AttachmentReadService {
  static const int _defaultChunkSizeBytes = 256 * 1024;

  final AttachmentStorageService _attachmentStorage;

  AttachmentReadService({AttachmentStorageService? attachmentStorage})
    : _attachmentStorage = attachmentStorage ?? AttachmentStorageService();

  Future<Uint8List> readAllBytes(TodoAttachmentModel attachment) async {
    final path = attachment.localPath;
    if (path == null || path.trim().isEmpty) {
      throw StateError('Missing localPath');
    }

    final chunkSize = attachment.chunkSize > 0
        ? attachment.chunkSize
        : _defaultChunkSizeBytes;
    final chunkCount = attachment.chunkCount;
    final size = attachment.size;

    if (chunkCount <= 0) {
      return Uint8List(0);
    }

    final builder = BytesBuilder(copy: false);
    for (var i = 0; i < chunkCount; i++) {
      final offset = i * chunkSize;
      final length = (size - offset).clamp(0, chunkSize).toInt();
      final chunk = await _attachmentStorage.readChunk(
        filePath: path,
        offset: offset,
        length: length,
      );
      builder.add(chunk);
    }
    return builder.toBytes();
  }
}
