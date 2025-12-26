import 'package:dio/dio.dart';
import 'package:easy_todo/models/update_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class UpdateService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 2),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
  final String _serverUrl =
      'https://update.0v0.live'; // Update this with your server URL

  Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }

  Future<UpdateInfo> checkForUpdates() async {
    try {
      final packageInfo = await getPackageInfo();

      // Remove debug suffix from package name for update checking
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

        // Enhanced logic: Check all versions greater than current version
        // If any of them has forceUpdate = true, set the overall forceUpdate to true
        if (updateInfo.updateAvailable && response.data['versions'] != null) {
          final List<dynamic> versions = response.data['versions'];
          final currentVersion = packageInfo.version;

          // Check if any version greater than current has forceUpdate = true
          bool hasForcedUpdate = versions.any(
            (version) =>
                _isVersionGreaterThan(version['version'], currentVersion) &&
                version['force_update'] == true,
          );

          return UpdateInfo(
            updateAvailable: true,
            latestVersion: updateInfo.latestVersion,
            downloadUrl: updateInfo.downloadUrl,
            changelog: updateInfo.changelog,
            forceUpdate: hasForcedUpdate,
            message: hasForcedUpdate
                ? 'A required update is available. Please update to continue using the app.'
                : updateInfo.message,
          );
        }

        return updateInfo;
      } else {
        throw Exception('Failed to check for updates');
      }
    } catch (e) {
      return UpdateInfo(
        updateAvailable: false,
        message: 'Error checking for updates: ${e.toString()}',
      );
    }
  }

  // Helper method to compare versions
  bool _isVersionGreaterThan(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();

      // Pad shorter version with zeros
      while (v1Parts.length < v2Parts.length) {
        v1Parts.add(0);
      }
      while (v2Parts.length < v1Parts.length) {
        v2Parts.add(0);
      }

      for (int i = 0; i < v1Parts.length; i++) {
        if (v1Parts[i] > v2Parts[i]) return true;
        if (v1Parts[i] < v2Parts[i]) return false;
      }

      return false; // Versions are equal
    } catch (e) {
      return false; // If parsing fails, assume not greater
    }
  }

  Future<bool> downloadAndInstallUpdate(
    BuildContext context,
    String downloadUrl, {
    void Function(int, int)? onProgress,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (!Platform.isAndroid) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.updateCheckFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.onError),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return false;
      }

      // Ensure download URL is complete
      String fullDownloadUrl = downloadUrl;
      if (downloadUrl.startsWith('/')) {
        fullDownloadUrl = '$_serverUrl$downloadUrl';
      } else if (!downloadUrl.startsWith('http://') &&
          !downloadUrl.startsWith('https://')) {
        fullDownloadUrl = '$_serverUrl/$downloadUrl';
      }

      final uri = Uri.tryParse(fullDownloadUrl);
      if (uri == null || uri.host.isEmpty) {
        throw Exception('Invalid download URL');
      }

      // Prefer HTTPS; allow HTTP only for localhost for development/testing.
      final isLocalhost =
          uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '::1';
      final isAllowedScheme =
          uri.scheme == 'https' || (isLocalhost && uri.scheme == 'http');
      if (!isAllowedScheme) {
        throw Exception('Insecure download URL scheme (HTTPS required)');
      }

      final directory = await getApplicationDocumentsDirectory();

      final savePath = '${directory.path}/easy_todo_update.apk';

      // Download the file
      await _dio.download(
        fullDownloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (onProgress != null) {
            onProgress(received, total);
          }
        },
      );

      // Install the APK
      if (await File(savePath).exists()) {
        await OpenFilex.open(savePath);
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.downloadFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.onError),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.updateCheckFailed}: ${e.toString()}',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return false;
    }
  }

  // Note: showUpdateDialog is deprecated in favor of the expandable update section
  // This method is kept for backward compatibility if needed elsewhere
  void showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: updateInfo.forceUpdate ? false : true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              updateInfo.forceUpdate ? Icons.warning : Icons.system_update,
              color: updateInfo.forceUpdate ? Colors.red : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              updateInfo.forceUpdate
                  ? l10n.requiredUpdate
                  : l10n.updateAvailable,
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.versionAvailable(updateInfo.latestVersion ?? '')),
              if (updateInfo.changelog != null &&
                  updateInfo.changelog!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.whatsNew,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: SingleChildScrollView(
                    child: Text(updateInfo.changelog!),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!updateInfo.forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.later),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Return to preference screen where update section will be shown
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: updateInfo.forceUpdate
                  ? Colors.red
                  : Colors.blue,
            ),
            child: Text(l10n.updateNow),
          ),
        ],
      ),
    );
  }
}
