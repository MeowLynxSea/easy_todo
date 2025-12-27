import 'package:flutter/material.dart';
import 'package:easy_todo/services/repositories/user_preferences_repository.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('zh');
  VoidCallback? onLanguageChanged;
  final UserPreferencesRepository _preferencesRepository =
      UserPreferencesRepository();

  LanguageProvider() {
    _loadLanguage();
  }

  Locale get locale => _locale;
  Locale get currentLanguage => _locale;
  String get currentLanguageCode => _locale.languageCode;

  void setOnLanguageChanged(VoidCallback callback) {
    onLanguageChanged = callback;
  }

  void setLocale(Locale locale) {
    final previousLocale = _locale;
    _locale = locale;
    _saveLanguage();
    notifyListeners();

    // Trigger callback if language actually changed
    if (previousLocale.languageCode != locale.languageCode &&
        onLanguageChanged != null) {
      onLanguageChanged!();
    }
  }

  Future<void> _loadLanguage() async {
    final prefs = await _preferencesRepository.load();
    final languageCode = prefs.languageCode.isNotEmpty
        ? prefs.languageCode
        : 'zh';
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> _saveLanguage() async {
    await _preferencesRepository.update(
      (current) => current.copyWith(languageCode: _locale.languageCode),
    );
  }

  Future<void> reloadFromPreferences() async {
    await _loadLanguage();
  }

  static const List<Locale> supportedLocales = [
    Locale('zh'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('ja'),
    Locale('ko'),
  ];
}
