import 'package:dio/dio.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/update_model.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 2),
      sendTimeout: const Duration(seconds: 15),
    ),
  );

  final String _serverUrl = 'https://update.0v0.live';

  Future<PackageInfo> getPackageInfo() async {
    return PackageInfo.fromPlatform();
  }

  Future<UpdateInfo> checkForUpdates() async {
    try {
      final packageInfo = await getPackageInfo();

      String packageName = packageInfo.packageName;
      if (packageName.endsWith('.debug')) {
        packageName = packageName.substring(
          0,
          packageName.length - '.debug'.length,
        );
      }

      final response = await _dio.post(
        '$_serverUrl/api/check-update',
        data: {
          'package_name': packageName,
          'current_version': packageInfo.version,
        },
      );

      if (response.statusCode == 200) {
        final updateInfo = UpdateInfo.fromJson(response.data);
        return updateInfo;
      }

      return UpdateInfo(
        updateAvailable: false,
        message: 'Failed to check for updates',
      );
    } catch (e) {
      return UpdateInfo(
        updateAvailable: false,
        message: 'Error checking for updates: ${e.toString()}',
      );
    }
  }

  Future<bool> downloadAndInstallUpdate(
    BuildContext context,
    String downloadUrl, {
    void Function(int, int)? onProgress,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.updateCheckError('Web not supported')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
    return false;
  }

  void showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.updateAvailable),
        content: Text(updateInfo.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}
