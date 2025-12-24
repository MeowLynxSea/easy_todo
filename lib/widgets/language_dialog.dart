import 'package:flutter/material.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/providers/language_provider.dart';

class LanguageDialog extends StatelessWidget {
  const LanguageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.language),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: LanguageProvider.supportedLocales.length,
          itemBuilder: (context, index) {
            final locale = LanguageProvider.supportedLocales[index];
            final isSelected = languageProvider.locale == locale;

            return RadioListTile<Locale>(
              title: Text(_getLanguageName(locale, l10n)),
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
            );
          },
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
}
