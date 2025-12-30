import 'dart:io';
import 'dart:typed_data';

import 'package:easy_todo/services/attachment_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttachmentStorageService (IO)', () {
    test('stagingFilePathFor appends .part', () {
      final storage = AttachmentStorageService();
      final finalPath =
          '${Directory.systemTemp.path}${Platform.pathSeparator}final.bin';
      expect(storage.stagingFilePathFor(finalPath), '$finalPath.part');
    });

    test('finalizeStagingFile moves staging to final', () async {
      final storage = AttachmentStorageService();
      final dir = await Directory.systemTemp.createTemp(
        'easy_todo_attachment_storage_',
      );
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });

      final finalPath = '${dir.path}${Platform.pathSeparator}final.bin';
      final stagingPath = storage.stagingFilePathFor(finalPath);

      await File(stagingPath).writeAsBytes([1, 2, 3, 4], flush: true);
      expect(await File(stagingPath).exists(), isTrue);
      expect(await File(finalPath).exists(), isFalse);

      await storage.finalizeStagingFile(
        stagingFilePath: stagingPath,
        finalFilePath: finalPath,
      );

      expect(await File(finalPath).exists(), isTrue);
      expect(await File(stagingPath).exists(), isFalse);
      expect(await File(finalPath).readAsBytes(), [1, 2, 3, 4]);
    });

    test('moveFile overwrites destination', () async {
      final storage = AttachmentStorageService();
      final dir = await Directory.systemTemp.createTemp(
        'easy_todo_attachment_storage_',
      );
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });

      final fromPath = '${dir.path}${Platform.pathSeparator}from.bin';
      final toPath = '${dir.path}${Platform.pathSeparator}to.bin';

      await File(fromPath).writeAsBytes([7, 7], flush: true);
      await File(toPath).writeAsBytes([1, 2, 3], flush: true);

      await storage.moveFile(fromPath: fromPath, toPath: toPath);

      expect(await File(fromPath).exists(), isFalse);
      expect(await File(toPath).readAsBytes(), [7, 7]);
    });

    test('importBytes writes into attachments dir', () async {
      final dir = await Directory.systemTemp.createTemp(
        'easy_todo_attachment_storage_',
      );
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });

      final storage = AttachmentStorageService(
        getDocumentsDirectory: () async => dir,
      );
      final path = await storage.importBytes(
        bytes: Uint8List.fromList([1, 2, 3]),
        attachmentId: 'att1',
        fileName: 'hello.txt',
      );

      expect(await File(path).exists(), isTrue);
      expect(await File(path).readAsBytes(), [1, 2, 3]);
      expect(path.contains('${dir.path}${Platform.pathSeparator}'), isTrue);
      expect(path.contains('easy_todo_attachments'), isTrue);
    });

    test('importStream writes into attachments dir', () async {
      final dir = await Directory.systemTemp.createTemp(
        'easy_todo_attachment_storage_',
      );
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });

      final storage = AttachmentStorageService(
        getDocumentsDirectory: () async => dir,
      );
      final path = await storage.importStream(
        sourceStream: Stream<List<int>>.fromIterable([
          [9, 8],
          [7],
        ]),
        attachmentId: 'att2',
        fileName: 'stream.bin',
      );

      expect(await File(path).exists(), isTrue);
      expect(await File(path).readAsBytes(), [9, 8, 7]);
      expect(path.contains('${dir.path}${Platform.pathSeparator}'), isTrue);
      expect(path.contains('easy_todo_attachments'), isTrue);
    });
  });
}
