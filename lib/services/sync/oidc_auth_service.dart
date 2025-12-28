import 'oidc_auth_service_stub.dart'
    if (dart.library.io) 'oidc_auth_service_io.dart';

abstract class OidcAuthService {
  Future<OidcTokens> signIn({required OidcAuthConfig config});

  Future<OidcTokens> refresh({
    required String tokenEndpoint,
    required String clientId,
    required String refreshToken,
  });
}

class OidcAuthConfig {
  final String issuer;
  final String clientId;
  final List<String> scopes;
  final String authorizationEndpoint;
  final String tokenEndpoint;

  const OidcAuthConfig({
    required this.issuer,
    required this.clientId,
    required this.scopes,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
  });
}

class OidcTokens {
  final String accessToken;
  final String? refreshToken;
  final int? expiresAtMsUtc;

  const OidcTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtMsUtc,
  });
}

OidcAuthService createOidcAuthService() => createOidcAuthServiceImpl();
