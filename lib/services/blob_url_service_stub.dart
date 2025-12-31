import 'dart:typed_data';

String createObjectUrlFromBytes(Uint8List bytes, {required String mimeType}) {
  throw UnsupportedError('Object URLs are only supported on web');
}

void revokeObjectUrl(String url) {
  // No-op on non-web.
}
