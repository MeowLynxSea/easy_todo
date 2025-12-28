import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import 'sync_auth_storage.dart';
import 'sync_server_auth_service.dart';

class IoSyncServerAuthService implements SyncServerAuthService {
  final Dio _dio;

  static const String _mobileAppRedirect = 'easy_todo://auth';

  IoSyncServerAuthService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              headers: <String, dynamic>{'Content-Type': 'application/json'},
            ),
          );

  @override
  Future<List<String>> listProviders({required String serverUrl}) async {
    final base = _normalizeServerUrl(serverUrl);
    final resp = await _dio.get<Map<String, dynamic>>(
      base.resolve('/v1/auth/providers').toString(),
    );
    final data = resp.data;
    if (data == null) return const [];
    final list = data['providers'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => e['name'])
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Uri buildStartUri({
    required String serverUrl,
    required String provider,
    required String appRedirect,
    required String client,
  }) {
    final base = _normalizeServerUrl(serverUrl);
    return base
        .resolve('/v1/auth/start')
        .replace(
          queryParameters: <String, String>{
            'provider': provider,
            'app_redirect': appRedirect,
            'client': client,
          },
        );
  }

  @override
  Future<SyncAuthTokens?> login({
    required String serverUrl,
    required String provider,
    required String client,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final startUri = buildStartUri(
        serverUrl: serverUrl,
        provider: provider,
        appRedirect: _mobileAppRedirect,
        client: client,
      );

      final launched =
          await launchUrl(startUri, mode: LaunchMode.externalApplication) ||
          await launchUrl(startUri, mode: LaunchMode.inAppWebView);
      if (!launched) {
        throw StateError('failed to launch browser');
      }

      // On mobile, login completes via deep link back to the app
      // (e.g. easy_todo://auth?ticket=...).
      return null;
    }

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: server.port,
      path: '/sync_auth/callback',
    );

    final completer = Completer<String>();
    late final StreamSubscription<HttpRequest> sub;
    sub = server.listen((request) async {
      if (request.uri.path != '/sync_auth/callback') {
        request.response
          ..statusCode = 404
          ..write('not found');
        await request.response.close();
        return;
      }

      final ticket = request.uri.queryParameters['ticket'];
      request.response.headers.contentType = ContentType.html;
      request.response.write(
        '<!doctype html><html><body>Login received. You can close this window now.</body></html>',
      );
      await request.response.close();

      if (ticket == null || ticket.trim().isEmpty) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('missing ticket'));
        }
      } else {
        if (!completer.isCompleted) completer.complete(ticket.trim());
      }

      await sub.cancel();
      await server.close(force: true);
    });

    final startUri = buildStartUri(
      serverUrl: serverUrl,
      provider: provider,
      appRedirect: redirectUri.toString(),
      client: client,
    );

    final launched =
        await launchUrl(startUri, mode: LaunchMode.inAppWebView) ||
        await launchUrl(startUri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await sub.cancel();
      await server.close(force: true);
      throw StateError('failed to launch browser');
    }

    final ticket = await completer.future.timeout(const Duration(minutes: 5));
    return exchange(serverUrl: serverUrl, ticket: ticket);
  }

  @override
  Future<SyncAuthTokens> exchange({
    required String serverUrl,
    required String ticket,
  }) async {
    final base = _normalizeServerUrl(serverUrl);
    final resp = await _dio.post<Map<String, dynamic>>(
      base.resolve('/v1/auth/exchange').toString(),
      data: <String, dynamic>{'ticket': ticket},
    );
    final data = resp.data;
    if (data == null) throw StateError('empty exchange response');

    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final expiresIn = (data['expiresIn'] as num?)?.toInt();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw StateError('missing accessToken');
    }
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      throw StateError('missing refreshToken');
    }

    final expiresAtMsUtc = expiresIn == null
        ? null
        : DateTime.now().toUtc().millisecondsSinceEpoch + expiresIn * 1000;

    return SyncAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAtMsUtc: expiresAtMsUtc,
    );
  }

  @override
  Future<SyncAuthTokens> refresh({
    required String serverUrl,
    required String refreshToken,
  }) async {
    final base = _normalizeServerUrl(serverUrl);
    final resp = await _dio.post<Map<String, dynamic>>(
      base.resolve('/v1/auth/refresh').toString(),
      data: <String, dynamic>{'refreshToken': refreshToken},
    );
    final data = resp.data;
    if (data == null) throw StateError('empty refresh response');

    final accessToken = data['accessToken'] as String?;
    final newRefreshToken = data['refreshToken'] as String?;
    final expiresIn = (data['expiresIn'] as num?)?.toInt();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw StateError('missing accessToken');
    }
    if (newRefreshToken == null || newRefreshToken.trim().isEmpty) {
      throw StateError('missing refreshToken');
    }

    final expiresAtMsUtc = expiresIn == null
        ? null
        : DateTime.now().toUtc().millisecondsSinceEpoch + expiresIn * 1000;

    return SyncAuthTokens(
      accessToken: accessToken,
      refreshToken: newRefreshToken,
      expiresAtMsUtc: expiresAtMsUtc,
    );
  }

  @override
  Future<void> logout({
    required String serverUrl,
    required String refreshToken,
  }) async {
    final base = _normalizeServerUrl(serverUrl);
    await _dio.post<void>(
      base.resolve('/v1/auth/logout').toString(),
      data: <String, dynamic>{'refreshToken': refreshToken},
    );
  }

  Uri _normalizeServerUrl(String serverUrl) {
    var trimmed = serverUrl.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return Uri.parse(trimmed);
  }
}

SyncServerAuthService createSyncServerAuthServiceImpl() =>
    IoSyncServerAuthService();
