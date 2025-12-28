import 'oidc_auth_service.dart';

class UnsupportedOidcAuthService implements OidcAuthService {
  @override
  Future<OidcTokens> signIn({required OidcAuthConfig config}) {
    throw UnsupportedError('OIDC sign-in is not supported on this platform');
  }

  @override
  Future<OidcTokens> refresh({
    required String tokenEndpoint,
    required String clientId,
    required String refreshToken,
  }) {
    throw UnsupportedError('OIDC refresh is not supported on this platform');
  }
}

OidcAuthService createOidcAuthServiceImpl() => UnsupportedOidcAuthService();
