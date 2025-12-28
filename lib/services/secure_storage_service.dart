import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

import 'web_session_storage_stub.dart'
    if (dart.library.html) 'web_session_storage_html.dart'
    as web_session;

class SecureStorageService {
  static const String _aiApiKeyKey = 'ai_api_key';

  final FlutterSecureStorage? _storageOverride;
  late final FlutterSecureStorage _storage =
      _storageOverride ?? const FlutterSecureStorage();

  SecureStorageService({FlutterSecureStorage? storage})
    : _storageOverride = storage;

  Future<String?> readAiApiKey() {
    if (kIsWeb) {
      return Future<String?>.value(web_session.getSessionValue(_aiApiKeyKey));
    }
    return _storage.read(key: _aiApiKeyKey);
  }

  Future<void> writeAiApiKey(String apiKey) {
    if (kIsWeb) {
      web_session.setSessionValue(_aiApiKeyKey, apiKey);
      return Future<void>.value();
    }
    return _storage.write(key: _aiApiKeyKey, value: apiKey);
  }

  Future<void> deleteAiApiKey() {
    if (kIsWeb) {
      web_session.removeSessionValue(_aiApiKeyKey);
      return Future<void>.value();
    }
    return _storage.delete(key: _aiApiKeyKey);
  }
}
