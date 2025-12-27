class SyncState {
  final String deviceId;
  final int lastHlcWallMsUtc;
  final int lastHlcCounter;
  final int lastServerSeq;

  /// Whether we have already enqueued existing local records once (bootstrap).
  ///
  /// Without this, only "new changes" are synced, and existing todos/repeats/etc
  /// created before enabling sync might never be pushed.
  final bool didBootstrapLocalRecords;

  /// Whether we have already enqueued singleton settings records once.
  ///
  /// Without this, an unchanged local preference might never be uploaded, so a
  /// new device can't pull it.
  final bool didBootstrapSettings;

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
    required this.didBootstrapLocalRecords,
    required this.didBootstrapSettings,
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
    bool? didBootstrapLocalRecords,
    bool? didBootstrapSettings,
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
      didBootstrapLocalRecords:
          didBootstrapLocalRecords ?? this.didBootstrapLocalRecords,
      didBootstrapSettings: didBootstrapSettings ?? this.didBootstrapSettings,
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
      didBootstrapLocalRecords: false,
      didBootstrapSettings: false,
      syncEnabled: false,
      serverUrl: '',
      authToken: '',
      dekId: null,
    );
  }

  static const Object _unset = Object();
}
