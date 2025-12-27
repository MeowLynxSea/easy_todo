import 'dart:convert';
import 'dart:math';

String generateUrlSafeRandomId({int byteLength = 16}) {
  final random = Random.secure();
  final bytes = List<int>.generate(byteLength, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}
