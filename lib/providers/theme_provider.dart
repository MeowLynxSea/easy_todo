import 'package:flutter/material.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/services/repositories/user_preferences_repository.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/models/user_preferences_model.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _primaryKey = 'primary';
  static const String _primaryVariantKey = 'primaryVariant';
  static const String _secondaryKey = 'secondary';

  static const Map<String, Color> _defaultThemeColors = {
    _primaryKey: AppTheme.primaryColor,
    _primaryVariantKey: AppTheme.primaryVariant,
    _secondaryKey: AppTheme.secondaryColor,
  };

  ThemeMode _themeMode = ThemeMode.system;
  Map<String, Color> _themeColors = {..._defaultThemeColors};
  Map<String, Color>? _customThemeColors;
  int _themeVersion = 0;
  final UserPreferencesRepository _preferencesRepository;

  ThemeProvider({UserPreferencesRepository? preferencesRepository})
    : _preferencesRepository =
          preferencesRepository ?? UserPreferencesRepository() {
    _loadFromUserPreferences();
  }

  ThemeMode get themeMode => _themeMode;
  Map<String, Color> get themeColors => _themeColors;
  Map<String, Color>? get customThemeColors => _customThemeColors;
  int get themeVersion => _themeVersion;

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    _themeVersion++;
    _persistTheme();
    notifyListeners();
  }

  void setThemeColors(Map<String, Color> colors) {
    _themeColors = _ensureRequiredThemeColors(colors);
    _themeVersion++;
    debugPrint('Setting theme colors: $colors');
    debugPrint('Theme version updated to: $_themeVersion');
    _persistTheme();
    notifyListeners();
  }

  void setCustomThemeColors(Map<String, Color> colors) {
    final normalized = Map<String, Color>.from(colors);
    if (normalized.containsKey(_primaryKey) &&
        !normalized.containsKey(_primaryVariantKey)) {
      normalized[_primaryVariantKey] = _derivePrimaryVariant(
        normalized[_primaryKey]!,
      );
    }
    _customThemeColors = normalized.isNotEmpty ? normalized : null;
    _themeVersion++;
    debugPrint('Setting custom theme colors: $_customThemeColors');
    _persistTheme();
    notifyListeners();
  }

  void clearCustomTheme() {
    _customThemeColors = null;
    _themeVersion++;
    _persistTheme();
    notifyListeners();
  }

  void resetToDefaultTheme() {
    _themeColors = {..._defaultThemeColors};
    _customThemeColors = null;
    _themeVersion++;
    _persistTheme();
    notifyListeners();
  }

  ThemeData getLightTheme() {
    return _getLightTheme(null);
  }

  ThemeData getDarkTheme() {
    return _getDarkTheme(null);
  }

  ThemeData getTheme(BuildContext context) {
    final bool isDark =
        _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    return isDark ? _getDarkTheme(context) : _getLightTheme(context);
  }

  ThemeData _getLightTheme(BuildContext? context) {
    final colors = _effectiveThemeColors();
    // debugPrint('Building light theme with colors: $colors');
    // debugPrint('Custom theme: $_customThemeColors, Theme colors: $_themeColors');
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors[_primaryKey]!,
        primary: colors[_primaryKey],
        secondary: colors[_secondaryKey],
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
      cardTheme: CardThemeData(elevation: 2, shadowColor: Color(0x0F000000)),
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
    final colors = _effectiveThemeColors();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors[_primaryKey]!,
        primary: colors[_primaryKey],
        secondary: colors[_secondaryKey],
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
      cardTheme: CardThemeData(elevation: 2, shadowColor: Color(0x1A000000)),
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

  Future<void> _loadFromUserPreferences() async {
    final prefs = await _preferencesRepository.load();

    final index = prefs.themeModeIndex;
    if (index >= 0 && index < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[index];
    } else {
      _themeMode = ThemeMode.system;
    }

    if (prefs.themeColorsString.isNotEmpty) {
      try {
        final parsed = _parseColorsFromString(prefs.themeColorsString);
        if (parsed.isNotEmpty) {
          _themeColors = _ensureRequiredThemeColors(parsed);
        }
      } catch (e) {
        debugPrint('Error parsing theme colors: $e');
      }
    }
    _themeColors = _ensureRequiredThemeColors(_themeColors);

    if (prefs.customThemeColorsString.isNotEmpty) {
      try {
        final parsed = _parseColorsFromString(prefs.customThemeColorsString);
        _customThemeColors = parsed.isNotEmpty ? parsed : null;
      } catch (e) {
        debugPrint('Error parsing custom theme colors: $e');
      }
    } else {
      _customThemeColors = null;
    }

    notifyListeners();
  }

  Future<void> _persistTheme() async {
    final themeColorsString = _colorsToString(_themeColors);
    final customThemeColorsString = _customThemeColors == null
        ? ''
        : _colorsToString(_customThemeColors!);

    await _preferencesRepository.update(
      (current) => current.copyWith(
        themeModeIndex: _themeMode.index,
        themeColorsString: themeColorsString,
        customThemeColorsString: customThemeColorsString,
      ),
    );
  }

  Future<void> reloadFromPreferences() async {
    await _loadFromUserPreferences();
  }

  Future<void> reloadFromHiveReadOnly() async {
    final box = HiveService().userPreferencesBox;
    final prefs =
        box.get(UserPreferencesRepository.hiveKey) ??
        UserPreferencesModel.create();

    final prevMode = _themeMode;
    final prevThemeColors = _themeColors;
    final prevCustom = _customThemeColors;

    final index = prefs.themeModeIndex;
    if (index >= 0 && index < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[index];
    } else {
      _themeMode = ThemeMode.system;
    }

    var nextThemeColors = _themeColors;
    if (prefs.themeColorsString.isNotEmpty) {
      try {
        final parsed = _parseColorsFromString(prefs.themeColorsString);
        if (parsed.isNotEmpty) {
          nextThemeColors = _ensureRequiredThemeColors(parsed);
        }
      } catch (e) {
        debugPrint('Error parsing theme colors: $e');
      }
    }
    _themeColors = _ensureRequiredThemeColors(nextThemeColors);

    Map<String, Color>? nextCustom;
    if (prefs.customThemeColorsString.isNotEmpty) {
      try {
        final parsed = _parseColorsFromString(prefs.customThemeColorsString);
        nextCustom = parsed.isNotEmpty ? parsed : null;
      } catch (e) {
        debugPrint('Error parsing custom theme colors: $e');
        nextCustom = null;
      }
    } else {
      nextCustom = null;
    }
    _customThemeColors = nextCustom;

    final changed =
        prevMode != _themeMode ||
        prevThemeColors.toString() != _themeColors.toString() ||
        prevCustom.toString() != _customThemeColors.toString();
    if (changed) {
      _themeVersion++;
    }
    notifyListeners();
  }

  String _colorsToString(Map<String, Color> colors) {
    return colors.entries
        .map((entry) => '${entry.key}:${entry.value.toARGB32()}')
        .join(',');
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

  static Map<String, Color> _ensureRequiredThemeColors(
    Map<String, Color> colors,
  ) {
    final primary = colors[_primaryKey] ?? _defaultThemeColors[_primaryKey]!;
    final secondary =
        colors[_secondaryKey] ?? _defaultThemeColors[_secondaryKey]!;
    final primaryVariant =
        colors[_primaryVariantKey] ?? _derivePrimaryVariant(primary);

    return {
      ...colors,
      _primaryKey: primary,
      _secondaryKey: secondary,
      _primaryVariantKey: primaryVariant,
    };
  }

  static Color _derivePrimaryVariant(Color primary) {
    final hslColor = HSLColor.fromColor(primary);
    final nextLightness = (hslColor.lightness * 0.8).clamp(0.0, 1.0);
    return hslColor.withLightness(nextLightness).toColor();
  }

  Map<String, Color> _effectiveThemeColors() {
    final base = _ensureRequiredThemeColors(_themeColors);
    final custom = _customThemeColors;
    if (custom == null || custom.isEmpty) return base;
    return _ensureRequiredThemeColors({...base, ...custom});
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
