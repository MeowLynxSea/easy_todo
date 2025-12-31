import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_todo/models/sync/key_bundle.dart';
import 'package:easy_todo/models/sync/sync_record_envelope.dart';

import 'sync_auth_storage.dart';
import 'sync_server_auth_service.dart';

class SyncApiException implements Exception {
  final int? statusCode;
  final String message;
  const SyncApiException(this.message, {this.statusCode});

  @override
  String toString() => 'SyncApiException($statusCode): $message';
}

class PushAccepted {
  final String type;
  final String recordId;
  final int serverSeq;

  const PushAccepted({
    required this.type,
    required this.recordId,
    required this.serverSeq,
  });

  factory PushAccepted.fromJson(Map<String, dynamic> json) {
    return PushAccepted(
      type: json['type'] as String,
      recordId: json['recordId'] as String,
      serverSeq: (json['serverSeq'] as num).toInt(),
    );
  }
}

class PushRejected {
  final String type;
  final String recordId;
  final String reason;

  const PushRejected({
    required this.type,
    required this.recordId,
    required this.reason,
  });

  factory PushRejected.fromJson(Map<String, dynamic> json) {
    return PushRejected(
      type: json['type'] as String,
      recordId: json['recordId'] as String,
      reason: json['reason'] as String,
    );
  }
}

class PushResponse {
  final List<PushAccepted> accepted;
  final List<PushRejected> rejected;

  const PushResponse({required this.accepted, required this.rejected});

