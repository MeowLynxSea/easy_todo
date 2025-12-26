import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/providers/language_provider.dart';
import 'package:easy_todo/providers/theme_provider.dart';
import 'package:easy_todo/providers/app_settings_provider.dart';
import 'package:easy_todo/providers/pomodoro_provider.dart';
import 'package:easy_todo/screens/language_settings_screen.dart';
import 'package:easy_todo/services/backup_restore_service.dart';
import 'package:easy_todo/services/file_service.dart';
import 'package:easy_todo/services/update_service.dart';
import 'package:easy_todo/models/update_model.dart';
import 'package:easy_todo/screens/storage_screen.dart';
import 'package:easy_todo/screens/backup_restore_screen.dart';
import 'package:easy_todo/screens/notification_settings_screen.dart';
import 'package:easy_todo/screens/view_settings_screen.dart';
import 'package:easy_todo/screens/about_screen.dart';
import 'package:easy_todo/screens/theme_settings_screen.dart';
import 'package:easy_todo/screens/pomodoro_settings_screen.dart';
import 'package:easy_todo/screens/ai_settings_screen.dart';
import 'package:easy_todo/providers/ai_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  final BackupRestoreService _backupService = BackupRestoreService();
  final UpdateService _updateService = UpdateService();
  Map<String, dynamic>? _storageStats;
  PackageInfo? _packageInfo;
  UpdateInfo? _updateInfo;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
  }

  Future<void> _loadStorageStats() async {
    final stats = await _backupService.getStorageStats();
    if (mounted) {
      setState(() {
        _storageStats = stats;
      });
    }
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await _updateService.getPackageInfo();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appSettingsProvider = Provider.of<AppSettingsProvider>(context);
    final aiProvider = Provider.of<AIProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferences), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appSettings,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceItem(
                    icon: Icons.notifications_outlined,
                    title: l10n.notifications,
                    subtitle: l10n.notificationsSubtitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  _buildPreferenceItem(
                    icon: Icons.dark_mode_outlined,
                    title: l10n.theme,
                    subtitle: themeProvider.getThemeModeText(context),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ThemeSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  _buildPreferenceItem(
                    icon: Icons.timer_outlined,
                    title: l10n.pomodoroTimer,
                    subtitle: l10n.pomodoroSettings,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PomodoroSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  _buildPreferenceItem(
                    icon: Icons.smart_toy_outlined,
                    title: l10n.aiSettings,
                    subtitle: aiProvider.settings.enableAIFeatures
                        ? l10n.aiEnabled
                        : l10n.aiDisabled,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AISettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  _buildPreferenceItem(
                    icon: Icons.language_outlined,
                    title: l10n.language,
                    subtitle: _getCurrentLanguageName(
                      languageProvider.locale.languageCode,
                      l10n,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LanguageSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  if (!kIsWeb) ...[
                    const Divider(),
                    _buildFingerprintLockItem(appSettingsProvider, l10n),
                    const Divider(),
                    _buildAutoUpdateItem(appSettingsProvider, l10n),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.viewSettings,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceItem(
                    icon: Icons.view_carousel_outlined,
                    title: l10n.viewDisplay,
                    subtitle: l10n.viewDisplaySubtitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ViewSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dataStorage,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceItem(
                    icon: Icons.backup_outlined,
                    title: l10n.backupRestore,
                    subtitle: l10n.backupSubtitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BackupRestoreScreen(),
                        ),
                      ).then((_) {
                        _loadStorageStats();
                      });
                    },
                  ),
                  const Divider(),
                  _buildPreferenceItem(
                    icon: Icons.storage_outlined,
                    title: l10n.storage,
                    subtitle: _storageStats != null
                        ? '${_storageStats!['todos']['total']} ${l10n.todos.toLowerCase()}, ${FileService.formatFileSize(_storageStats!['storage']['dataSize'])}'
                        : l10n.storageSubtitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StorageScreen(),
                        ),
                      ).then((_) {
                        _loadStorageStats();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.about,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceItem(
                    icon: Icons.info_outlined,
                    title: l10n.aboutEasyTodo,
                    subtitle: _packageInfo != null
                        ? _packageInfo!.version
                        : l10n.version,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  if (!kIsWeb) ...[
                    const Divider(),
                    _buildUpdateSection(l10n),
                  ],
                  const Divider(),
                  _buildPreferenceItem(
                    icon: Icons.help_outline,
                    title: l10n.helpSupport,
                    subtitle: l10n.helpSubtitle,
                    onTap: () {
                      _showHelpSupportDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dangerZone,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceItem(
                    icon: Icons.delete_outline,
                    title: l10n.clearAllData,
                    subtitle: l10n.clearDataSubtitle,
                    onTap: () {
                      _showClearDataDialog();
                    },
                    iconColor: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showHelpSupportDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.helpSupport),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.developerInfo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildContactItem(
              icon: Icons.person,
              title: l10n.developer,
              subtitle: l10n.developerNameMeowLynxSea,
            ),
            const SizedBox(height: 8),
            _buildContactItem(
              icon: Icons.email,
              title: l10n.email,
              subtitle: l10n.developerEmail,
              onTap: () => _launchUrl('mailto:${l10n.developerEmail}'),
            ),
            const SizedBox(height: 8),
            _buildContactItem(
              icon: Icons.code,
              title: l10n.github,
              subtitle: l10n.developerGithub,
              onTap: () => _launchUrl('https://${l10n.developerGithub}'),
            ),
            const SizedBox(height: 8),
            _buildContactItem(
              icon: Icons.language,
              title: l10n.website,
              subtitle: l10n.developerWebsite,
              onTap: () => _launchUrl('https://www.meowdream.cn'),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.needHelp,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.helpDescription,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Copy to clipboard
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.copiedToClipboard(url)),
              action: SnackBarAction(
                label: l10n.ok,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Fallback: Copy to clipboard on error
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cannotOpenLink(url)),
            action: SnackBarAction(
              label: l10n.ok,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    final l10n = AppLocalizations.of(context)!;
    final appSettingsProvider = Provider.of<AppSettingsProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearAllData),
        content: Text(
          l10n.clearDataWarning,
          style: const TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final todoProvider = Provider.of<TodoProvider>(
                context,
                listen: false,
              );
              final pomodoroProvider = Provider.of<PomodoroProvider>(
                context,
                listen: false,
              );

              Navigator.of(dialogContext).pop();

              // 仅在开启生物识别验证时需要验证
              if (appSettingsProvider.biometricLockEnabled) {
                final authenticated = await appSettingsProvider
                    .authenticateForSensitiveOperation(
                      reason: l10n.authenticateToClearData,
                    );
                if (!context.mounted) return;

                if (!authenticated) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.fingerprintAuthenticationFailed),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }

              // 生物识别通过或未开启生物识别验证，继续清除数据
              try {
                await todoProvider.clearAllData();
                pomodoroProvider.resetAllState();
                await _loadStorageStats();
                if (!context.mounted) return;

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.dataClearedSuccess),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${l10n.clearDataFailed}: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.clearAllData),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoUpdateItem(
    AppSettingsProvider provider,
    AppLocalizations l10n,
  ) {
    return ListTile(
      leading: Icon(
        Icons.system_update,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        l10n.autoUpdate,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        l10n.autoUpdateSubtitle,
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: Switch(
        value: provider.autoUpdateEnabled,
        onChanged: (value) async {
          final messenger = ScaffoldMessenger.of(context);
          await provider.setAutoUpdate(value);
          if (!context.mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                value ? l10n.autoUpdateEnabled : l10n.autoUpdateDisabled,
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFingerprintLockItem(
    AppSettingsProvider provider,
    AppLocalizations l10n,
  ) {
    return FutureBuilder<bool>(
      future: provider.isFingerprintAvailable(),
      builder: (context, snapshot) {
        final isAvailable = snapshot.data ?? false;

        if (!isAvailable) {
          return _buildPreferenceItem(
            icon: Icons.fingerprint,
            title: l10n.fingerprintLock,
            subtitle: l10n.fingerprintNotAvailable,
            onTap: () {},
            iconColor: Colors.grey,
          );
        }

        return ListTile(
          leading: Icon(
            Icons.fingerprint,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            l10n.fingerprintLock,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            l10n.fingerprintLockSubtitle,
            style: TextStyle(color: Colors.grey[600]),
          ),
          trailing: Switch(
            value: provider.biometricLockEnabled,
            onChanged: (value) async {
              final messenger = ScaffoldMessenger.of(context);
              final success = await provider.setFingerprintLock(
                value,
                enableReason: l10n.authenticateToEnableFingerprint,
                disableReason: l10n.authenticateToDisableFingerprint,
              );
              if (!context.mounted) return;

              if (success) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? l10n.fingerprintLockEnabled
                          : l10n.fingerprintLockDisabled,
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                return;
              }

              messenger.showSnackBar(
                SnackBar(
                  content: Text(l10n.fingerprintAuthenticationFailed),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUpdateSection(AppLocalizations l10n) {
    return Column(
      children: [
        _buildPreferenceItem(
          icon: Icons.system_update_outlined,
          title: l10n.checkForUpdates,
          subtitle: _updateInfo?.updateAvailable == true
              ? '${l10n.updateAvailable}: ${_updateInfo?.latestVersion ?? ''}'
              : l10n.checkUpdatesSubtitle,
          onTap: () {
            if (_updateInfo?.updateAvailable != true) {
              _checkForUpdates();
            }
          },
        ),
        if (_updateInfo?.updateAvailable == true) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.new_releases, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.updateAvailable}: ${_updateInfo?.latestVersion ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_updateInfo?.changelog?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.whatsNew,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: SingleChildScrollView(
                      child: Text(
                        _updateInfo!.changelog!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_isDownloading) ...[
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: _downloadProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _downloadUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.updateNow),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _checkForUpdates() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final updateInfo = await _updateService.checkForUpdates();

      setState(() {
        _updateInfo = updateInfo;
      });

      if (updateInfo.updateAvailable) {
        // Update available, show the expanded section
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.updateAvailable,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.youHaveLatestVersion,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
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
    }
  }

  Future<void> _downloadUpdate() async {
    if (_updateInfo?.downloadUrl == null) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final success = await _updateService.downloadAndInstallUpdate(
        context,
        _updateInfo!.downloadUrl!,
        onProgress: (received, total) {
          setState(() {
            _downloadProgress = total > 0 ? received / total : 0.0;
          });
        },
      );

      setState(() {
        _isDownloading = false;
      });

      if (success && mounted) {
        setState(() {
          _downloadProgress = 1.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.updateDownloadSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });

      if (mounted) {
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
    }
  }

  String _getCurrentLanguageName(String languageCode, AppLocalizations l10n) {
    switch (languageCode) {
      case 'zh':
        return l10n.chinese;
      case 'en':
        return l10n.english;
      case 'es':
        return l10n.spanish;
      case 'fr':
        return l10n.french;
      case 'de':
        return l10n.german;
      case 'ja':
        return l10n.japanese;
      case 'ko':
        return l10n.korean;
      default:
        return languageCode.toUpperCase();
    }
  }
}
