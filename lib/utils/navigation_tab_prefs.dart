import 'package:easy_todo/utils/app_tabs.dart';

class NavigationTabConfig {
  final List<String> tabOrder;
  final List<String> enabledTabs;
  final String defaultTab;

  const NavigationTabConfig({
    required this.tabOrder,
    required this.enabledTabs,
    required this.defaultTab,
  });
}

const List<AppTabId> kRequiredTabs = <AppTabId>[
  AppTabId.todos,
  AppTabId.preferences,
];

NavigationTabConfig normalizeNavigationTabConfig({
  required List<String> tabOrder,
  required List<String> enabledTabs,
  required String defaultTab,
}) {
  final knownKeys = AppTabId.values
      .map((e) => e.storageKey)
      .toList(growable: false);
  final requiredKeys = kRequiredTabs
      .map((e) => e.storageKey)
      .toList(growable: false);

  final normalizedOrder = _normalizeKeyList(tabOrder);
  final normalizedEnabled = _normalizeKeyList(enabledTabs);

  final mergedOrder = _ensureContainsAll(normalizedOrder, requiredKeys);
  final mergedOrderWithKnown = _ensureContainsAll(mergedOrder, knownKeys);
  final mergedEnabled = _ensureContainsAll(normalizedEnabled, requiredKeys);

  final normalizedDefault = _normalizeDefaultTab(
    defaultTab,
    enabledTabs: mergedEnabled,
    tabOrder: mergedOrderWithKnown,
  );

  return NavigationTabConfig(
    tabOrder: mergedOrderWithKnown,
    enabledTabs: mergedEnabled,
    defaultTab: normalizedDefault,
  );
}

List<AppTabId> resolveVisibleTabs({required NavigationTabConfig config}) {
  final enabled = config.enabledTabs.toSet();
  final seen = <AppTabId>{};
  final result = <AppTabId>[];

  for (final key in config.tabOrder) {
    if (!enabled.contains(key)) continue;
    final tab = AppTabIdX.fromStorageKey(key);
    if (tab == null) continue;
    if (seen.add(tab)) {
      result.add(tab);
    }
  }

  for (final requiredTab in kRequiredTabs) {
    if (seen.add(requiredTab)) {
      result.add(requiredTab);
    }
  }

  return result;
}

List<String> _normalizeKeyList(List<String> input) {
  final seen = <String>{};
  final result = <String>[];
  for (final raw in input) {
    final key = raw.trim();
    if (key.isEmpty) continue;
    if (seen.add(key)) {
      result.add(key);
    }
  }
  return result;
}

List<String> _ensureContainsAll(List<String> base, List<String> mustHave) {
  final seen = base.toSet();
  final result = List<String>.from(base);
  for (final key in mustHave) {
    if (seen.add(key)) {
      result.add(key);
    }
  }
  return result;
}

String _normalizeDefaultTab(
  String defaultTab, {
  required List<String> enabledTabs,
  required List<String> tabOrder,
}) {
  final key = defaultTab.trim();
  if (enabledTabs.contains(key)) return key;

  for (final ordered in tabOrder) {
    if (enabledTabs.contains(ordered)) return ordered;
  }

  return AppTabId.todos.storageKey;
}
