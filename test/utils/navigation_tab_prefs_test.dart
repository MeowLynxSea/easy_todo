import 'package:easy_todo/utils/app_tabs.dart';
import 'package:easy_todo/utils/navigation_tab_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeNavigationTabConfig always keeps required tabs', () {
    final normalized = normalizeNavigationTabConfig(
      tabOrder: <String>['history', 'schedule'],
      enabledTabs: <String>['history'],
      defaultTab: 'history',
    );

    expect(normalized.enabledTabs, contains(AppTabId.todos.storageKey));
    expect(normalized.enabledTabs, contains(AppTabId.preferences.storageKey));
    expect(normalized.tabOrder, contains(AppTabId.todos.storageKey));
    expect(normalized.tabOrder, contains(AppTabId.preferences.storageKey));
  });

  test('normalizeNavigationTabConfig defaultTab falls back to enabled tab', () {
    final normalized = normalizeNavigationTabConfig(
      tabOrder: <String>[
        AppTabId.history.storageKey,
        AppTabId.todos.storageKey,
      ],
      enabledTabs: <String>[
        AppTabId.history.storageKey,
        AppTabId.todos.storageKey,
      ],
      defaultTab: 'not_a_real_tab',
    );

    expect(
      normalized.defaultTab,
      anyOf(AppTabId.history.storageKey, AppTabId.todos.storageKey),
    );
    expect(normalized.enabledTabs, contains(normalized.defaultTab));
  });

  test('resolveVisibleTabs respects order and enabled set', () {
    final normalized = normalizeNavigationTabConfig(
      tabOrder: <String>[
        AppTabId.history.storageKey,
        AppTabId.todos.storageKey,
        AppTabId.statistics.storageKey,
        AppTabId.preferences.storageKey,
      ],
      enabledTabs: <String>[
        AppTabId.history.storageKey,
        AppTabId.todos.storageKey,
        AppTabId.preferences.storageKey,
      ],
      defaultTab: AppTabId.history.storageKey,
    );

    final tabs = resolveVisibleTabs(config: normalized);
    expect(tabs, contains(AppTabId.todos));
    expect(tabs, contains(AppTabId.preferences));
    expect(tabs, isNot(contains(AppTabId.statistics)));
    expect(tabs.first, AppTabId.history);
  });
}
