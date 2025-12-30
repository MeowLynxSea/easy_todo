import 'dart:typed_data';

Future<void> downloadBytes(
  Uint8List bytes, {
  required String fileName,
  required String mimeType,
}) {
  throw UnsupportedError('downloadBytes is only supported on web');
}
