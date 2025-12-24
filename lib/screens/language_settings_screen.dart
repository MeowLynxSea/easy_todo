import 'package:flutter/material.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/providers/language_provider.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.language,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: LanguageProvider.supportedLocales.length,
              itemBuilder: (context, index) {
                final locale = LanguageProvider.supportedLocales[index];
                final isSelected = languageProvider.locale == locale;
                final languageName = _getLanguageName(locale, l10n);

                return RadioListTile<Locale>(
                  title: Text(
                    languageName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    _getNativeLanguageName(locale),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  value: locale,
                  groupValue: languageProvider.locale,
                  onChanged: (value) {
                    if (value != null) {
                      languageProvider.setLocale(value);
                      Navigator.of(context).pop();
                    }
                  },
                  selected: isSelected,
                  activeColor: Theme.of(context).colorScheme.primary,
                  secondary: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.languageSettings,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(Locale locale, AppLocalizations l10n) {
    switch (locale.languageCode) {
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
        return locale.languageCode.toUpperCase();
    }
  }

  String _getNativeLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return locale.languageCode.toUpperCase();
    }
  }
}