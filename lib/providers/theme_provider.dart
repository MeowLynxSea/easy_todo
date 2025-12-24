import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _themeColorsKey = 'theme_colors';
  static const String _customThemeKey = 'custom_theme';

  ThemeMode _themeMode = ThemeMode.system;
  Map<String, Color> _themeColors = {
    'primary': AppTheme.primaryColor,
    'primaryVariant': AppTheme.primaryVariant,
    'secondary': AppTheme.secondaryColor,
  };
  Map<String, Color>? _customThemeColors;
  int _themeVersion = 0;

  ThemeProvider() {
    _loadTheme();
    _loadThemeColors();
  }

  ThemeMode get themeMode => _themeMode;
  Map<String, Color> get themeColors => _themeColors;
  Map<String, Color>? get customThemeColors => _customThemeColors;
  int get themeVersion => _themeVersion;

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    _themeVersion++;
    _saveTheme();
    notifyListeners();
  }

  void setThemeColors(Map<String, Color> colors) {
    _themeColors = colors;
    _themeVersion++;
    debugPrint('Setting theme colors: $colors');
    debugPrint('Theme version updated to: $_themeVersion');
    _saveThemeColors();
    notifyListeners();
  }

  void setCustomThemeColors(Map<String, Color> colors) {
    _customThemeColors = colors.isNotEmpty ? colors : null;
    _themeVersion++;
    debugPrint('Setting custom theme colors: $_customThemeColors');
    _saveCustomTheme();
    notifyListeners();
  }

  void clearCustomTheme() {
    _customThemeColors = null;
    _themeVersion++;
    _saveCustomTheme();
    notifyListeners();
  }

  void resetToDefaultTheme() {
    _themeColors = {
      'primary': AppTheme.primaryColor,
      'primaryVariant': AppTheme.primaryVariant,
      'secondary': AppTheme.secondaryColor,
    };
    _customThemeColors = null;
    _themeVersion++;
    _saveThemeColors();
    _saveCustomTheme();
    notifyListeners();
  }

  ThemeData getLightTheme() {
    return _getLightTheme(null);
  }

  ThemeData getDarkTheme() {
    return _getDarkTheme(null);
  }

  ThemeData getTheme(BuildContext context) {
    final bool isDark = _themeMode == ThemeMode.dark ||
                       (_themeMode == ThemeMode.system &&
                        Theme.of(context).brightness == Brightness.dark);

    return isDark ? _getDarkTheme(context) : _getLightTheme(context);
  }

  ThemeData _getLightTheme(BuildContext? context) {
    final colors = _customThemeColors ?? _themeColors;
    // debugPrint('Building light theme with colors: $colors');
    // debugPrint('Custom theme: $_customThemeColors, Theme colors: $_themeColors');
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors['primary']!,
        primary: colors['primary'],
        secondary: colors['secondary'],
        surface: AppTheme.surface,
        surfaceContainer: AppTheme.background,
        error: AppTheme.error,
        brightness: Brightness.light,
      ),
      // Rest of the light theme properties from AppTheme.lightTheme
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Color(0x0F000000),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppTheme.textPrimary),
        bodyMedium: TextStyle(color: AppTheme.textPrimary),
        titleLarge: TextStyle(color: AppTheme.textPrimary),
        titleMedium: TextStyle(color: AppTheme.textPrimary),
        titleSmall: TextStyle(color: AppTheme.textPrimary),
      ),
    );
  }

  ThemeData _getDarkTheme(BuildContext? context) {
    final colors = _customThemeColors ?? _themeColors;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors['primary']!,
        primary: colors['primary'],
        secondary: colors['secondary'],
        surface: const Color(0xFF1E1E1E),
        surfaceContainer: const Color(0xFF121212),
        error: AppTheme.error,
        brightness: Brightness.dark,
      ),
      // Rest of the dark theme properties
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Color(0x1A000000),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
      ),
    );
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 2; // Default to system
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
  }

  Future<void> _loadThemeColors() async {
    final prefs = await SharedPreferences.getInstance();
    final colorsString = prefs.getString(_themeColorsKey);
    if (colorsString != null) {
      try {
        final colorsMap = _parseColorsFromString(colorsString);
        if (colorsMap.isNotEmpty) {
          _themeColors = colorsMap;
        }
      } catch (e) {
        // Keep default colors on error
        debugPrint('Error loading theme colors: $e');
      }
    }
    _loadCustomTheme();
  }

  Future<void> _loadCustomTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final customColorsString = prefs.getString(_customThemeKey);
    if (customColorsString != null) {
      try {
        final customColorsMap = _parseColorsFromString(customColorsString);
        if (customColorsMap.isNotEmpty) {
          _customThemeColors = customColorsMap;
        }
      } catch (e) {
        // Keep no custom theme on error
        debugPrint('Error loading custom theme colors: $e');
      }
    }
  }

  Future<void> _saveThemeColors() async {
    final prefs = await SharedPreferences.getInstance();
    final colorsString = _colorsToString(_themeColors);
    await prefs.setString(_themeColorsKey, colorsString);
  }

  Future<void> _saveCustomTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (_customThemeColors != null) {
      final colorsString = _colorsToString(_customThemeColors!);
      await prefs.setString(_customThemeKey, colorsString);
    } else {
      await prefs.remove(_customThemeKey);
    }
  }

  String _colorsToString(Map<String, Color> colors) {
    return colors.entries.map((entry) => '${entry.key}:${entry.value.toARGB32()}').join(',');
  }

  Map<String, Color> _parseColorsFromString(String colorsString) {
    final colorsMap = <String, Color>{};
    final pairs = colorsString.split(',');

    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final key = parts[0];
        final value = int.tryParse(parts[1]);
        if (value != null) {
          colorsMap[key] = Color(value);
        }
      }
    }

    return colorsMap;
  }

  String getThemeModeText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_themeMode) {
      case ThemeMode.light:
        return l10n.lightTheme;
      case ThemeMode.dark:
        return l10n.darkTheme;
      case ThemeMode.system:
        return l10n.systemTheme;
    }
  }
}
