import 'package:flutter/material.dart';

class PermissionService {
  static Future<bool> checkAndRequestNotificationPermission() async => true;

  static Future<bool> checkAndRequestExactAlarmPermission() async => true;

  static Future<bool> checkAndRequestBatteryOptimizationPermission(
    BuildContext context,
  ) async =>
      true;

  static Future<void> showExactAlarmPermissionDialog(
    BuildContext context,
  ) async {}

  static Future<void> initializePermissions(BuildContext context) async {
    debugPrint('PermissionService(web): skipping platform permissions');
  }

  static Future<Map<String, bool>> getPermissionStatus() async => {
        'notification': true,
        'batteryOptimization': true,
      };
}

