import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../web_session_storage_stub.dart'
    if (dart.library.html) '../web_session_storage_html.dart';

class SyncAuthTokens {
  final String accessToken;
  final String? refreshToken;
  final int? expiresAtMsUtc;

  const SyncAuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtMsUtc,
  });
}

class SyncAuthStorage {
  static const _accessTokenKey = 'sync_access_token';
  static const _refreshTokenKey = 'sync_refresh_token';
  static const _expiresAtKey = 'sync_expires_at_ms_utc';

  final FlutterSecureStorage? _secureStorageOverride;
  late final FlutterSecureStorage _secureStorage =
      _secureStorageOverride ?? const FlutterSecureStorage();

  SyncAuthStorage({FlutterSecureStorage? secureStorage})
    : _secureStorageOverride = secureStorage;

  Future<SyncAuthTokens?> read() async {
    if (kIsWeb) {
      final accessToken = getSessionValue(_accessTokenKey);
      if (accessToken == null || accessToken.trim().isEmpty) return null;
      final refreshToken = getSessionValue(_refreshTokenKey);
      final expiresRaw = getSessionValue(_expiresAtKey);
      final expiresAtMsUtc = expiresRaw == null
          ? null
          : int.tryParse(expiresRaw);
      return SyncAuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAtMsUtc: expiresAtMsUtc,
      );
    }

    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    if (accessToken == null || accessToken.trim().isEmpty) return null;
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    final expiresRaw = await _secureStorage.read(key: _expiresAtKey);
    final expiresAtMsUtc = expiresRaw == null ? null : int.tryParse(expiresRaw);
    return SyncAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAtMsUtc: expiresAtMsUtc,
    );
  }

  Future<void> write(SyncAuthTokens tokens) async {
    if (kIsWeb) {
      setSessionValue(_accessTokenKey, tokens.accessToken);
      if (tokens.refreshToken != null) {
        setSessionValue(_refreshTokenKey, tokens.refreshToken!);
      }
      if (tokens.expiresAtMsUtc != null) {
        setSessionValue(_expiresAtKey, tokens.expiresAtMsUtc.toString());
      }
      return;
    }

    await _secureStorage.write(
      key: _accessTokenKey,
      value: tokens.accessToken,
    );
    if (tokens.refreshToken != null) {
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: tokens.refreshToken,
      );
    }
    if (tokens.expiresAtMsUtc != null) {
      await _secureStorage.write(
        key: _expiresAtKey,
        value: tokens.expiresAtMsUtc.toString(),
      );
    }
  }

  Future<void> clear() async {
    if (kIsWeb) {
      removeSessionValue(_accessTokenKey);
      removeSessionValue(_refreshTokenKey);
      removeSessionValue(_expiresAtKey);
      return;
    }

    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _expiresAtKey);
  }
}
