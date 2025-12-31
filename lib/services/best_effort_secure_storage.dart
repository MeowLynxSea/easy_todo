import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Best-effort storage for sensitive values.
///
/// On some macOS builds (notably unsigned, non-notarized distribution builds),
/// Keychain access via `flutter_secure_storage` may fail with `-34018`
/// (missing entitlement). When that happens, this falls back to
/// `SharedPreferences` for the remainder of the app run to keep core features
/// (e.g. cloud sync login) working.
class BestEffortSecureStorage {
  final FlutterSecureStorage? _secureStorageOverride;
  final Future<SharedPreferences>? _prefsOverride;

  static bool _macosKeychainUnavailable = false;

  late final FlutterSecureStorage _secureStorage =
      _secureStorageOverride ?? const FlutterSecureStorage();
  late final Future<SharedPreferences> _prefs =
      _prefsOverride ?? SharedPreferences.getInstance();

  BestEffortSecureStorage({
    FlutterSecureStorage? secureStorage,
    Future<SharedPreferences>? prefs,
  }) : _secureStorageOverride = secureStorage,
       _prefsOverride = prefs;

  bool get _isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  bool _isMissingEntitlementError(Object error) {
    if (error is! PlatformException) return false;
    final message = (error.message ?? '').toLowerCase();
    final details = (error.details?.toString() ?? '').toLowerCase();
    final code = error.code.toLowerCase();
    return code.contains('-34018') ||
        message.contains('-34018') ||
        details.contains('-34018') ||
        message.contains('missing entitlement') ||
        message.contains("required entitlement isn't presented");
  }

  Future<String?> read({required String key}) async {
    if (_isMacOS && _macosKeychainUnavailable) {
      return (await _prefs).getString(key);
    }

    try {
      return await _secureStorage.read(key: key);
    } catch (error) {
      if (_isMacOS && _isMissingEntitlementError(error)) {
        _macosKeychainUnavailable = true;
        return (await _prefs).getString(key);
      }
      rethrow;
    }
  }

  Future<void> write({required String key, required String value}) async {
    if (_isMacOS && _macosKeychainUnavailable) {
      await (await _prefs).setString(key, value);
      return;
    }

    try {
      await _secureStorage.write(key: key, value: value);
    } catch (error) {
      if (_isMacOS && _isMissingEntitlementError(error)) {
        _macosKeychainUnavailable = true;
        await (await _prefs).setString(key, value);
        return;
      }
      rethrow;
    }
  }

  Future<void> delete({required String key}) async {
    if (_isMacOS && _macosKeychainUnavailable) {
      await (await _prefs).remove(key);
      return;
    }

    try {
      await _secureStorage.delete(key: key);
    } catch (error) {
      if (_isMacOS && _isMissingEntitlementError(error)) {
        _macosKeychainUnavailable = true;
        await (await _prefs).remove(key);
        return;
      }
      rethrow;
    }
  }
}
