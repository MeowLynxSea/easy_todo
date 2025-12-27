import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores DEK bytes for automatic unlock on mobile/desktop.
///
/// Web defaults to in-memory (session) storage.
class DekStorageService {
  static const String _keyPrefix = 'sync_dek_';

  static final Map<String, List<int>> _webSessionDek = <String, List<int>>{};

  final FlutterSecureStorage _storage;

  DekStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> writeDek({required String dekId, required List<int> dek}) async {
    if (kIsWeb) {
      _webSessionDek[dekId] = dek;
      return;
    }
    final value = base64UrlEncode(dek).replaceAll('=', '');
    await _storage.write(key: '$_keyPrefix$dekId', value: value);
  }

  Future<List<int>?> readDek({required String dekId}) async {
    if (kIsWeb) {
      return _webSessionDek[dekId];
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
      return;
    }
    await _storage.delete(key: '$_keyPrefix$dekId');
  }
}
