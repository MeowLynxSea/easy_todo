class HlcJson {
  final int wallTimeMsUtc;
  final int counter;
  final String deviceId;

  const HlcJson({
    required this.wallTimeMsUtc,
    required this.counter,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'wallTimeMsUtc': wallTimeMsUtc,
    'counter': counter,
    'deviceId': deviceId,
  };

  factory HlcJson.fromJson(Map<String, dynamic> json) {
    return HlcJson(
      wallTimeMsUtc: (json['wallTimeMsUtc'] as num).toInt(),
      counter: (json['counter'] as num).toInt(),
      deviceId: json['deviceId'] as String,
    );
  }
}

class SyncRecordEnvelope {
  final String type;
  final String recordId;
  final HlcJson hlc;
  final int? deletedAtMsUtc;
  final int schemaVersion;
  final String dekId;
  final String payloadAlgo;

  final String nonce;
  final String ciphertext;

  const SyncRecordEnvelope({
    required this.type,
    required this.recordId,
    required this.hlc,
    required this.deletedAtMsUtc,
    required this.schemaVersion,
    required this.dekId,
    required this.payloadAlgo,
    required this.nonce,
    required this.ciphertext,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'recordId': recordId,
    'hlc': hlc.toJson(),
    'deletedAtMsUtc': deletedAtMsUtc,
    'schemaVersion': schemaVersion,
    'dekId': dekId,
    'payloadAlgo': payloadAlgo,
    'nonce': nonce,
    'ciphertext': ciphertext,
  };

  factory SyncRecordEnvelope.fromJson(Map<String, dynamic> json) {
    return SyncRecordEnvelope(
      type: json['type'] as String,
      recordId: json['recordId'] as String,
      hlc: HlcJson.fromJson(json['hlc'] as Map<String, dynamic>),
      deletedAtMsUtc: json['deletedAtMsUtc'] == null
          ? null
          : (json['deletedAtMsUtc'] as num).toInt(),
      schemaVersion: (json['schemaVersion'] as num).toInt(),
      dekId: json['dekId'] as String,
      payloadAlgo: json['payloadAlgo'] as String,
      nonce: json['nonce'] as String,
      ciphertext: json['ciphertext'] as String,
    );
  }
}
