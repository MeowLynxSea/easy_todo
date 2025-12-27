class SyncMeta {
  final String type;
  final String recordId;

  final int hlcWallMsUtc;
  final int hlcCounter;
  final String hlcDeviceId;

  final int? deletedAtMsUtc;
  final int schemaVersion;

  const SyncMeta({
    required this.type,
    required this.recordId,
    required this.hlcWallMsUtc,
    required this.hlcCounter,
    required this.hlcDeviceId,
    required this.deletedAtMsUtc,
    required this.schemaVersion,
  });

  SyncMeta copyWith({
    int? hlcWallMsUtc,
    int? hlcCounter,
    String? hlcDeviceId,
    Object? deletedAtMsUtc = _unset,
    int? schemaVersion,
  }) {
    return SyncMeta(
      type: type,
      recordId: recordId,
      hlcWallMsUtc: hlcWallMsUtc ?? this.hlcWallMsUtc,
      hlcCounter: hlcCounter ?? this.hlcCounter,
      hlcDeviceId: hlcDeviceId ?? this.hlcDeviceId,
      deletedAtMsUtc: identical(deletedAtMsUtc, _unset)
          ? this.deletedAtMsUtc
          : deletedAtMsUtc as int?,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  static const Object _unset = Object();
}
