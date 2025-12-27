import 'package:easy_todo/models/user_preferences_model.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/sync_write_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesRepository {
  static const int schemaVersion = 1;
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
    var prefs = box.get(hiveKey);

    if (prefs == null) {
      prefs = UserPreferencesModel.create();
      await save(prefs);
      return prefs;
    }

    final migrated = await _migrateFromSharedPreferencesIfHelpful(prefs);
    if (migrated != prefs) {
      await save(migrated);
      return migrated;
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

    final legacyLanguageCode = prefs.getString('app_language');
    if ((next.languageCode).isEmpty ||
        (next.languageCode == UserPreferencesModel.create().languageCode)) {
      if (legacyLanguageCode != null && legacyLanguageCode.isNotEmpty) {
        next = next.copyWith(languageCode: legacyLanguageCode);
      }
    }

    final legacyThemeModeIndex = prefs.getInt('app_theme');
    if (next.themeModeIndex == UserPreferencesModel.create().themeModeIndex) {
      if (legacyThemeModeIndex != null) {
        next = next.copyWith(themeModeIndex: legacyThemeModeIndex);
      }
    }

    final legacyThemeColors = prefs.getString('theme_colors');
    if (next.themeColorsString.isEmpty && legacyThemeColors != null) {
      next = next.copyWith(themeColorsString: legacyThemeColors);
    }

    final legacyCustomThemeColors = prefs.getString('custom_theme');
    if (next.customThemeColorsString.isEmpty &&
        legacyCustomThemeColors != null) {
      next = next.copyWith(customThemeColorsString: legacyCustomThemeColors);
    }

    final legacyStatusFilter = prefs.getInt('todo_status_filter');
    if (next.statusFilterIndex ==
        UserPreferencesModel.create().statusFilterIndex) {
      if (legacyStatusFilter != null) {
        next = next.copyWith(statusFilterIndex: legacyStatusFilter);
      }
    }

    final legacyTimeFilter = prefs.getInt('todo_time_filter');
    if (next.timeFilterIndex == UserPreferencesModel.create().timeFilterIndex) {
      if (legacyTimeFilter != null) {
        next = next.copyWith(timeFilterIndex: legacyTimeFilter);
      }
    }

    final legacySortOrder = prefs.getInt('todo_sort_order');
    if (next.sortOrderIndex == UserPreferencesModel.create().sortOrderIndex) {
      if (legacySortOrder != null) {
        next = next.copyWith(sortOrderIndex: legacySortOrder);
      }
    }

    final legacySelectedCategories = prefs.getString(
      'todo_selected_categories',
    );
    if (next.selectedCategories.isEmpty &&
        legacySelectedCategories != null &&
        legacySelectedCategories.isNotEmpty) {
      next = next.copyWith(
        selectedCategories: legacySelectedCategories.split(','),
      );
    }

    return next;
  }
}
