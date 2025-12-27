import 'package:easy_todo/providers/ai_provider.dart';
import 'package:easy_todo/providers/app_settings_provider.dart';
import 'package:easy_todo/providers/filter_provider.dart';
import 'package:easy_todo/providers/language_provider.dart';
import 'package:easy_todo/providers/pomodoro_provider.dart';
import 'package:easy_todo/providers/sync_provider.dart';
import 'package:easy_todo/providers/theme_provider.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/services/crypto/sync_crypto.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  bool _showToken = false;
  bool _isEnabling = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkServer() async {
    final l10n = AppLocalizations.of(context)!;
    final sync = context.read<SyncProvider>();
    try {
      await sync.checkServerHealth();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cloudSyncServerOkSnack)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cloudSyncServerCheckFailedSnack)),
      );
    }
  }

  Future<bool> _showServerConfigDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final sync = context.read<SyncProvider>();
    final serverUrlController = TextEditingController(text: sync.serverUrl);
    final tokenController = TextEditingController(text: sync.authToken);

    return (await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(l10n.cloudSyncSetupDialogTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: serverUrlController,
                    decoration: InputDecoration(
                      labelText: l10n.cloudSyncServerUrl,
                      hintText: l10n.cloudSyncServerUrlHint,
                      prefixIcon: const Icon(Icons.link_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tokenController,
                    obscureText: !_showToken,
                    decoration: InputDecoration(
                      labelText: l10n.cloudSyncBearerToken,
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        tooltip: _showToken
                            ? l10n.cloudSyncHideToken
                            : l10n.cloudSyncShowToken,
                        onPressed: () =>
                            setState(() => _showToken = !_showToken),
                        icon: Icon(
                          _showToken
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(context).pop(true);
                    await sync.configure(
                      serverUrl: serverUrlController.text,
                      authToken: tokenController.text,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.cloudSyncConfigSaved)),
                    );
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        )) ??
        false;
  }

  Future<void> _guidedEnableFlow() async {
    final l10n = AppLocalizations.of(context)!;
    final sync = context.read<SyncProvider>();
    if (sync.status == SyncStatus.running) return;

    if (!sync.isConfigured) {
      final ok = await _showServerConfigDialog();
      if (!ok) return;
      if (!mounted) return;
    }

    if (!mounted) return;
    final passphraseController = TextEditingController();
    final confirmController = TextEditingController();
    var obscure = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.cloudSyncEnableDialogTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.cloudSyncPassphraseDialogHint,
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passphraseController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: l10n.cloudSyncPassphrase,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: l10n.cloudSyncConfirmPassphrase,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: !obscure,
                        onChanged: (v) =>
                            setState(() => obscure = !(v ?? false)),
                      ),
                      Text(l10n.cloudSyncShowPassphrase),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.cloudSyncEnable),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;
    if (!mounted) return;

    try {
      await sync.checkServerHealth();
      await sync.enableSync(
        passphrase: passphraseController.text,
        confirmPassphrase: confirmController.text,
      );
    } on InvalidPassphraseException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cloudSyncInvalidPassphrase)),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cloudSyncServerCheckFailedSnack)),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.cloudSyncEnabledSnack)),
    );
  }

  Future<void> _unlock() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    var obscure = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.cloudSyncUnlockDialogTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    obscureText: obscure,
                    decoration: InputDecoration(labelText: l10n.cloudSyncPassphrase),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: !obscure,
                        onChanged: (v) => setState(() => obscure = !(v ?? false)),
                      ),
                      Text(l10n.cloudSyncShowPassphrase),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.cloudSyncUnlock),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;

    if (!mounted) return;
    final sync = context.read<SyncProvider>();
    try {
      await sync.unlock(passphrase: controller.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cloudSyncUnlockedSnack)),
      );
    } on InvalidPassphraseException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cloudSyncInvalidPassphrase)),
      );
    }
  }

  Future<void> _syncNow() async {
    final l10n = AppLocalizations.of(context)!;
    final sync = context.read<SyncProvider>();
    try {
      await sync.syncNow();
    } on SyncRollbackDetectedException {
      if (!mounted) return;
      final choice = await showDialog<_RollbackChoice>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.cloudSyncRollbackTitle),
            content: Text(l10n.cloudSyncRollbackMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(_RollbackChoice.stop),
                child: Text(l10n.cloudSyncStopSync),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(_RollbackChoice.continueSync),
                child: Text(l10n.cloudSyncContinue),
              ),
            ],
          );
        },
      );

      if (choice == _RollbackChoice.stop) {
        await sync.disableSync(forgetDek: false);
        return;
      }

      if (choice == _RollbackChoice.continueSync) {
        await sync.syncNow(allowRollback: true);
      }
    }

    if (!mounted) return;
    await _refreshAppStateAfterSync();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.cloudSyncSyncedSnack)),
    );
  }

  Future<void> _refreshAppStateAfterSync() async {
    final todoProvider = context.read<TodoProvider>();
    final pomodoroProvider = context.read<PomodoroProvider>();
    final aiProvider = context.read<AIProvider>();
    final appSettingsProvider = context.read<AppSettingsProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final filterProvider = context.read<FilterProvider>();

    await todoProvider.refreshAllData();
    await pomodoroProvider.reloadFromHive();
    await aiProvider.reloadFromHive();
    await appSettingsProvider.reloadFromStorage();
    await languageProvider.reloadFromPreferences();
    await themeProvider.reloadFromPreferences();
    await filterProvider.reloadFromPreferences();
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Color _statusColor(BuildContext context, SyncStatus status) {
    return switch (status) {
      SyncStatus.idle => Theme.of(context).colorScheme.primary,
      SyncStatus.running => Theme.of(context).colorScheme.tertiary,
      SyncStatus.error => Theme.of(context).colorScheme.error,
    };
  }

  String? _resolveErrorMessage(SyncProvider sync, AppLocalizations l10n) {
    final code = sync.lastErrorCode;
    if (code == null) return null;

    return switch (code) {
      SyncErrorCode.passphraseMismatch => l10n.cloudSyncErrorPassphraseMismatch,
      SyncErrorCode.notConfigured => l10n.cloudSyncErrorNotConfigured,
      SyncErrorCode.disabled => l10n.cloudSyncErrorDisabled,
      SyncErrorCode.locked => l10n.cloudSyncErrorLocked,
      SyncErrorCode.invalidPassphrase => l10n.cloudSyncInvalidPassphrase,
      SyncErrorCode.unauthorized => l10n.cloudSyncErrorUnauthorized,
      SyncErrorCode.keyBundleNotFound => l10n.cloudSyncErrorKeyBundleNotFound,
      SyncErrorCode.network => l10n.cloudSyncErrorNetwork,
      SyncErrorCode.conflict => l10n.cloudSyncErrorConflict,
      SyncErrorCode.unknown => sync.lastErrorDetail ?? l10n.cloudSyncErrorUnknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cloudSync)),
      body: Consumer<SyncProvider>(
        builder: (context, sync, child) {
          final statusText = switch (sync.status) {
            SyncStatus.idle => l10n.cloudSyncStatusIdle,
            SyncStatus.running => l10n.cloudSyncStatusRunning,
            SyncStatus.error => l10n.cloudSyncStatusError,
          };
          final errorText = _resolveErrorMessage(sync, l10n);
          final statusColor = _statusColor(context, sync.status);
          final configured = sync.isConfigured;
          final canSyncNow =
              configured &&
              sync.syncEnabled &&
              sync.isUnlocked &&
              sync.status != SyncStatus.running;
          final enableSwitchValue = sync.syncEnabled || _isEnabling;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.cloud_sync_outlined,
                            color: statusColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.cloudSyncOverviewTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (sync.status == SyncStatus.running) ...[
                            const SizedBox(width: 12),
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.cloudSyncOverviewSubtitle,
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.cloudSyncEnableSwitchTitle),
                        subtitle: Text(l10n.cloudSyncEnableSwitchSubtitle),
                        value: enableSwitchValue,
                        onChanged: sync.status == SyncStatus.running
                            ? null
                            : (v) async {
                                if (v) {
                                  setState(() => _isEnabling = true);
                                  try {
                                    await _guidedEnableFlow();
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isEnabling = false);
                                    }
                                  }
                                } else {
                                  await sync.disableSync();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.cloudSyncDisabledSnack),
                                    ),
                                  );
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildStatusChip(
                            icon: Icons.info_outline,
                            label: '${l10n.status}: $statusText',
                            color: statusColor,
                          ),
                          _buildStatusChip(
                            icon: sync.syncEnabled
                                ? Icons.toggle_on_outlined
                                : Icons.toggle_off_outlined,
                            label: sync.syncEnabled
                                ? l10n.cloudSyncEnabledOn
                                : l10n.cloudSyncEnabledOff,
                            color: sync.syncEnabled
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).disabledColor,
                          ),
                          _buildStatusChip(
                            icon: sync.isUnlocked
                                ? Icons.lock_open_outlined
                                : Icons.lock_outline,
                            label: sync.isUnlocked
                                ? l10n.cloudSyncUnlockedYes
                                : l10n.cloudSyncUnlockedNo,
                            color: sync.isUnlocked
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                          ),
                          _buildStatusChip(
                            icon: configured
                                ? Icons.link_outlined
                                : Icons.link_off_outlined,
                            label: configured
                                ? l10n.cloudSyncConfiguredYes
                                : l10n.cloudSyncConfiguredNo,
                            color: configured
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                          ),
                        ],
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .errorContainer
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorText,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                        l10n.cloudSyncSetupTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.cloudSyncSetupSubtitle,
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.link_outlined),
                        title: Text(l10n.cloudSyncServerUrl),
                        subtitle: Text(
                          (sync.serverUrl.trim().isEmpty)
                              ? l10n.cloudSyncNotSet
                              : sync.serverUrl.trim(),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.key_outlined),
                        title: Text(l10n.cloudSyncBearerToken),
                        subtitle: Text(
                          (sync.authToken.trim().isEmpty)
                              ? l10n.cloudSyncNotSet
                              : l10n.cloudSyncTokenSet,
                        ),
                        trailing: IconButton(
                          tooltip: _showToken
                              ? l10n.cloudSyncHideToken
                              : l10n.cloudSyncShowToken,
                          onPressed: () => setState(() => _showToken = !_showToken),
                          icon: Icon(
                            _showToken
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      if (_showToken && sync.authToken.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SelectableText(sync.authToken.trim()),
                        )
                      else
                        const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  sync.status == SyncStatus.running
                                      ? null
                                      : () async {
                                          final ok =
                                              await _showServerConfigDialog();
                                          if (!ok) return;
                                          if (!context.mounted) return;
                                        },
                              child: Text(l10n.cloudSyncEditServerConfig),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: sync.status == SyncStatus.running
                                  ? null
                                  : configured
                                  ? _checkServer
                                  : null,
                              child: Text(l10n.cloudSyncCheckServer),
                            ),
                          ),
                        ],
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
                        l10n.cloudSyncSecurityTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.cloudSyncSecuritySubtitle,
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          sync.isUnlocked
                              ? Icons.lock_open_outlined
                              : Icons.lock_outline,
                        ),
                        title: Text(l10n.cloudSyncLockStateTitle),
                        subtitle: Text(
                          sync.isUnlocked
                              ? l10n.cloudSyncLockStateUnlocked
                              : l10n.cloudSyncLockStateLocked,
                        ),
                        trailing: sync.isUnlocked
                            ? Icon(
                                Icons.check_circle_outline,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : OutlinedButton(
                                onPressed: sync.status == SyncStatus.running
                                    ? null
                                    : configured
                                    ? (sync.syncEnabled ? _unlock : _guidedEnableFlow)
                                    : null,
                                child: Text(
                                  sync.syncEnabled
                                      ? l10n.cloudSyncUnlock
                                      : l10n.cloudSyncEnable,
                                ),
                              ),
                      ),
                      if (kIsWeb) ...[
                        const SizedBox(height: 8),
                        Text(l10n.cloudSyncWebDekNote),
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
                        l10n.cloudSyncActionsTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.cloudSyncActionsSubtitle,
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: canSyncNow ? _syncNow : null,
                              icon: const Icon(Icons.sync_outlined),
                              label: Text(l10n.cloudSyncSyncNow),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: sync.status == SyncStatus.running
                                  ? null
                                  : sync.syncEnabled
                                  ? () async {
                                      await sync.disableSync();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.cloudSyncDisabledSnack,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.stop_circle_outlined),
                              label: Text(l10n.cloudSyncDisable),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text(l10n.cloudSyncAdvancedTitle),
                subtitle: Text(l10n.cloudSyncAdvancedSubtitle),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  SelectableText('${l10n.cloudSyncDeviceId}: ${sync.deviceId}'),
                  SelectableText(
                    '${l10n.cloudSyncLastServerSeq}: ${sync.lastServerSeq}',
                  ),
                  SelectableText('${l10n.cloudSyncDekId}: ${sync.dekId ?? "-"}'),
                  SelectableText(
                    '${l10n.cloudSyncLastSyncAt}: ${sync.lastSyncAt?.toIso8601String() ?? "-"}',
                  ),
                  if (sync.lastErrorDetail != null) ...[
                    const SizedBox(height: 8),
                    SelectableText(sync.lastErrorDetail!),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _RollbackChoice { stop, continueSync }
