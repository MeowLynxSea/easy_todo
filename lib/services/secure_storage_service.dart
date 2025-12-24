import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _aiApiKeyKey = 'ai_api_key';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> readAiApiKey() => _storage.read(key: _aiApiKeyKey);

  Future<void> writeAiApiKey(String apiKey) =>
      _storage.write(key: _aiApiKeyKey, value: apiKey);

  Future<void> deleteAiApiKey() => _storage.delete(key: _aiApiKeyKey);
}
