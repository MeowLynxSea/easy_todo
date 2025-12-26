import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:share_plus/share_plus.dart';

class FileService {
  static const String _backupFolder = 'easy_todo_backups';

  /// 获取应用文档目录
  static Future<Directory> getAppDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDocDir.path}/$_backupFolder');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  /// 生成备份文件名
  static String generateBackupFileName() {
    // 确保时区已初始化
    try {
      tz.initializeTimeZones();

      // 使用更完整的时区检测逻辑
      final localTimeZoneName = DateTime.now().timeZoneName;
      String? timeZoneId;

      if (localTimeZoneName.contains('CST') || localTimeZoneName.contains('GMT+8') || localTimeZoneName.contains('UTC+8')) {
        timeZoneId = 'Asia/Shanghai';
      } else if (localTimeZoneName.contains('PST') || localTimeZoneName.contains('GMT-8')) {
        timeZoneId = 'America/Los_Angeles';
      } else if (localTimeZoneName.contains('EST') || localTimeZoneName.contains('GMT-5')) {
        timeZoneId = 'America/New_York';
      } else if (localTimeZoneName.contains('JST') || localTimeZoneName.contains('GMT+9')) {
        timeZoneId = 'Asia/Tokyo';
      } else if (localTimeZoneName.contains('GMT')) {
        final offset = DateTime.now().timeZoneOffset.inHours;
        if (offset == 8) {
          timeZoneId = 'Asia/Shanghai';
        } else if (offset == 9) {
          timeZoneId = 'Asia/Tokyo';
        } else if (offset == -5) {
          timeZoneId = 'America/New_York';
        } else if (offset == -8) {
          timeZoneId = 'America/Los_Angeles';
        }
      }

      if (timeZoneId != null) {
        try {
          final location = tz.getLocation(timeZoneId);
          tz.setLocalLocation(location);
          // debugPrint('FileService: Set timezone to $timeZoneId');
        } catch (e) {
          debugPrint('FileService: Failed to set timezone: $e');
        }
      }

      final now = tz.TZDateTime.now(tz.local);
      final formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
      return 'easy_todo_backup_${formatter.format(now)}.json';
    } catch (e) {
      debugPrint('FileService: Timezone initialization failed: $e');
      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
      return 'easy_todo_backup_${formatter.format(now)}.json';
    }
  }

  /// 获取所有备份文件
  static Future<List<File>> getBackupFiles() async {
    final backupDir = await getAppDirectory();
    final files = await backupDir
        .list()
        .where((entity) => entity is File)
        .cast<File>()
        .toList();

    // 按修改时间降序排序
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return files;
  }

  /// 删除备份文件
  static Future<bool> deleteBackupFile(File file) async {
    try {
      await file.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取文件大小（格式化）
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 检查存储空间
  static Future<Map<String, int>> getStorageInfo() async {
    try {
      final backupDir = await getAppDirectory();

      // 获取备份目录大小
      int backupSize = 0;
      if (await backupDir.exists()) {
        await for (var entity in backupDir.list(recursive: true)) {
          if (entity is File) {
            backupSize += await entity.length();
          }
        }
      }

      return {
        'backupSize': backupSize,
        'totalFiles': (await getBackupFiles()).length,
      };
    } catch (e) {
      return {'backupSize': 0, 'totalFiles': 0};
    }
  }

  /// 分享备份文件
  static Future<void> shareBackupFile(File file, {String? subject}) async {
    try {
      final XFile xFile = XFile(file.path, name: file.uri.pathSegments.last);
      await Share.shareXFiles([xFile], subject: subject ?? 'Easy Todo 备份文件');
    } catch (e) {
      throw Exception('分享失败: $e');
    }
  }
}
