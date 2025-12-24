import 'package:flutter/material.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/providers/app_settings_provider.dart';
import 'package:easy_todo/theme/app_theme.dart';

class ViewSettingsScreen extends StatefulWidget {
  const ViewSettingsScreen({super.key});

  @override
  State<ViewSettingsScreen> createState() => _ViewSettingsScreenState();
}

class _ViewSettingsScreenState extends State<ViewSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appSettingsProvider = Provider.of<AppSettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.viewSettings), centerTitle: true),
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
                    l10n.todoViewSettings,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildViewModeSetting(appSettingsProvider, l10n),
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
                    l10n.historyViewSettings,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHistoryViewModeSetting(appSettingsProvider, l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeSetting(
    AppSettingsProvider provider,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.viewMode,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: Text(l10n.listView),
                value: 'list',
                groupValue: provider.viewMode,
                onChanged: (value) async {
                  if (value != null) {
                    await provider.setViewMode(value);
                  }
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: Text(l10n.stackingView),
                value: 'stacking',
                groupValue: provider.viewMode,
                onChanged: (value) async {
                  if (value != null) {
                    await provider.setViewMode(value);
                  }
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryViewModeSetting(
    AppSettingsProvider provider,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.historyViewMode,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: Text(l10n.listView),
                value: 'list',
                groupValue: provider.historyViewMode,
                onChanged: (value) async {
                  if (value != null) {
                    await provider.setHistoryViewMode(value);
                  }
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: Text(l10n.calendarView),
                value: 'calendar',
                groupValue: provider.historyViewMode,
                onChanged: (value) async {
                  if (value != null) {
                    await provider.setHistoryViewMode(value);
                  }
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
