import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import 'oidc_auth_service.dart';

class IoOidcAuthService implements OidcAuthService {
  final Dio _dio;

  IoOidcAuthService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
            ),
          );

  @override
  Future<OidcTokens> signIn({required OidcAuthConfig config}) async {
    final codeVerifier = _randomUrlSafeString(64);
    final codeChallenge = await _codeChallengeS256(codeVerifier);
    final state = _randomUrlSafeString(32);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: server.port,
      path: '/callback',
    );

    final completer = Completer<Map<String, String>>();
    late final StreamSubscription<HttpRequest> sub;
    sub = server.listen((request) async {
      final uri = request.uri;
      if (uri.path != '/callback') {
        request.response
          ..statusCode = 404
          ..write('not found');
        await request.response.close();
        return;
      }

      final query = uri.queryParameters;
      final code = query['code'];
      final returnedState = query['state'];

      request.response.headers.contentType = ContentType.html;
      request.response.write(
        '<!doctype html><html><body>You can close this window now.</body></html>',
      );
      await request.response.close();

      if (code == null || returnedState == null) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('missing code/state'));
        }
        await sub.cancel();
        await server.close(force: true);
        return;
      }

      if (returnedState != state) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('state mismatch'));
        }
        await sub.cancel();
        await server.close(force: true);
        return;
      }

      if (!completer.isCompleted) {
        completer.complete(query);
      }
      await sub.cancel();
      await server.close(force: true);
    });

    final authorizeUri = Uri.parse(config.authorizationEndpoint).replace(
      queryParameters: <String, String>{
        'response_type': 'code',
        'client_id': config.clientId,
        'redirect_uri': redirectUri.toString(),
        'scope': config.scopes.join(' '),
        'code_challenge_method': 'S256',
        'code_challenge': codeChallenge,
        'state': state,
      },
    );

    final launched =
        await launchUrl(authorizeUri, mode: LaunchMode.inAppWebView) ||
        await launchUrl(authorizeUri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await sub.cancel();
      await server.close(force: true);
      throw StateError('failed to launch browser');
    }

    final query = await completer.future.timeout(const Duration(minutes: 5));
    final code = query['code']!;

    final tokens = await _exchangeCodeForToken(
      tokenEndpoint: config.tokenEndpoint,
      clientId: config.clientId,
      code: code,
      redirectUri: redirectUri.toString(),
      codeVerifier: codeVerifier,
    );
    return tokens;
  }

  @override
  Future<OidcTokens> refresh({
    required String tokenEndpoint,
    required String clientId,
    required String refreshToken,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      tokenEndpoint,
      data: <String, dynamic>{
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final data = resp.data;
    if (data == null) throw StateError('empty token response');
    return _parseTokenResponse(data);
  }

  Future<OidcTokens> _exchangeCodeForToken({
    required String tokenEndpoint,
    required String clientId,
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      tokenEndpoint,
      data: <String, dynamic>{
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': codeVerifier,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final data = resp.data;
    if (data == null) throw StateError('empty token response');
    return _parseTokenResponse(data);
  }

  OidcTokens _parseTokenResponse(Map<String, dynamic> data) {
    final accessToken = data['access_token'] as String?;
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw StateError('missing access_token');
    }
    final idToken = data['id_token'] as String?;
    final refreshToken = data['refresh_token'] as String?;
    final bearerToken = (idToken != null && idToken.contains('.'))
        ? idToken
        : accessToken;

    final expiresAtFromJwt = _tryJwtExpMsUtc(bearerToken);
    final expiresIn = (data['expires_in'] as num?)?.toInt();
    final expiresAtMsUtc =
        expiresAtFromJwt ??
        (expiresIn == null
            ? null
            : DateTime.now().toUtc().millisecondsSinceEpoch + expiresIn * 1000);

    return OidcTokens(
      accessToken: bearerToken,
      refreshToken: refreshToken,
      expiresAtMsUtc: expiresAtMsUtc,
    );
  }

  int? _tryJwtExpMsUtc(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final bytes = base64Url.decode(normalized);
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, dynamic>) return null;
      final exp = json['exp'];
      if (exp is! num) return null;
      return exp.toInt() * 1000;
    } catch (_) {
      return null;
    }
  }

  String _randomUrlSafeString(int minLength) {
    final random = Random.secure();
    final bytes = List<int>.generate(minLength, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  Future<String> _codeChallengeS256(String verifier) async {
    final sha256 = Sha256();
    final digest = await sha256.hash(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }
}

OidcAuthService createOidcAuthServiceImpl() => IoOidcAuthService();