  factory PushResponse.fromJson(Map<String, dynamic> json) {
    return PushResponse(
      accepted: (json['accepted'] as List<dynamic>? ?? const [])
          .map((e) => PushAccepted.fromJson(e as Map<String, dynamic>))
          .toList(),
      rejected: (json['rejected'] as List<dynamic>? ?? const [])
          .map((e) => PushRejected.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PullResponse {
  final List<SyncRecordEnvelope> records;
  final int nextSince;

  const PullResponse({required this.records, required this.nextSince});

  factory PullResponse.fromJson(Map<String, dynamic> json) {
    return PullResponse(
      records: (json['records'] as List<dynamic>? ?? const [])
          .map((e) => SyncRecordEnvelope.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextSince: (json['nextSince'] as num).toInt(),
    );
  }
}

class AttachmentRef {
  final String attachmentId;
  final String todoId;

  const AttachmentRef({required this.attachmentId, required this.todoId});

  Map<String, dynamic> toJson() => {
    'attachmentId': attachmentId,
    'todoId': todoId,
  };
}

class SyncApiClient {
  static const Duration _syncTimeout = Duration(minutes: 3);

  final Dio _dio;
  final SyncAuthStorage? _authStorage;
  final SyncServerAuthService? _authService;
  final String? _staticBearerToken;

  Completer<SyncAuthTokens>? _refreshMutex;

  SyncApiClient.dev({
    required String serverUrl,
    required String bearerToken,
    Dio? dio,
  }) : _authStorage = null,
       _authService = null,
       _staticBearerToken = bearerToken,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: _normalizeBaseUrl(serverUrl),
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 20),
               sendTimeout: const Duration(seconds: 20),
               headers: <String, dynamic>{
                 'Authorization': 'Bearer $bearerToken',
                 'Content-Type': 'application/json',
               },
             ),
           );

  SyncApiClient.tokens({
    required String serverUrl,
    required SyncAuthStorage authStorage,
    required SyncServerAuthService authService,
    Dio? dio,
  }) : _authStorage = authStorage,
       _authService = authService,
       _staticBearerToken = null,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: _normalizeBaseUrl(serverUrl),
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 20),
               sendTimeout: const Duration(seconds: 20),
               headers: <String, dynamic>{'Content-Type': 'application/json'},
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final bearer = await _getAccessToken();
          if (bearer != null && bearer.trim().isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $bearer';
          }
          handler.next(options);
        },
        onError: (err, handler) async {
          final status = err.response?.statusCode;
          final isBanned =
              status == 403 && _isBannedErrorBody(err.response?.data);
          final shouldRetry =
              (status == 401 || (status == 403 && !isBanned)) &&
              err.requestOptions.extra['__sync_retried'] != true;
          if (!shouldRetry) {
            handler.next(err);
            return;
          }

          try {
            final refreshed = await _refreshIfPossible();
            if (refreshed == null) {
              handler.next(err);
              return;
            }

            final req = err.requestOptions;
            req.extra['__sync_retried'] = true;
            req.headers['Authorization'] = 'Bearer ${refreshed.accessToken}';
            final resp = await _dio.fetch(req);
            handler.resolve(resp);
          } catch (_) {
            handler.next(err);
          }
        },
      ),
    );
  }

  static String _normalizeBaseUrl(String serverUrl) {
    var trimmed = serverUrl.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static bool _isBannedErrorBody(Object? data) {
    if (data is Map && data['error'] is String) {
      return (data['error'] as String).trim().toLowerCase() == 'banned';
    }
    return false;
  }

  Future<String?> _getAccessToken() async {
    if (_staticBearerToken != null) return _staticBearerToken;
    final storage = _authStorage;
    if (storage == null) return null;
    try {
      final tokens = await storage.read();
      return tokens?.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<SyncAuthTokens?> _refreshIfPossible() async {
    final storage = _authStorage;
    final authService = _authService;
    if (storage == null || authService == null) return null;

    SyncAuthTokens? existing;
    try {
      existing = await storage.read();
    } catch (_) {
      return null;
    }
    final refreshToken = existing?.refreshToken;
    if (refreshToken == null || refreshToken.trim().isEmpty) return null;

    if (_refreshMutex != null) {
      return _refreshMutex!.future;
    }

    final mutex = Completer<SyncAuthTokens>();
    _refreshMutex = mutex;

    try {
      final baseUrl = _dio.options.baseUrl;
      final tokens = await authService.refresh(
        serverUrl: baseUrl,
        refreshToken: refreshToken,
      );
      await storage.write(tokens);
      if (!mutex.isCompleted) mutex.complete(tokens);
      return tokens;
    } catch (e) {
      final status = e is DioException ? e.response?.statusCode : null;
      final isBanned =
          e is DioException &&
          status == 403 &&
          _isBannedErrorBody(e.response?.data);
      final shouldClear =
          status == 401 ||
          (status == 403 && !isBanned); // refresh token invalid/expired
      if (shouldClear) {
        await storage.clear();
      }
      if (!mutex.isCompleted) mutex.completeError(e);
      rethrow;
    } finally {
      _refreshMutex = null;
    }
  }

  Never _throwAsSyncApiException(Object err) {
    if (err is DioException) {
      final status = err.response?.statusCode;
      final data = err.response?.data;
      final message = data is Map && data['error'] is String
          ? data['error'] as String
          : err.message ?? 'network error';
      throw SyncApiException(message, statusCode: status);
    }
    throw SyncApiException(err.toString());
  }

  Future<KeyBundle?> getKeyBundle() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>('/v1/key-bundle');
      final data = resp.data;
      if (data == null) {
        throw const SyncApiException('empty response');
      }
      return KeyBundle.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _throwAsSyncApiException(e);
    } catch (e) {
      _throwAsSyncApiException(e);
    }
  }

  Future<KeyBundle> putKeyBundle({
    required int expectedBundleVersion,
    required KeyBundle bundle,
  }) async {
    try {
      final resp = await _dio.put<Map<String, dynamic>>(
        '/v1/key-bundle',
        data: <String, dynamic>{
          'expectedBundleVersion': expectedBundleVersion,
          'bundle': bundle.toJson(),
        },
      );
      final data = resp.data;
      if (data == null) {
        throw const SyncApiException('empty response');
      }
      return KeyBundle.fromJson(data);
    } catch (e) {
      _throwAsSyncApiException(e);
    }
  }

  Future<PushResponse> push({required List<SyncRecordEnvelope> records}) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '/v1/sync/push',
        data: <String, dynamic>{
          'records': records.map((e) => e.toJson()).toList(),
        },
        options: Options(
          sendTimeout: _syncTimeout,
          receiveTimeout: _syncTimeout,
        ),
      );
      final data = resp.data;
      if (data == null) {
        throw const SyncApiException('empty response');
      }
      return PushResponse.fromJson(data);
    } catch (e) {
      _throwAsSyncApiException(e);
    }
  }

  Future<PullResponse> pull({
    required int since,
    int limit = 200,
    String? excludeDeviceId,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '/v1/sync/pull',
        queryParameters: <String, dynamic>{
          'since': since,
          'limit': limit,
          if (excludeDeviceId != null && excludeDeviceId.trim().isNotEmpty)
            'excludeDeviceId': excludeDeviceId.trim(),
        },
        options: Options(receiveTimeout: _syncTimeout),
      );
      final data = resp.data;
      if (data == null) {
        throw const SyncApiException('empty response');
      }
      return PullResponse.fromJson(data);
    } catch (e) {
      _throwAsSyncApiException(e);
    }
  }

  Future<void> health() async {
    try {
      await _dio.get('/v1/health');
    } catch (e) {
      _throwAsSyncApiException(e);
    }
  }

  Future<void> upsertAttachmentRefs({required List<AttachmentRef> refs}) async {
    if (refs.isEmpty) return;

    try {
      await _dio.post<Map<String, dynamic>>(
        '/v1/attachments/refs',
        data: <String, dynamic>{'refs': refs.map((e) => e.toJson()).toList()},
        options: Options(
          sendTimeout: _syncTimeout,
          receiveTimeout: _syncTimeout,
        ),
      );
    } catch (e) {
      _throwAsSyncApiException(e);
    }
  }
}
