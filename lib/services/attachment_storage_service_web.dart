import 'dart:typed_data';

import 'package:easy_todo/services/hive_service.dart';

class AttachmentStorageService {
  final HiveService _hiveService;
  static const String _stagingSuffix = '.part';

  AttachmentStorageService({HiveService? hiveService})
    : _hiveService = hiveService ?? HiveService();

  String _chunkKey(String filePath, int offset) => '$filePath:$offset';

  Future<String> buildAttachmentFilePath({
    required String attachmentId,
    required String fileName,
  }) async {
    return attachmentId;
  }

  Future<String> importFile({
    required String sourcePath,
    required String attachmentId,
    required String fileName,
  }) {
    throw UnsupportedError('sourcePath is not supported on web; pass bytes');
  }

  String stagingFilePathFor(String finalFilePath) =>
      '$finalFilePath$_stagingSuffix';

  Future<bool> fileExists(String filePath) async {
    final prefix = '$filePath:';
    return _hiveService.todoAttachmentChunksBox.keys.any(
      (k) => k is String && k.startsWith(prefix),
    );
  }

  Future<void> moveFile({
    required String fromPath,
    required String toPath,
  }) async {
    if (fromPath == toPath) return;

    final fromPrefix = '$fromPath:';
    final toPrefix = '$toPath:';

    final box = _hiveService.todoAttachmentChunksBox;
    final existingToKeys = box.keys
        .whereType<String>()
        .where((k) => k.startsWith(toPrefix))
        .toList(growable: false);
    for (final key in existingToKeys) {
      await box.delete(key);
    }

    final keys = box.keys
        .whereType<String>()
        .where((k) => k.startsWith(fromPrefix))
        .toList(growable: false);

    for (final key in keys) {
      final offset = key.substring(fromPrefix.length);
      final bytes = box.get(key);
      if (bytes == null) continue;
      await box.put('$toPrefix$offset', bytes);
    }
    for (final key in keys) {
      await box.delete(key);
    }
  }

  Future<void> finalizeStagingFile({
    required String stagingFilePath,
    required String finalFilePath,
  }) async {
    if (stagingFilePath == finalFilePath) return;
    await moveFile(fromPath: stagingFilePath, toPath: finalFilePath);
  }

  Future<Uint8List> readChunk({
    required String filePath,
    required int offset,
    required int length,
  }) async {
    final stored = _hiveService.todoAttachmentChunksBox.get(
      _chunkKey(filePath, offset),
    );
    if (stored == null) {
      throw StateError('Missing attachment chunk: $filePath@$offset');
    }
    if (stored.length == length) return stored;
    if (stored.length < length) return stored;
    return Uint8List.fromList(stored.sublist(0, length));
  }

  Future<void> writeChunk({
    required String filePath,
    required int offset,
    required Uint8List bytes,
  }) async {
    await _hiveService.todoAttachmentChunksBox.put(
      _chunkKey(filePath, offset),
      bytes,
    );
  }

  Future<void> deleteFileIfExists(String? filePath) async {
    if (filePath == null || filePath.trim().isEmpty) return;
    final prefix = '$filePath:';
    final box = _hiveService.todoAttachmentChunksBox;
    final keys = box.keys
        .whereType<String>()
        .where((k) => k.startsWith(prefix))
        .toList(growable: false);
    for (final k in keys) {
      await box.delete(k);
    }
  }
}
