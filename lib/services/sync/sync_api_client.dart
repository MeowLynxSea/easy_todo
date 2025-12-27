import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_todo/models/sync/key_bundle.dart';
import 'package:easy_todo/models/sync/sync_record_envelope.dart';

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
      accepted:
          (json['accepted'] as List<dynamic>? ?? const [])
              .map((e) => PushAccepted.fromJson(e as Map<String, dynamic>))
              .toList(),
      rejected:
          (json['rejected'] as List<dynamic>? ?? const [])
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
      records:
          (json['records'] as List<dynamic>? ?? const [])
              .map(
                (e) => SyncRecordEnvelope.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      nextSince: (json['nextSince'] as num).toInt(),
    );
  }
}

class SyncApiClient {
  final Dio _dio;

  SyncApiClient({
    required String serverUrl,
    required String bearerToken,
    Dio? dio,
  }) : _dio =
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

  static String _normalizeBaseUrl(String serverUrl) {
    var trimmed = serverUrl.trim();
    if (trimmed.endsWith('/')) trimmed = trimmed.substring(0, trimmed.length - 1);
    return trimmed;
  }

  Never _throwAsSyncApiException(Object err) {
    if (err is DioException) {
      final status = err.response?.statusCode;
      final data = err.response?.data;
      final message =
          data is Map && data['error'] is String
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

  Future<PullResponse> pull({required int since, int limit = 200}) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '/v1/sync/pull',
        queryParameters: <String, dynamic>{'since': since, 'limit': limit},
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
}
