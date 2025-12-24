import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/services/backup_restore_service.dart';
import 'package:easy_todo/services/file_service.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:easy_todo/providers/todo_provider.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  final BackupRestoreService _backupService = BackupRestoreService();
  Map<String, dynamic>? _storageStats;
  late AppLocalizations _l10n;

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
  }

  Future<void> _loadStorageStats() async {
    final stats = await _backupService.getStorageStats();
    setState(() {
      _storageStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _l10n = l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.storageManagement), centerTitle: true),
      body: _storageStats == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStorageOverviewCard(),
                  const SizedBox(height: 20),
                  _buildChartsSection(),
                  const SizedBox(height: 20),
                  _buildCleanupOptions(),
                ],
              ),
            ),
    );
  }

  Widget _buildStorageOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _l10n.storageOverview,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.task_alt,
                    title: _l10n.totalTodos,
                    value: '${_storageStats!['todos']['total']}',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    title: _l10n.completed,
                    value: '${_storageStats!['todos']['completed']}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.pending_actions,
                    title: _l10n.pending,
                    value: '${_storageStats!['todos']['pending']}',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.timer,
                    title: _l10n.pomodoroSessions,
                    value: '${_storageStats!['pomodoro']?['total'] ?? 0}',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.storage,
                    title: _l10n.dataSize,
                    value: FileService.formatFileSize(
                      _storageStats!['storage']['dataSize'],
                    ),
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.schedule,
                    title: _l10n.focusTime,
                    value: _formatDuration(_storageStats!['pomodoro']?['totalFocusTime'] ?? 0),
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    final completedTodos = _storageStats!['todos']['completed'];
    final pendingTodos = _storageStats!['todos']['pending'];
    final dataSize = _storageStats!['storage']['dataSize'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _l10n.storageAnalytics,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTodoStatusChart(completedTodos, pendingTodos),
            const SizedBox(height: 20),
            _buildStorageBreakdownChart(dataSize),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoStatusChart(int completed, int pending) {
    final total = completed + pending;
    if (total == 0) {
      return Center(
        child: Text(
          _l10n.noTodosToDisplay,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    final pendingPercentage = (pending / total * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _l10n.todoStatusDistribution,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: completed,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${((completed / total * 100).round())}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: pending,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$pendingPercentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(Colors.green, _l10n.completed, completed),
            _buildLegendItem(Colors.orange, _l10n.pending, pending),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, int value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($value)',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStorageBreakdownChart(int dataSize) {
    // Create a visual representation of storage usage
    final sizeInKB = dataSize / 1024;
    final displaySize = sizeInKB > 1024
        ? '${(sizeInKB / 1024).toStringAsFixed(1)} MB'
        : '${sizeInKB.toStringAsFixed(1)} KB';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _l10n.dataStorageUsage,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (dataSize / 1024 / 1024).clamp(
            0,
            1,
          ), // Assume 1MB as max for visualization
          backgroundColor: Colors.grey[200],
          color: AppTheme.primaryColor,
          minHeight: 24,
        ),
        const SizedBox(height: 8),
        Text(
          '${_l10n.total}: $displaySize',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCleanupOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _l10n.storageCleanup,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              _l10n.cleanupDescription,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await _backupService.cleanupData(
                      clearCompleted: true,
                    );
                    await _loadStorageStats();
                    await _refreshAllPages();
                    _showCleanupResult(result);
                  },
                  icon: const Icon(Icons.cleaning_services),
                  label: Text(_l10n.clearCompletedTodos),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await _backupService.cleanupData(
                      clearOldStatistics: true,
                    );
                    await _loadStorageStats();
                    await _refreshAllPages();
                    _showCleanupResult(result);
                  },
                  icon: const Icon(Icons.delete_sweep),
                  label: Text(_l10n.clearOldStatistics),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await _backupService.cleanupData(
                      clearBackupFiles: true,
                    );
                    await _loadStorageStats();
                    await _refreshAllPages();
                    _showCleanupResult(result);
                  },
                  icon: const Icon(Icons.backup_outlined),
                  label: Text(_l10n.clearBackupFiles),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await _backupService.cleanupData(
                      clearOldPomodoroSessions: true,
                    );
                    await _loadStorageStats();
                    await _refreshAllPages();
                    _showCleanupResult(result);
                  },
                  icon: const Icon(Icons.timer_off),
                  label: Text(_l10n.clearOldPomodoroSessions),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshAllPages() async {
    // Refresh TodoProvider to reload todos and statistics from storage
    if (mounted) {
      final todoProvider = Provider.of<TodoProvider>(context, listen: false);
      await todoProvider.refreshAllData();
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).round()}m';
    return '${(seconds / 3600).round()}h';
  }

  void _showCleanupResult(Map<String, dynamic> result) {
    if (result['success']) {
      final todosDeleted = result['todosDeleted'] ?? 0;
      final statisticsDeleted = result['statisticsDeleted'] ?? 0;
      final pomodoroSessionsDeleted = result['pomodoroSessionsDeleted'] ?? 0;
      final backupFilesDeleted = result['backupFilesDeleted'] ?? 0;

      String message = _l10n.cleanupCompleted;
      if (todosDeleted > 0) message += ': ${_l10n.todosDeleted(todosDeleted)}';
      if (statisticsDeleted > 0) {
        message += ', ${_l10n.statisticsDeleted(statisticsDeleted)}';
      }
      if (pomodoroSessionsDeleted > 0) {
        message += ', ${_l10n.pomodoroSessionsDeleted(pomodoroSessionsDeleted)}';
      }
      if (backupFilesDeleted > 0) {
        message += ', ${_l10n.backupFilesDeleted(backupFilesDeleted)}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_l10n.cleanupFailedPrefix}${result['error']}',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
