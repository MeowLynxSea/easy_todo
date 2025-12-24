import 'package:flutter/material.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/providers/theme_provider.dart';

class ThemeDialog extends StatelessWidget {
  const ThemeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.theme),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Row(
                children: [
                  const Icon(Icons.light_mode),
                  const SizedBox(width: 16),
                  Text(l10n.lightTheme),
                ],
              ),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
              selected: themeProvider.themeMode == ThemeMode.light,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            RadioListTile<ThemeMode>(
              title: Row(
                children: [
                  const Icon(Icons.dark_mode),
                  const SizedBox(width: 16),
                  Text(l10n.darkTheme),
                ],
              ),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
              selected: themeProvider.themeMode == ThemeMode.dark,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            RadioListTile<ThemeMode>(
              title: Row(
                children: [
                  const Icon(Icons.settings_suggest),
                  const SizedBox(width: 16),
                  Text(l10n.systemTheme),
                ],
              ),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
              selected: themeProvider.themeMode == ThemeMode.system,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
