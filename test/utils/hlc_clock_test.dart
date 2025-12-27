import 'package:easy_todo/utils/hlc_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HlcClock', () {
    test('tick is monotonic for local writes', () {
      final clock = HlcClock(deviceId: 'd1', lastWallMsUtc: 0, lastCounter: 0);

      final t1 = clock.tick(1000);
      final t2 = clock.tick(1000);
      final t3 = clock.tick(999);

      expect(HlcClock.compare(t1, t2) < 0, true);
      expect(HlcClock.compare(t2, t3) < 0, true);
    });

    test('observe advances local time', () {
      final clock = HlcClock(
        deviceId: 'd1',
        lastWallMsUtc: 1000,
        lastCounter: 0,
      );

      clock.observe(
        const HlcTimestamp(wallTimeMsUtc: 2000, counter: 5, deviceId: 'd2'),
        1500,
      );

      final next = clock.tick(1500);
      expect(next.wallTimeMsUtc >= 2000, true);
    });
  });
}
