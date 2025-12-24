import 'package:dio/dio.dart';
import 'package:easy_todo/models/update_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class UpdateService {
  final Dio _dio = Dio();
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
      // Request storage permission with user explanation
      if (!await _requestStoragePermissionWithDialog(context)) {
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

      // Get download directory - use app-specific directory for Android 10+
      Directory? directory;
      if (Platform.isAndroid) {
        // For Android 10+, use application-specific directory
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getExternalStorageDirectory();
      }

      if (directory == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.cannotAccessStorage,
                style: TextStyle(color: Theme.of(context).colorScheme.onError),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return false;
      }

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

  Future<bool> _requestStoragePermissionWithDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    if (Platform.isAndroid) {
      // For Android 10+, we can use app-specific directories without special permissions
      // For older Android versions, we need storage permission
      if (await _isAndroid10OrHigher()) {
        return true; // No permission needed for app-specific directories
      }

      // Check if permissions are already granted for older Android versions
      bool storageGranted = await Permission.storage.isGranted;

      if (storageGranted) {
        return true;
      }

      // Show explanation dialog for older Android versions
      bool userApproved =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(l10n.storagePermissionTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.storagePermissionDescription),
                  SizedBox(height: 8),
                  Text(l10n.permissionNote),
                  SizedBox(height: 4),
                  Text(l10n.accessDeviceStorage),
                  Text(l10n.downloadFilesToDevice),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.allow),
                ),
              ],
            ),
          ) ??
          false;

      if (!userApproved) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.storagePermissionDenied,
                style: TextStyle(color: Theme.of(context).colorScheme.onError),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return false;
      }

      // Request storage permission (standard permission)
      PermissionStatus status = await Permission.storage.request();

      if (status == PermissionStatus.granted) {
        return true;
      }

      // If permission is permanently denied, show dialog to open settings
      if (status == PermissionStatus.permanentlyDenied) {
        bool shouldOpenSettings =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.permissionDenied),
                content: Text(l10n.permissionDeniedMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.openSettings),
                  ),
                ],
              ),
            ) ??
            false;

        if (shouldOpenSettings) {
          // Open app settings
          bool opened = await openAppSettings();
          if (!opened && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.cannotOpenSettings,
                  style: TextStyle(color: Theme.of(context).colorScheme.onError),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.storagePermissionDenied,
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }

      return false;
    }
    return true;
  }

  Future<bool> _isAndroid10OrHigher() async {
    if (!Platform.isAndroid) return false;

    // For Android 10 (API 29) and higher, use scoped storage
    // We don't need special permissions for app-specific directories
    return true; // Assume Android 10+ by default, most devices are
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
