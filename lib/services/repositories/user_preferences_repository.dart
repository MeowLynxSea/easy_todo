import 'package:easy_todo/models/user_preferences_model.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/sync_write_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesRepository {
  static const int schemaVersion = 2;
  static const String hiveKey = 'userPreferences';

  final HiveService _hiveService;
  final SyncWriteService _syncWriteService;

  UserPreferencesRepository({
    HiveService? hiveService,
    SyncWriteService? syncWriteService,
  }) : _hiveService = hiveService ?? HiveService(),
       _syncWriteService = syncWriteService ?? SyncWriteService();

  Future<UserPreferencesModel> load() async {
    final box = _hiveService.userPreferencesBox;
    final existing = box.get(hiveKey);
    final didExist = existing != null;

    var prefs = existing ?? UserPreferencesModel.create();

    // Only migrate legacy SharedPreferences once, when creating the Hive record
    // for the first time. Otherwise, legacy keys can override user choices on
    // every app start (especially when the "default" equals a valid selection).
    if (!didExist) {
      final migrated = await _migrateFromSharedPreferencesIfHelpful(prefs);
      if (migrated != prefs) {
        prefs = migrated;
      }
      await save(prefs);
      return prefs;
    }

    return prefs;
  }

  Future<void> save(UserPreferencesModel preferences) async {
    await _syncWriteService.upsertRecord(
      type: SyncTypes.userPrefs,
      recordId: SyncRecordIds.singleton,
      schemaVersion: schemaVersion,
      writeBusinessData: () =>
          _hiveService.userPreferencesBox.put(hiveKey, preferences),
    );
  }

  Future<UserPreferencesModel> update(
    UserPreferencesModel Function(UserPreferencesModel current) transform,
  ) async {
    final current = await load();
    final next = transform(current);
    if (identical(next, current)) return current;
    await save(next);
    return next;
  }

  Future<UserPreferencesModel> _migrateFromSharedPreferencesIfHelpful(
    UserPreferencesModel current,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    var next = current;
    final defaults = UserPreferencesModel.create();

    final legacyLanguageCode = prefs.getString('app_language');
    if (legacyLanguageCode != null && legacyLanguageCode.isNotEmpty) {
      if ((next.languageCode).isEmpty ||
          (next.languageCode == defaults.languageCode)) {
        if (legacyLanguageCode != next.languageCode) {
          next = next.copyWith(languageCode: legacyLanguageCode);
        }
      }
    }

    final legacyThemeModeIndex = prefs.getInt('app_theme');
    if (legacyThemeModeIndex != null) {
      if (next.themeModeIndex == defaults.themeModeIndex) {
        if (legacyThemeModeIndex != next.themeModeIndex) {
          next = next.copyWith(themeModeIndex: legacyThemeModeIndex);
        }
      }
    }

    final legacyThemeColors = prefs.getString('theme_colors');
    if (legacyThemeColors != null && legacyThemeColors.isNotEmpty) {
      if (next.themeColorsString.isEmpty &&
          legacyThemeColors != next.themeColorsString) {
        next = next.copyWith(themeColorsString: legacyThemeColors);
      }
    }

    final legacyCustomThemeColors = prefs.getString('custom_theme');
    if (next.customThemeColorsString.isEmpty &&
        legacyCustomThemeColors != null &&
        legacyCustomThemeColors.isNotEmpty) {
      if (legacyCustomThemeColors != next.customThemeColorsString) {
        next = next.copyWith(customThemeColorsString: legacyCustomThemeColors);
      }
    }

    final legacyStatusFilter = prefs.getInt('todo_status_filter');
    if (legacyStatusFilter != null) {
      if (next.statusFilterIndex == defaults.statusFilterIndex) {
        if (legacyStatusFilter != next.statusFilterIndex) {
          next = next.copyWith(statusFilterIndex: legacyStatusFilter);
        }
      }
    }

    final legacyTimeFilter = prefs.getInt('todo_time_filter');
    if (legacyTimeFilter != null) {
      if (next.timeFilterIndex == defaults.timeFilterIndex) {
        if (legacyTimeFilter != next.timeFilterIndex) {
          next = next.copyWith(timeFilterIndex: legacyTimeFilter);
        }
      }
    }

    final legacySortOrder = prefs.getInt('todo_sort_order');
    if (legacySortOrder != null) {
      if (next.sortOrderIndex == defaults.sortOrderIndex) {
        if (legacySortOrder != next.sortOrderIndex) {
          next = next.copyWith(sortOrderIndex: legacySortOrder);
        }
      }
    }

    final legacySelectedCategories = prefs.getString(
      'todo_selected_categories',
    );
    if (next.selectedCategories.isEmpty &&
        legacySelectedCategories != null &&
        legacySelectedCategories.isNotEmpty) {
      final parsed = legacySelectedCategories
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      if (parsed.isNotEmpty) {
        next = next.copyWith(selectedCategories: parsed);
      }
    }

    return next;
  }
}
