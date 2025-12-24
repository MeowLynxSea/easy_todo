import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/services/notification_service.dart';
import 'package:easy_todo/models/notification_settings_model.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  NotificationSettingsModel? _settings;
  bool _isLoading = true;
  bool? _hasPermission;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      _settings = _notificationService.settings;
      await _checkNotificationPermission();
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkNotificationPermission() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final permission =
          await plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;
      setState(() => _hasPermission = permission);
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      setState(() => _hasPermission = false);
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final androidPlugin = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted =
          await androidPlugin?.requestNotificationsPermission() ?? false;

      setState(() => _hasPermission = granted);

      if (!granted) {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      setState(() => _hasPermission = false);
    }
  }

  void _showPermissionDeniedDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notificationPermissions),
        content: Text(l10n.permissionsDenied),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      // 先发送一个立即的测试通知
      await _notificationService.sendTestNotification(
        l10n.testNotification,
        l10n.testNotificationContent,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.notificationTestSent),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.failedToSendTestNotification}${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_settings == null) return;

    final updatedSettings = _settings!.copyWith(notificationsEnabled: value);
    await _notificationService.updateSettings(updatedSettings);
    setState(() => _settings = updatedSettings);
  }

  Future<void> _toggleDailySummary(bool value) async {
    if (_settings == null) return;

    final updatedSettings = _settings!.copyWith(dailySummaryEnabled: value);
    await _notificationService.updateSettings(updatedSettings);
    setState(() => _settings = updatedSettings);
  }

  Future<void> _selectDailySummaryTime() async {
    if (_settings == null) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _settings!.dailySummaryTime,
    );

    if (picked != null) {
      final updatedSettings = _settings!.copyWith(dailySummaryTime: picked);
      await _notificationService.updateSettings(updatedSettings);
      setState(() => _settings = updatedSettings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.notificationSettings),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationSettings), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPermissionCard(l10n),
          const SizedBox(height: 16),
          _buildGeneralSettingsCard(l10n),
          const SizedBox(height: 16),
          _buildDailySummaryCard(l10n),
          const SizedBox(height: 16),
          _buildTestCard(l10n),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: _hasPermission == true ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.notificationPermissions,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_hasPermission == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.permissionsGranted,
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.permissionsDenied,
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_hasPermission != true)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requestNotificationPermission,
                  child: Text(l10n.grantPermissions),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettingsCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.enableNotifications,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l10n.enableNotifications),
              subtitle: Text(
                _settings?.notificationsEnabled == true
                    ? l10n.enableReminder
                    : l10n.cancelReminder,
              ),
              value: _settings?.notificationsEnabled ?? false,
              onChanged: _hasPermission == true ? _toggleNotifications : null,
              secondary: Icon(
                Icons.notifications_active_outlined,
                color: _settings?.notificationsEnabled == true
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dailySummary,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dailySummaryDescription,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l10n.dailySummary),
              subtitle: Text(
                _settings?.dailySummaryEnabled == true
                    ? l10n.enableReminder
                    : l10n.cancelReminder,
              ),
              value: _settings?.dailySummaryEnabled ?? false,
              onChanged: (_settings?.notificationsEnabled ?? false)
                  ? _toggleDailySummary
                  : null,
              secondary: Icon(
                Icons.summarize_outlined,
                color: _settings?.dailySummaryEnabled == true
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
            if (_settings?.dailySummaryEnabled == true) ...[
              const Divider(),
              ListTile(
                title: Text(l10n.dailySummaryTime),
                subtitle: Text(
                  '${_settings?.dailySummaryTime.hour.toString().padLeft(2, '0')}:${_settings?.dailySummaryTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: _selectDailySummaryTime,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.testNotification,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasPermission == true
                    ? _sendTestNotification
                    : null,
                child: Text(l10n.sendTestNotification),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
