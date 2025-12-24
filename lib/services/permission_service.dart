import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_todo/services/background_service.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';

class PermissionService {
  static const String _tag = 'PermissionService';

  // 检查并请求通知权限
  static Future<bool> checkAndRequestNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }

      return false;
    } catch (e) {
      debugPrint('$_tag: Error checking notification permission: $e');
      return false;
    }
  }

  // 检查并请求精确闹钟权限
  static Future<bool> checkAndRequestExactAlarmPermission() async {
    try {
      // 对于较新的Android版本，需要检查精确闹钟权限
      if (await Permission.scheduleExactAlarm.isGranted) {
        debugPrint('$_tag: Exact alarm permission already granted');
        return true;
      }

      if (await Permission.scheduleExactAlarm.isDenied) {
        final result = await Permission.scheduleExactAlarm.request();
        debugPrint('$_tag: Exact alarm permission request result: $result');
        return result.isGranted;
      }

      return false;
    } catch (e) {
      debugPrint('$_tag: Error checking exact alarm permission: $e');
      return false;
    }
  }

  // 检查并请求忽略电池优化权限
  static Future<bool> checkAndRequestBatteryOptimizationPermission(BuildContext context) async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.ignoreBatteryOptimizations.request();
        if (result.isGranted) {
          return true;
        }
      }

      // 如果权限被拒绝，显示引导对话框
      await _showBatteryOptimizationDialog(context);
      return false;
    } catch (e) {
      debugPrint('$_tag: Error checking battery optimization permission: $e');
      return false;
    }
  }

  // 显示电池优化权限引导对话框
  static Future<void> _showBatteryOptimizationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.batteryOptimizationSettings),
          content: Text(l10n.batteryOptimizationContent),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.setLater),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(l10n.goToSettings),
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // 显示精确闹钟权限引导对话框
  static Future<void> showExactAlarmPermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.exactAlarmPermission),
          content: Text(l10n.exactAlarmPermissionContent),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.setLater),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(l10n.goToSettings),
              onPressed: () async {
                Navigator.of(context).pop();
                // 由于API兼容性问题，使用通用设置页面
                await openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // 初始化所有必要权限
  static Future<void> initializePermissions(BuildContext context) async {
    debugPrint('$_tag: Initializing permissions...');

    // 检查通知权限
    final notificationGranted = await checkAndRequestNotificationPermission();
    if (!notificationGranted) {
      debugPrint('$_tag: Notification permission denied');
    }

    // 检查电池优化权限
    await checkAndRequestBatteryOptimizationPermission(context);

    // 初始化后台服务
    final backgroundService = BackgroundService();
    await backgroundService.initialize();

    debugPrint('$_tag: Permissions initialization completed');
  }

  // 获取权限状态
  static Future<Map<String, bool>> getPermissionStatus() async {
    try {
      final notificationStatus = await Permission.notification.status;
      final batteryOptimizationStatus = await Permission.ignoreBatteryOptimizations.status;

      return {
        'notification': notificationStatus.isGranted,
        'batteryOptimization': batteryOptimizationStatus.isGranted,
      };
    } catch (e) {
      debugPrint('$_tag: Error getting permission status: $e');
      return {
        'notification': false,
        'batteryOptimization': false,
      };
    }
  }
}