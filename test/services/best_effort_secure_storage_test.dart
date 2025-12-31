import 'package:easy_todo/services/best_effort_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object?>{});
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('falls back to SharedPreferences on macOS -34018', () async {
    const missingEntitlement = PlatformException(
      code: 'Unexpected security result code',
      message: "Code: -34018, Message: A required entitlement isn't presented",
    );

    final secureStorage = _MockFlutterSecureStorage();
    when(
      () => secureStorage.read(key: any(named: 'key')),
    ).thenThrow(missingEntitlement);
    when(
      () => secureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenThrow(missingEntitlement);
    when(
      () => secureStorage.delete(key: any(named: 'key')),
    ).thenThrow(missingEntitlement);

    final storage = BestEffortSecureStorage(
      secureStorage: secureStorage,
      prefs: SharedPreferences.getInstance(),
    );

    await storage.write(key: 'k', value: 'v');
    expect(await storage.read(key: 'k'), 'v');
    await storage.delete(key: 'k');
    expect(await storage.read(key: 'k'), isNull);
  });
}
