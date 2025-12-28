class SyncState {
  static const int defaultAutoSyncIntervalSeconds = 300;
  static const int minAutoSyncIntervalSeconds = 30;

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

  /// One-time repair: if meta exists but outbox was lost, existing local records
  /// might never be pushed (only singleton settings are). This flag prevents
  /// re-enqueueing all records on every sync.
  final bool didBackfillOutboxFromMeta;

  /// Device-local sync configuration/state.
  final bool syncEnabled;
  final String serverUrl;
  final int autoSyncIntervalSeconds;

  /// Current logged-in sync user id (derived from access token sub).
  ///
  /// Used to detect account switches and reset bootstrap/cursors to avoid
  /// accidentally mixing two users in one local sync space.
  final String authUserId;

  /// OAuth provider name used for `GET /v1/auth/start?provider=...`.
  final String authProvider;

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
    required this.didBackfillOutboxFromMeta,
    required this.syncEnabled,
    required this.serverUrl,
    required this.autoSyncIntervalSeconds,
    required this.authUserId,
    required this.authProvider,
    required this.dekId,
  });

  SyncState copyWith({
    String? deviceId,
    int? lastHlcWallMsUtc,
    int? lastHlcCounter,
    int? lastServerSeq,
    bool? didBootstrapLocalRecords,
    bool? didBootstrapSettings,
    bool? didBackfillOutboxFromMeta,
    bool? syncEnabled,
    String? serverUrl,
    int? autoSyncIntervalSeconds,
    String? authUserId,
    String? authProvider,
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
      didBackfillOutboxFromMeta:
          didBackfillOutboxFromMeta ?? this.didBackfillOutboxFromMeta,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      serverUrl: serverUrl ?? this.serverUrl,
      autoSyncIntervalSeconds:
          autoSyncIntervalSeconds ?? this.autoSyncIntervalSeconds,
      authUserId: authUserId ?? this.authUserId,
      authProvider: authProvider ?? this.authProvider,
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
      didBackfillOutboxFromMeta: false,
      syncEnabled: false,
      serverUrl: '',
      autoSyncIntervalSeconds: defaultAutoSyncIntervalSeconds,
      authUserId: '',
      authProvider: '',
      dekId: null,
    );
  }

  static const Object _unset = Object();
}
