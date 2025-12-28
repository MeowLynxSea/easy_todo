import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../services/web_url_utils_stub.dart'
    if (dart.library.html) '../../services/web_url_utils_web.dart';
import 'sync_auth_storage.dart';
import 'sync_server_auth_service.dart';

class WebSyncServerAuthService implements SyncServerAuthService {
  final Dio _dio;

  WebSyncServerAuthService({Dio? dio})
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
    final appRedirect = _currentUrlWithoutTicket().toString();
    final startUri = buildStartUri(
      serverUrl: serverUrl,
      provider: provider,
      appRedirect: appRedirect,
      client: client,
    );

    navigateWebUrl(startUri);

    // On web, login completes via full-page redirect back to appRedirect.
    return null;
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

  Uri _currentUrlWithoutTicket() {
    if (!kIsWeb) return Uri();
    final current = currentWebUrl();
    final qp = Map<String, String>.from(current.queryParameters);
    qp.remove('ticket');
    qp.remove('amp;ticket');
    return current.replace(queryParameters: qp);
  }
}

SyncServerAuthService createSyncServerAuthServiceImpl() =>
    WebSyncServerAuthService();
