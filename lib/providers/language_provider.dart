import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  Locale _locale = const Locale('zh');
  VoidCallback? onLanguageChanged;

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
    if (previousLocale.languageCode != locale.languageCode && onLanguageChanged != null) {
      onLanguageChanged!();
    }
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'zh';
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> _saveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _locale.languageCode);
  }

  static const List<Locale> supportedLocales = [
    Locale('zh'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('ja'),
    Locale('ko')
  ];
}
