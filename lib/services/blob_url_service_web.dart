// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

String createObjectUrlFromBytes(Uint8List bytes, {required String mimeType}) {
  final blob = html.Blob(<Object>[bytes], mimeType);
  return html.Url.createObjectUrlFromBlob(blob);
}

void revokeObjectUrl(String url) {
  html.Url.revokeObjectUrl(url);
}
