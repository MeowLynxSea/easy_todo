import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'web_session_storage_stub.dart'
    if (dart.library.html) 'web_session_storage_html.dart' as web_session;

/// Stores DEK bytes for automatic unlock on mobile/desktop.
///
/// Web defaults to in-memory + browser sessionStorage (cleared when the
/// browser/tab session ends).
class DekStorageService {
  static const String _keyPrefix = 'sync_dek_';

  static final Map<String, List<int>> _webSessionDek = <String, List<int>>{};

  final FlutterSecureStorage _storage;

  DekStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> writeDek({required String dekId, required List<int> dek}) async {
    if (kIsWeb) {
      _webSessionDek[dekId] = dek;
      final value = base64UrlEncode(dek).replaceAll('=', '');
      web_session.setSessionValue('$_keyPrefix$dekId', value);
      return;
    }
    final value = base64UrlEncode(dek).replaceAll('=', '');
    await _storage.write(key: '$_keyPrefix$dekId', value: value);
  }

  Future<List<int>?> readDek({required String dekId}) async {
    if (kIsWeb) {
      final cached = _webSessionDek[dekId];
      if (cached != null) return cached;

      final value = web_session.getSessionValue('$_keyPrefix$dekId');
      if (value == null || value.isEmpty) return null;

      var normalized = value;
      final pad = normalized.length % 4;
      if (pad != 0) {
        normalized = normalized.padRight(normalized.length + (4 - pad), '=');
      }
      final decoded = base64Url.decode(normalized);
      _webSessionDek[dekId] = decoded;
      return decoded;
    }
    final value = await _storage.read(key: '$_keyPrefix$dekId');
    if (value == null || value.isEmpty) return null;

    var normalized = value;
    final pad = normalized.length % 4;
    if (pad != 0) {
      normalized = normalized.padRight(normalized.length + (4 - pad), '=');
    }
    return base64Url.decode(normalized);
  }

  Future<void> deleteDek({required String dekId}) async {
    if (kIsWeb) {
      _webSessionDek.remove(dekId);
      web_session.removeSessionValue('$_keyPrefix$dekId');
      return;
    }
    await _storage.delete(key: '$_keyPrefix$dekId');
  }
}
