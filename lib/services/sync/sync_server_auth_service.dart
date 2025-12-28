import 'sync_server_auth_service_stub.dart'
    if (dart.library.io) 'sync_server_auth_service_io.dart'
    if (dart.library.html) 'sync_server_auth_service_web.dart';

import 'sync_auth_storage.dart';

abstract class SyncServerAuthService {
  Future<List<String>> listProviders({required String serverUrl});

  Uri buildStartUri({
    required String serverUrl,
    required String provider,
    required String appRedirect,
    required String client,
  });

  Future<SyncAuthTokens?> login({
    required String serverUrl,
    required String provider,
    required String client,
  });

  Future<SyncAuthTokens> exchange({
    required String serverUrl,
    required String ticket,
  });

  Future<SyncAuthTokens> refresh({
    required String serverUrl,
    required String refreshToken,
  });

  Future<void> logout({
    required String serverUrl,
    required String refreshToken,
  });
}

SyncServerAuthService createSyncServerAuthService() =>
    createSyncServerAuthServiceImpl();
