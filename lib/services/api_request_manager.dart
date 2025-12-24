import 'dart:async';
import 'dart:collection';

class _PendingRequest {
  final DateTime startTime;
  final Completer completer;

  _PendingRequest(this.startTime, this.completer);
}

class ApiRequestManager {
  static const Duration _timeWindow = Duration(minutes: 1);
  static int _maxRequestsPerMinute = 20;

  static final ApiRequestManager _instance = ApiRequestManager._internal();
  factory ApiRequestManager() => _instance;
  ApiRequestManager._internal();

  static void setMaxRequestsPerMinute(int maxRequests) {
    _maxRequestsPerMinute = maxRequests;
  }

  final Queue<DateTime> _requestTimestamps = Queue<DateTime>();
  final Map<String, _PendingRequest> _pendingRequests = {};

  Timer? _cleanupTimer;

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _cleanupOldRequests();
    });
  }

  void _cleanupOldRequests() {
    final now = DateTime.now();
    while (_requestTimestamps.isNotEmpty &&
           now.difference(_requestTimestamps.first) > _timeWindow) {
      _requestTimestamps.removeFirst();
    }
  }

  Future<bool> _canMakeRequest() async {
    _cleanupOldRequests();

    if (_requestTimestamps.length >= _maxRequestsPerMinute) {
      final oldestRequest = _requestTimestamps.first;
      final waitTime = _timeWindow - DateTime.now().difference(oldestRequest);

      if (waitTime.inMilliseconds > 0) {
        await Future.delayed(waitTime);
        return _canMakeRequest();
      }
    }

    return true;
  }

  String _generateRequestKey(String endpoint, Map<String, dynamic> data) {
    final normalizedData = Map<String, dynamic>.from(data)
      ..removeWhere((key, value) => key == 'timestamp' || key == 'request_id');
    return '${endpoint}_${normalizedData.toString().hashCode}';
  }

  Future<T> makeRequest<T>(
    String endpoint,
    Map<String, dynamic> data,
    Future<T> Function() requestFunction, {
    Duration? timeout,
  }) async {
    if (_cleanupTimer == null) {
      _startCleanupTimer();
    }

    final requestKey = _generateRequestKey(endpoint, data);

    // Check if there's already an identical request in progress
    if (_pendingRequests.containsKey(requestKey)) {
      return _pendingRequests[requestKey]!.completer.future as Future<T>;
    }

    // Wait for rate limit
    await _canMakeRequest();

    // Register the request
    final completer = Completer<T>();
    _pendingRequests[requestKey] = _PendingRequest(DateTime.now(), completer);
    _requestTimestamps.add(DateTime.now());


    try {
      // Execute the request with timeout
      final result = timeout != null
          ? await requestFunction().timeout(timeout)
          : await requestFunction();

      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(requestKey);
    }
  }

  Future<T> makeAiRequest<T>(
    String prompt,
    String model,
    Future<T> Function() requestFunction, {
    Duration? timeout,
  }) async {
    final data = {
      'model': model,
      'prompt_hash': prompt.hashCode.toString(),
    };

    return makeRequest(
      'ai_completion',
      data,
      requestFunction,
      timeout: timeout ?? const Duration(seconds: 60),
    );
  }

  int get pendingRequestsCount => _pendingRequests.length;
  int get currentWindowRequestCount => _requestTimestamps.length;

  Map<String, dynamic> getStats() {
    _cleanupOldRequests();
    return {
      'pending_requests': _pendingRequests.length,
      'current_window_requests': _requestTimestamps.length,
      'max_requests_per_minute': _maxRequestsPerMinute,
      'time_window_seconds': _timeWindow.inSeconds,
    };
  }

  List<Map<String, dynamic>> getRequestQueueInfo() {
    final now = DateTime.now();
    return _pendingRequests.entries.map((entry) {
      final request = entry.value;
      final waitTime = now.difference(request.startTime);
      return {
        'request_key': entry.key,
        'start_time': request.startTime.toIso8601String(),
        'wait_time_ms': waitTime.inMilliseconds,
        'wait_time_formatted': '${waitTime.inSeconds}s ${waitTime.inMilliseconds % 1000}ms',
      };
    }).toList();
  }

  List<Map<String, dynamic>> getRecentRequests() {
    _cleanupOldRequests();
    return _requestTimestamps.map((timestamp) {
      final age = DateTime.now().difference(timestamp);
      return {
        'timestamp': timestamp.toIso8601String(),
        'age_ms': age.inMilliseconds,
        'age_formatted': '${age.inSeconds}s ${age.inMilliseconds % 1000}ms',
      };
    }).toList();
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _pendingRequests.clear();
    _requestTimestamps.clear();
  }
}