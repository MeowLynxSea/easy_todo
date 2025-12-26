import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/services/backup_restore_service.dart';
import 'package:easy_todo/services/file_service.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/widgets/web_desktop_content.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final BackupRestoreService _backupService = BackupRestoreService();
  Map<String, dynamic>? _backupStats;
  List<Map<String, dynamic>>? _backupFiles;
  bool _isLoading = false;
  late AppLocalizations _l10n;

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _backupService.getStorageStats();
      final files = await _backupService.getBackupFiles();

      setState(() {
        _backupStats = stats;
        _backupFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _l10n = l10n; // Store for async methods
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupRestore), centerTitle: true),
      body: _isLoading
          ? const WebDesktopContent(
              padding: EdgeInsets.zero,
              child: Center(child: CircularProgressIndicator()),
            )
          : RefreshIndicator(
              onRefresh: _loadBackupInfo,
              child: WebDesktopContent(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBackupSummaryCard(l10n),
                      const SizedBox(height: 20),
                      _buildQuickActionsCard(l10n),
                      const SizedBox(height: 20),
                      _buildBackupFilesCard(l10n),
                      const SizedBox(height: 20),
                      _buildBackupInfoCard(l10n),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBackupSummaryCard(AppLocalizations l10n) {
    if (_backupStats == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text(l10n.unableToLoadBackupStats)),
        ),
      );
    }

    final todoCount = _backupStats!['todos']['total'];
    final dataSize = _backupStats!['storage']['dataSize'];
    final backupFiles = _backupStats!['storage']['backupFiles'];
    final repeatTodosCount = _backupStats!['repeatTodos']?['total'] ?? 0;
    final dataStatsCount = _backupStats!['statisticsData']?['total'] ?? 0;
    final pomodoroCount = _backupStats!['pomodoro']?['total'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.backupSummary,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.task_alt,
                    title: l10n.todos,
                    value: '$todoCount',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.repeat,
                    title: l10n.repeatTasks,
                    value: '$repeatTodosCount',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.analytics,
                    title: l10n.dataEntries(dataStatsCount),
                    value: '$dataStatsCount',
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.timer,
                    title: l10n.pomodoroSessions,
                    value: '$pomodoroCount',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.storage,
                    title: l10n.dataSize,
                    value: _formatFileSize(dataSize),
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.backup_outlined,
                    title: l10n.backupFiles,
                    value: '$backupFiles',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.quickActions,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.backupRestoreDescription,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _performBackup,
                    icon: const Icon(Icons.backup),
                    label: Text(l10n.createBackup),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _performRestore,
                    icon: const Icon(Icons.restore),
                    label: Text(l10n.restoreBackup),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importBackup,
                    icon: const Icon(Icons.file_upload),
                    label: Text(l10n.importBackup),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupFilesCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.backupFiles,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _loadBackupInfo,
                  icon: const Icon(Icons.refresh),
                  tooltip: l10n.refresh,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _backupFiles == null || _backupFiles!.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.backup_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noBackupFilesFound,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.createFirstBackup,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _backupFiles!.length,
                    itemBuilder: (context, index) {
                      final file = _backupFiles![index];
                      return _buildBackupFileItem(file);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupFileItem(Map<String, dynamic> file) {
    final fileName = file['fileName'] ?? _l10n.unknown;
    final fileSize = _formatFileSize(file['fileSize'] ?? 0);
    final fileDate = file['fileDate'] ?? _l10n.unknownDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.backup, color: AppTheme.primaryColor),
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('$fileSize • $fileDate'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'restore':
                _restoreFromFile(file);
                break;
              case 'share':
                _shareBackupFile(file);
                break;
              case 'delete':
                _deleteBackupFile(file);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'restore',
              child: ListTile(
                leading: const Icon(Icons.restore),
                title: Text(_l10n.restoreFromFile),
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: const Icon(Icons.share),
                title: Text(_l10n.shareBackup),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  _l10n.deleteFile,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupInfoCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.aboutBackups,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(l10n.backupInfo1, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(l10n.backupInfo2, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(l10n.backupInfo3, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(l10n.backupInfo4, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Future<void> _performBackup() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _backupService.backupData();

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_l10n.backupCreatedSuccess}: ${result['fileName']}',
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: _l10n.ok,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
        await _loadBackupInfo();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_l10n.backupFailed}: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_l10n.backupFailed}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performRestore() async {
    if (!_backupFiles!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.noBackupFilesAvailable),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show file selection dialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.selectBackupFile),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _backupFiles!.length,
            itemBuilder: (context, index) {
              final file = _backupFiles![index];
              return ListTile(
                title: Text(file['fileName'] ?? _l10n.unknown),
                subtitle: Text(
                  '${_formatFileSize(file['fileSize'] ?? 0)} • ${file['fileDate'] ?? _l10n.unknownDate}',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _restoreFromFile(file);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreFromFile(Map<String, dynamic> file) async {
    final fileName = file['fileName'] ?? _l10n.unknown;
    final messenger = ScaffoldMessenger.of(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.confirmRestore),
        content: Text(_l10n.restoreWarning(fileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(_l10n.restoreBackup),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Restore data from the actual file
      final restoreResult = await _backupService.restoreData(file['filePath']);

      if (!mounted) return;

      if (restoreResult['success']) {
        // Refresh all data in the TodoProvider
        final todoProvider = Provider.of<TodoProvider>(context, listen: false);
        await todoProvider.refreshAllData();
        if (!mounted) return;

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${_l10n.dataRestoredSuccess(fileName)} (${_l10n.restoreSuccessPrefix}${restoreResult['todosCount']}${_l10n.restoreSuccessSuffix})',
            ),
            backgroundColor: Colors.green,
          ),
        );

        await _loadBackupInfo();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${_l10n.restoreFailed}: ${restoreResult['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${_l10n.restoreFailed}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _importBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(_l10n.cannotAccessFile),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate file format
      final selectedFile = File(file.path!);
      final content = await selectedFile.readAsString();
      if (!mounted) return;

      if (!_validateBackupFormat(content)) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(_l10n.invalidBackupFormat),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_l10n.importBackupTitle),
          content: Text(_l10n.importingBackupFile(file.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(_l10n.import),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      if (!mounted) return;

      setState(() {
        _isLoading = true;
      });

      // Copy file to backup directory
      final backupDir = await FileService.getAppDirectory();
      final targetFile = File('${backupDir.path}/${file.name}');
      await selectedFile.copy(targetFile.path);

      // Restore from the copied file
      final restoreResult = await _backupService.restoreData(targetFile.path);

      if (!mounted) return;

      if (restoreResult['success']) {
        // Refresh all data in the TodoProvider
        final todoProvider = Provider.of<TodoProvider>(context, listen: false);
        await todoProvider.refreshAllData();
        if (!mounted) return;

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${_l10n.importSuccessPrefix}${restoreResult['todosCount']}${_l10n.restoreSuccessSuffix}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the backup files list
        await _loadBackupInfo();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${_l10n.importFailedPrefix}${restoreResult['error']}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${_l10n.importFailedPrefix}${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateBackupFormat(String content) {
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      return data.containsKey('version') &&
          data.containsKey('backupDate') &&
          data.containsKey('todos') &&
          data.containsKey('statistics') &&
          data['todos'] is List &&
          data['statistics'] is List;
    } catch (e) {
      return false;
    }
  }

  Future<void> _shareBackupFile(Map<String, dynamic> file) async {
    final fileName = file['fileName'] ?? _l10n.unknown;
    final filePath = file['filePath'];
    final messenger = ScaffoldMessenger.of(context);

    if (filePath == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_l10n.invalidFilePath(fileName)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final backupFile = File(filePath);
      if (!await backupFile.exists()) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('${_l10n.backupFileNotFound}: $fileName'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await FileService.shareBackupFile(
        backupFile,
        subject: 'Easy Todo 备份文件 - $fileName',
      );

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(_l10n.backupShareSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${_l10n.shareFailedPrefix}${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBackupFile(Map<String, dynamic> file) async {
    final fileName = file['fileName'] ?? _l10n.unknown;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.deleteBackupFile),
        content: Text(_l10n.deleteBackupWarning(fileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(_l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Actually delete the file from storage
      final filePath = file['filePath'];
      if (filePath != null) {
        final backupFile = File(filePath);
        if (await backupFile.exists()) {
          await backupFile.delete();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_l10n.backupFileDeletedSuccess(fileName)),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the backup files list
          await _loadBackupInfo();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_l10n.backupFileNotFound}: $fileName'),
              backgroundColor: Colors.orange,
            ),
          );
          // Refresh the list anyway to remove the non-existent file
          await _loadBackupInfo();
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l10n.invalidFilePath(fileName)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_l10n.failedToDeleteFile}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
