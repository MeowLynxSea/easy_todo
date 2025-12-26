import 'package:flutter/material.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  static BiometricService get instance => _instance;

  BiometricService._internal();

  Future<bool> isFingerprintAvailable() async => false;

  Future<List<dynamic>> getAvailableBiometrics() async => const [];

  Future<bool> authenticateWithFingerprint({
    String reason = 'Please authenticate',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    debugPrint('BiometricService(web): biometric auth not supported');
    return false;
  }

  Future<void> stopAuthentication() async {}
}
