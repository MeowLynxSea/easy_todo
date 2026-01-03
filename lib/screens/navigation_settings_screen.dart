import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/providers/app_settings_provider.dart';
import 'package:easy_todo/utils/app_tabs.dart';
import 'package:easy_todo/widgets/web_desktop_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NavigationSettingsScreen extends StatefulWidget {
  const NavigationSettingsScreen({super.key});

  @override
  State<NavigationSettingsScreen> createState() =>
      _NavigationSettingsScreenState();
}

class _NavigationSettingsScreenState extends State<NavigationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AppSettingsProvider>();
    final config = provider.navigationTabConfig;
    final visibleTabs = provider.visibleNavigationTabs;
    final defaultTab = provider.navigationDefaultTabId;

    final orderedAllTabs = config.tabOrder
        .map(AppTabIdX.fromStorageKey)
        .whereType<AppTabId>()
        .toList(growable: false);

    final enabledSet = config.enabledTabs.toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navigationSettingsTitle),
        centerTitle: true,
      ),
      body: WebDesktopContent(
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navigationCustomizeTabsTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.navigationCustomizeTabsSubtitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orderedAllTabs.length,
                      onReorder: (oldIndex, newIndex) async {
                        if (oldIndex < newIndex) newIndex -= 1;
                        final next = [...orderedAllTabs];
                        final moved = next.removeAt(oldIndex);
                        next.insert(newIndex, moved);
                        await provider.setNavigationTabOrder(
                          next.map((e) => e.storageKey).toList(),
                        );
                      },
                      itemBuilder: (context, index) {
                        final tab = orderedAllTabs[index];
                        final enabled = enabledSet.contains(tab.storageKey);
                        final required = tab.isRequired;
                        return ListTile(
                          key: ValueKey('nav_tab_${tab.storageKey}'),
                          leading: Icon(tab.icon),
                          title: Text(tab.label(l10n)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: enabled,
                                onChanged: required
                                    ? null
                                    : (value) async {
                                        await provider.setNavigationTabEnabled(
                                          tab.storageKey,
                                          value,
                                        );
                                      },
                              ),
                              const SizedBox(width: 8),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          await provider.resetNavigationTabsToDefault();
                        },
                        child: Text(l10n.resetButton),
                      ),
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
                      l10n.navigationDefaultTabTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AppTabId>(
                      value: visibleTabs.contains(defaultTab)
                          ? defaultTab
                          : visibleTabs.first,
                      items: [
                        for (final tab in visibleTabs)
                          DropdownMenuItem(
                            value: tab,
                            child: Text(tab.label(l10n)),
                          ),
                      ],
                      onChanged: (value) async {
                        if (value == null) return;
                        await provider.setNavigationDefaultTab(
                          value.storageKey,
                        );
                      },
                      decoration: InputDecoration(
                        labelText: l10n.navigationDefaultTabFieldLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
