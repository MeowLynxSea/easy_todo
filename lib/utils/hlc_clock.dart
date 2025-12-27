class HlcTimestamp {
  final int wallTimeMsUtc;
  final int counter;
  final String deviceId;

  const HlcTimestamp({
    required this.wallTimeMsUtc,
    required this.counter,
    required this.deviceId,
  });

  @override
  String toString() => 'HLC($wallTimeMsUtc,$counter,$deviceId)';
}

/// Hybrid Logical Clock (HLC).
///
/// Stores local state (lastWallMsUtc, lastCounter) and generates monotonic
/// timestamps for local writes. Use [observe] after accepting remote timestamps.
class HlcClock {
  final String deviceId;

  int _lastWallMsUtc;
  int _lastCounter;

  HlcClock({
    required this.deviceId,
    required int lastWallMsUtc,
    required int lastCounter,
  }) : _lastWallMsUtc = lastWallMsUtc,
       _lastCounter = lastCounter;

  int get lastWallMsUtc => _lastWallMsUtc;
  int get lastCounter => _lastCounter;

  HlcTimestamp tick(int nowMsUtc) {
    if (nowMsUtc > _lastWallMsUtc) {
      _lastWallMsUtc = nowMsUtc;
      _lastCounter = 0;
    } else {
      _lastCounter += 1;
    }
    return HlcTimestamp(
      wallTimeMsUtc: _lastWallMsUtc,
      counter: _lastCounter,
      deviceId: deviceId,
    );
  }

  /// Advance the local clock after observing a remote timestamp.
  ///
  /// This follows standard HLC observe rules and guarantees monotonicity.
  void observe(HlcTimestamp remote, int nowMsUtc) {
    final maxWall = _max3(_lastWallMsUtc, remote.wallTimeMsUtc, nowMsUtc);

    if (maxWall == _lastWallMsUtc && maxWall == remote.wallTimeMsUtc) {
      _lastCounter = _max2(_lastCounter, remote.counter) + 1;
    } else if (maxWall == _lastWallMsUtc) {
      _lastCounter = _lastCounter + 1;
    } else if (maxWall == remote.wallTimeMsUtc) {
      _lastCounter = remote.counter + 1;
    } else {
      _lastCounter = 0;
    }

    _lastWallMsUtc = maxWall;
  }

  static int compare(HlcTimestamp a, HlcTimestamp b) {
    if (a.wallTimeMsUtc != b.wallTimeMsUtc) {
      return a.wallTimeMsUtc.compareTo(b.wallTimeMsUtc);
    }
    if (a.counter != b.counter) {
      return a.counter.compareTo(b.counter);
    }
    return a.deviceId.compareTo(b.deviceId);
  }

  static int _max2(int a, int b) => a > b ? a : b;
  static int _max3(int a, int b, int c) {
    final ab = a > b ? a : b;
    return ab > c ? ab : c;
  }
}
