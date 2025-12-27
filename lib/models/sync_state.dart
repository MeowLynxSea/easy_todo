class SyncState {
  final String deviceId;
  final int lastHlcWallMsUtc;
  final int lastHlcCounter;
  final int lastServerSeq;

  const SyncState({
    required this.deviceId,
    required this.lastHlcWallMsUtc,
    required this.lastHlcCounter,
    required this.lastServerSeq,
  });

  SyncState copyWith({
    String? deviceId,
    int? lastHlcWallMsUtc,
    int? lastHlcCounter,
    int? lastServerSeq,
  }) {
    return SyncState(
      deviceId: deviceId ?? this.deviceId,
      lastHlcWallMsUtc: lastHlcWallMsUtc ?? this.lastHlcWallMsUtc,
      lastHlcCounter: lastHlcCounter ?? this.lastHlcCounter,
      lastServerSeq: lastServerSeq ?? this.lastServerSeq,
    );
  }

  static SyncState create({required String deviceId}) {
    return SyncState(
      deviceId: deviceId,
      lastHlcWallMsUtc: 0,
      lastHlcCounter: 0,
      lastServerSeq: 0,
    );
  }
}
