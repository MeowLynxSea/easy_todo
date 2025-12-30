import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class AttachmentStorageService {
  static const String _attachmentsFolder = 'easy_todo_attachments';
  static const String _stagingSuffix = '.part';

  final Future<Directory> Function() _getDocumentsDirectory;

  AttachmentStorageService({
    Future<Directory> Function()? getDocumentsDirectory,
  }) : _getDocumentsDirectory =
           getDocumentsDirectory ?? getApplicationDocumentsDirectory;

  Future<Directory> _ensureAttachmentsDir() async {
    final appDocDir = await _getDocumentsDirectory();
    final dir = Directory(
      '${appDocDir.path}${Platform.pathSeparator}$_attachmentsFolder',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _sanitizeFileName(String fileName) {
    var name = fileName.trim();
    if (name.isEmpty) return 'file';

    name = name.replaceAll(RegExp(r'[\\\\/]+'), '_');
    name = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (name.length > 120) {
      name = name.substring(name.length - 120);
    }
    return name;
  }

  Future<String> buildAttachmentFilePath({
    required String attachmentId,
    required String fileName,
  }) async {
    final dir = await _ensureAttachmentsDir();
    final safeName = _sanitizeFileName(fileName);
    return '${dir.path}${Platform.pathSeparator}${attachmentId}_$safeName';
  }

  Future<String> importFile({
    required String sourcePath,
    required String attachmentId,
    required String fileName,
  }) async {
    final destPath = await buildAttachmentFilePath(
      attachmentId: attachmentId,
      fileName: fileName,
    );
    final source = File(sourcePath);
    final dest = File(destPath);
    if (await dest.exists()) {
      await dest.delete();
    }
    await source.copy(destPath);
    return dest.path;
  }

  Future<String> importBytes({
    required Uint8List bytes,
    required String attachmentId,
    required String fileName,
  }) async {
    final destPath = await buildAttachmentFilePath(
      attachmentId: attachmentId,
      fileName: fileName,
    );
    final dest = File(destPath);
    if (await dest.exists()) {
      await dest.delete();
    }
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  }

  Future<String> importStream({
    required Stream<List<int>> sourceStream,
    required String attachmentId,
    required String fileName,
  }) async {
    final destPath = await buildAttachmentFilePath(
      attachmentId: attachmentId,
      fileName: fileName,
    );
    final dest = File(destPath);
    if (await dest.exists()) {
      await dest.delete();
    }
    final sink = dest.openWrite();
    try {
      await sink.addStream(sourceStream);
    } finally {
      await sink.close();
    }
    return dest.path;
  }

  String stagingFilePathFor(String finalFilePath) => '$finalFilePath$_stagingSuffix';

  Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return file.exists();
  }

  Future<void> moveFile({required String fromPath, required String toPath}) async {
    if (fromPath == toPath) return;

    final from = File(fromPath);
    if (!await from.exists()) {
      throw StateError('Missing file: $fromPath');
    }

    final to = File(toPath);
    if (await to.exists()) {
      await to.delete();
    }

    try {
      await from.rename(toPath);
    } catch (_) {
      await from.copy(toPath);
      await from.delete();
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
    final file = File(filePath);
    final raf = await file.open(mode: FileMode.read);
    try {
      await raf.setPosition(offset);
      final bytes = await raf.read(length);
      return Uint8List.fromList(bytes);
    } finally {
      await raf.close();
    }
  }

  Future<void> writeChunk({
    required String filePath,
    required int offset,
    required Uint8List bytes,
  }) async {
    final file = File(filePath);
    final raf = await file.open(mode: FileMode.writeOnly);
    try {
      await raf.setPosition(offset);
      await raf.writeFrom(bytes);
    } finally {
      await raf.close();
    }
  }

  Future<void> deleteFileIfExists(String? filePath) async {
    if (filePath == null || filePath.trim().isEmpty) return;
    final file = File(filePath);
    if (!await file.exists()) return;
    await file.delete();
  }
}
