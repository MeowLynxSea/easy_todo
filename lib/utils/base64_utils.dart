import 'dart:convert';

String base64UrlNoPadEncode(List<int> bytes) {
  return base64UrlEncode(bytes).replaceAll('=', '');
}

List<int> base64UrlNoPadDecode(String value) {
  var normalized = value.trim();
  final pad = normalized.length % 4;
  if (pad != 0) {
    normalized = normalized.padRight(normalized.length + (4 - pad), '=');
  }
  return base64Url.decode(normalized);
}
