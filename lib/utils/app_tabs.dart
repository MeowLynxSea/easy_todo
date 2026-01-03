import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

enum AppTabId {
  todos,
  importanceQuadrant,
  schedule,
  history,
  statistics,
  preferences,
}

extension AppTabIdX on AppTabId {
  static const List<AppTabId> defaultOrder = <AppTabId>[
    AppTabId.todos,
    AppTabId.importanceQuadrant,
    AppTabId.schedule,
    AppTabId.history,
    AppTabId.statistics,
    AppTabId.preferences,
  ];

  String get storageKey => name;

  static AppTabId? fromStorageKey(String key) {
    final normalized = key.trim();
    for (final value in AppTabId.values) {
      if (value.storageKey == normalized) return value;
    }
    return null;
  }

  bool get isRequired {
    return this == AppTabId.todos || this == AppTabId.preferences;
  }

  IconData get icon {
    return switch (this) {
      AppTabId.todos => Icons.task_alt_outlined,
      AppTabId.importanceQuadrant => Icons.grid_view_outlined,
      AppTabId.schedule => Icons.calendar_month_outlined,
      AppTabId.history => Icons.history_outlined,
      AppTabId.statistics => Icons.bar_chart_outlined,
      AppTabId.preferences => Icons.settings_outlined,
    };
  }

  IconData get selectedIcon {
    return switch (this) {
      AppTabId.todos => Icons.task_alt,
      AppTabId.importanceQuadrant => Icons.grid_view,
      AppTabId.schedule => Icons.calendar_month,
      AppTabId.history => Icons.history,
      AppTabId.statistics => Icons.bar_chart,
      AppTabId.preferences => Icons.settings,
    };
  }

  String label(AppLocalizations l10n) {
    return switch (this) {
      AppTabId.todos => l10n.todos,
      AppTabId.importanceQuadrant => l10n.importanceQuadrant,
      AppTabId.schedule => l10n.schedule,
      AppTabId.history => l10n.history,
      AppTabId.statistics => l10n.stats,
      AppTabId.preferences => l10n.preferences,
    };
  }
}
