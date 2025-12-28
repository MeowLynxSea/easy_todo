import 'sync_auth_storage.dart';
import 'sync_server_auth_service.dart';

class UnsupportedSyncServerAuthService implements SyncServerAuthService {
  @override
  Future<List<String>> listProviders({required String serverUrl}) {
    throw UnsupportedError(
      'Sync server auth is not supported on this platform',
    );
  }

  @override
  Uri buildStartUri({
    required String serverUrl,
    required String provider,
    required String appRedirect,
    required String client,
  }) {
    throw UnsupportedError(
      'Sync server auth is not supported on this platform',
    );
  }

  @override
  Future<SyncAuthTokens?> login({
    required String serverUrl,
    required String provider,
    required String client,
  }) {
    throw UnsupportedError(
      'Sync server auth is not supported on this platform',
    );
  }

  @override
  Future<SyncAuthTokens> exchange({
    required String serverUrl,
    required String ticket,
  }) {
    throw UnsupportedError(
      'Sync server auth is not supported on this platform',
    );
  }

  @override
  Future<SyncAuthTokens> refresh({
    required String serverUrl,
    required String refreshToken,
  }) {
    throw UnsupportedError(
      'Sync server auth is not supported on this platform',
    );
  }

  @override
  Future<void> logout({
    required String serverUrl,
    required String refreshToken,
  }) {
    throw UnsupportedError(
      'Sync server auth is not supported on this platform',
    );
  }
}

SyncServerAuthService createSyncServerAuthServiceImpl() =>
    UnsupportedSyncServerAuthService();
