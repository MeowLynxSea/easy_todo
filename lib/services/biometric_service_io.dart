import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  static BiometricService get instance => _instance;

  final LocalAuthentication _auth = LocalAuthentication();

  BiometricService._internal();

  /// 检查设备是否支持指纹识别
  Future<bool> isFingerprintAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      // debugPrint('Biometric check - canCheckBiometrics: $canCheck');
      // debugPrint('Biometric check - isDeviceSupported: $isDeviceSupported');

      if (!canCheck || !isDeviceSupported) {
        debugPrint('Device does not support biometrics');
        return false;
      }

      // 检查可用的生物识别类型
      final availableBiometrics = await _auth.getAvailableBiometrics();
      // debugPrint('Available biometrics: $availableBiometrics');

      // 检查是否支持指纹识别
      final hasFingerprint = availableBiometrics.contains(
        BiometricType.fingerprint,
      );
      // debugPrint('Has fingerprint: $hasFingerprint');

      // 如果有指纹识别，返回true
      if (hasFingerprint) {
        return true;
      }

      // 如果没有指纹识别但有其他生物识别方式，也返回true
      // 因为用户可能使用面部识别等其他方式
      if (availableBiometrics.isNotEmpty) {
        // debugPrint('Using alternative biometric authentication');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// 获取可用的生物识别类型（仅指纹）
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final allTypes = await _auth.getAvailableBiometrics();
      // 只返回指纹类型
      return allTypes
          .where((type) => type == BiometricType.fingerprint)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 进行生物识别验证（包括指纹、面部识别等）
  Future<bool> authenticateWithFingerprint({
    String reason = '请使用生物识别验证您的身份',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // 首先检查可用的生物识别类型
      final availableBiometrics = await _auth.getAvailableBiometrics();
      debugPrint(
        'Available biometrics for authentication: $availableBiometrics',
      );

      String biometricHint = '请使用生物识别';
      String biometricNotRecognized = '生物识别未识别，请重试';
      String biometricSuccess = '生物识别验证成功';

      // 根据可用的生物识别类型调整提示文本
      if (availableBiometrics.contains(BiometricType.fingerprint)) {
        biometricHint = '请使用指纹传感器';
        biometricNotRecognized = '指纹未识别，请重试';
        biometricSuccess = '指纹验证成功';
      } else if (availableBiometrics.contains(BiometricType.face)) {
        biometricHint = '请使用面部识别';
        biometricNotRecognized = '面部未识别，请重试';
        biometricSuccess = '面部识别成功';
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        biometricHint = '请使用虹膜识别';
        biometricNotRecognized = '虹膜未识别，请重试';
        biometricSuccess = '虹膜识别成功';
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: '生物识别验证',
            cancelButton: '取消',
            biometricHint: biometricHint,
            biometricNotRecognized: biometricNotRecognized,
            biometricSuccess: biometricSuccess,
          ),
        ],
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // 允许生物识别和设备密码
        ),
      );
      debugPrint('Authentication result: $authenticated');
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: ${e.code} - ${e.message}');
      if (e.code == 'NotAvailable') {
        debugPrint('Biometric authentication not available');
        return false;
      } else if (e.code == 'NotEnrolled') {
        debugPrint('No biometric credentials enrolled');
        return false;
      } else if (e.code == 'LockedOut') {
        debugPrint('Biometric authentication temporarily locked out');
        return false;
      } else if (e.code == 'PermanentlyLockedOut') {
        debugPrint('Biometric authentication permanently locked out');
        return false;
      } else {
        debugPrint('Unknown biometric authentication error: ${e.code}');
        return false;
      }
    } catch (e) {
      debugPrint('Unexpected error during biometric authentication: $e');
      return false;
    }
  }

  /// 停止当前的指纹验证
  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      // 忽略错误
    }
  }
}
