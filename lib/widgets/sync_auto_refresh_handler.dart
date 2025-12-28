import 'dart:async';

import 'package:easy_todo/providers/ai_provider.dart';
import 'package:easy_todo/providers/app_settings_provider.dart';
import 'package:easy_todo/providers/filter_provider.dart';
import 'package:easy_todo/providers/language_provider.dart';
import 'package:easy_todo/providers/pomodoro_provider.dart';
import 'package:easy_todo/providers/sync_provider.dart';
import 'package:easy_todo/providers/theme_provider.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SyncAutoRefreshHandler extends StatefulWidget {
  final Widget child;

  const SyncAutoRefreshHandler({super.key, required this.child});

  @override
  State<SyncAutoRefreshHandler> createState() => _SyncAutoRefreshHandlerState();
}

class _SyncAutoRefreshHandlerState extends State<SyncAutoRefreshHandler> {
  VoidCallback? _syncListener;
  int? _lastHandledRevision;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sync = context.read<SyncProvider>();
      _lastHandledRevision = sync.autoSyncCompletedRevision;
      _syncListener = () => _onSyncChanged();
      sync.addListener(_syncListener!);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    final listener = _syncListener;
    if (listener != null) {
      try {
        context.read<SyncProvider>().removeListener(listener);
      } catch (_) {}
    }
    super.dispose();
  }

  void _onSyncChanged() {
    if (!mounted) return;
    final sync = context.read<SyncProvider>();

    final revision = sync.autoSyncCompletedRevision;
    if (_lastHandledRevision == revision) return;
    _lastHandledRevision = revision;

    if (sync.status == SyncStatus.running) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      unawaited(_refreshAppStateAfterAutoSync());
    });
  }

  Future<void> _refreshAppStateAfterAutoSync() async {
    if (!mounted) return;

    final filterProvider = context.read<FilterProvider>();
    final todoProvider = context.read<TodoProvider>();
    final pomodoroProvider = context.read<PomodoroProvider>();
    final aiProvider = context.read<AIProvider>();
    final appSettingsProvider = context.read<AppSettingsProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final themeProvider = context.read<ThemeProvider>();

    await filterProvider.reloadFromHiveReadOnly();
    await todoProvider.reloadFromHiveReadOnly(filterProvider: filterProvider);
    await pomodoroProvider.reloadFromHiveReadOnly();
    await aiProvider.reloadFromHiveReadOnly();
    await appSettingsProvider.reloadFromHiveReadOnly();
    await languageProvider.reloadFromHiveReadOnly();
    await themeProvider.reloadFromHiveReadOnly();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
