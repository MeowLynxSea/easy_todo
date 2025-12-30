import 'dart:io';

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
  });
}

