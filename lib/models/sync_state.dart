class SyncState {
  final String deviceId;
  final int lastHlcWallMsUtc;
  final int lastHlcCounter;
  final int lastServerSeq;

  /// Device-local sync configuration/state.
  final bool syncEnabled;
  final String serverUrl;
  final String authToken;

  /// Current DEK id for this sync space.
  ///
  /// Used to attempt automatic unlock from secure storage.
  final String? dekId;

  const SyncState({
    required this.deviceId,
    required this.lastHlcWallMsUtc,
    required this.lastHlcCounter,
    required this.lastServerSeq,
    required this.syncEnabled,
    required this.serverUrl,
    required this.authToken,
    required this.dekId,
  });

  SyncState copyWith({
    String? deviceId,
    int? lastHlcWallMsUtc,
    int? lastHlcCounter,
    int? lastServerSeq,
    bool? syncEnabled,
    String? serverUrl,
    String? authToken,
    Object? dekId = _unset,
  }) {
    return SyncState(
      deviceId: deviceId ?? this.deviceId,
      lastHlcWallMsUtc: lastHlcWallMsUtc ?? this.lastHlcWallMsUtc,
      lastHlcCounter: lastHlcCounter ?? this.lastHlcCounter,
      lastServerSeq: lastServerSeq ?? this.lastServerSeq,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      serverUrl: serverUrl ?? this.serverUrl,
      authToken: authToken ?? this.authToken,
      dekId: identical(dekId, _unset) ? this.dekId : dekId as String?,
    );
  }

  static SyncState create({required String deviceId}) {
    return SyncState(
      deviceId: deviceId,
      lastHlcWallMsUtc: 0,
      lastHlcCounter: 0,
      lastServerSeq: 0,
      syncEnabled: false,
      serverUrl: '',
      authToken: '',
      dekId: null,
    );
  }

  static const Object _unset = Object();
}
