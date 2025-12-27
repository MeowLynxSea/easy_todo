class ScryptParams {
  final int n;
  final int r;
  final int p;
  final int dkLen;

  const ScryptParams({
    required this.n,
    required this.r,
    required this.p,
    required this.dkLen,
  });

  Map<String, dynamic> toJson() => {'N': n, 'r': r, 'p': p, 'dkLen': dkLen};

  factory ScryptParams.fromJson(Map<String, dynamic> json) {
    return ScryptParams(
      n: (json['N'] as num).toInt(),
      r: (json['r'] as num).toInt(),
      p: (json['p'] as num).toInt(),
      dkLen: (json['dkLen'] as num).toInt(),
    );
  }
}

class KeyBundle {
  final int bundleVersion;
  final String dekId;

  final String kdf;
  final String salt;
  final ScryptParams kdfParams;

  final String wrapAlgo;
  final String wrappedDek;
  final String wrapNonce;

  final int updatedAtMsUtc;

  const KeyBundle({
    required this.bundleVersion,
    required this.dekId,
    required this.kdf,
    required this.salt,
    required this.kdfParams,
    required this.wrapAlgo,
    required this.wrappedDek,
    required this.wrapNonce,
    required this.updatedAtMsUtc,
  });

  Map<String, dynamic> toJson() => {
    'bundleVersion': bundleVersion,
    'dekId': dekId,
    'kdf': kdf,
    'salt': salt,
    'kdfParams': kdfParams.toJson(),
    'wrapAlgo': wrapAlgo,
    'wrappedDek': wrappedDek,
    'wrapNonce': wrapNonce,
    'updatedAtMsUtc': updatedAtMsUtc,
  };

  factory KeyBundle.fromJson(Map<String, dynamic> json) {
    return KeyBundle(
      bundleVersion: (json['bundleVersion'] as num).toInt(),
      dekId: json['dekId'] as String,
      kdf: json['kdf'] as String,
      salt: json['salt'] as String,
      kdfParams: ScryptParams.fromJson(
        json['kdfParams'] as Map<String, dynamic>,
      ),
      wrapAlgo: json['wrapAlgo'] as String,
      wrappedDek: json['wrappedDek'] as String,
      wrapNonce: json['wrapNonce'] as String,
      updatedAtMsUtc: (json['updatedAtMsUtc'] as num).toInt(),
    );
  }
}
