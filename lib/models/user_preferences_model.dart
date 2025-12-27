class UserPreferencesModel {
  /// App language code (e.g. "zh", "en").
  final String languageCode;

  /// Flutter ThemeMode index (ThemeMode.values[index]).
  final int themeModeIndex;

  /// Serialized theme color map (see ThemeProvider encoding).
  final String themeColorsString;

  /// Serialized custom theme colors map, empty if none.
  final String customThemeColorsString;

  /// Todo filter preferences (index-based for backwards compatibility).
  final int statusFilterIndex;
  final int timeFilterIndex;
  final int sortOrderIndex;
  final List<String> selectedCategories;

  final String viewMode; // 'list' or 'stacking'
  final bool viewOpenInNewPage;
  final String historyViewMode; // 'list' or 'calendar'

  /// Schedule: visible range within a day (minutes since midnight).
  /// End is allowed to be 1440, representing 24:00.
  final int scheduleDayStartMinutes;
  final int scheduleDayEndMinutes;

  /// Schedule: which weekdays are shown (DateTime.weekday: 1=Mon..7=Sun).
  final List<int> scheduleVisibleWeekdays;

  /// Schedule: text scale factor for labels (chips/blocks).
  final double scheduleLabelTextScale;

  const UserPreferencesModel({
    required this.languageCode,
    required this.themeModeIndex,
    required this.themeColorsString,
    required this.customThemeColorsString,
    required this.statusFilterIndex,
    required this.timeFilterIndex,
    required this.sortOrderIndex,
    required this.selectedCategories,
    required this.viewMode,
    required this.viewOpenInNewPage,
    required this.historyViewMode,
    required this.scheduleDayStartMinutes,
    required this.scheduleDayEndMinutes,
    required this.scheduleVisibleWeekdays,
    required this.scheduleLabelTextScale,
  });

  UserPreferencesModel copyWith({
    String? languageCode,
    int? themeModeIndex,
    String? themeColorsString,
    String? customThemeColorsString,
    int? statusFilterIndex,
    int? timeFilterIndex,
    int? sortOrderIndex,
    List<String>? selectedCategories,
    String? viewMode,
    bool? viewOpenInNewPage,
    String? historyViewMode,
    int? scheduleDayStartMinutes,
    int? scheduleDayEndMinutes,
    List<int>? scheduleVisibleWeekdays,
    double? scheduleLabelTextScale,
  }) {
    return UserPreferencesModel(
      languageCode: languageCode ?? this.languageCode,
      themeModeIndex: themeModeIndex ?? this.themeModeIndex,
      themeColorsString: themeColorsString ?? this.themeColorsString,
      customThemeColorsString:
          customThemeColorsString ?? this.customThemeColorsString,
      statusFilterIndex: statusFilterIndex ?? this.statusFilterIndex,
      timeFilterIndex: timeFilterIndex ?? this.timeFilterIndex,
      sortOrderIndex: sortOrderIndex ?? this.sortOrderIndex,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      viewMode: viewMode ?? this.viewMode,
      viewOpenInNewPage: viewOpenInNewPage ?? this.viewOpenInNewPage,
      historyViewMode: historyViewMode ?? this.historyViewMode,
      scheduleDayStartMinutes:
          scheduleDayStartMinutes ?? this.scheduleDayStartMinutes,
      scheduleDayEndMinutes:
          scheduleDayEndMinutes ?? this.scheduleDayEndMinutes,
      scheduleVisibleWeekdays:
          scheduleVisibleWeekdays ?? this.scheduleVisibleWeekdays,
      scheduleLabelTextScale:
          scheduleLabelTextScale ?? this.scheduleLabelTextScale,
    );
  }

  static UserPreferencesModel create() {
    return const UserPreferencesModel(
      languageCode: 'zh',
      themeModeIndex: 2,
      themeColorsString: '',
      customThemeColorsString: '',
      statusFilterIndex: 0,
      timeFilterIndex: 0,
      sortOrderIndex: 0,
      selectedCategories: <String>[],
      viewMode: 'list',
      viewOpenInNewPage: false,
      historyViewMode: 'list',
      scheduleDayStartMinutes: 0,
      scheduleDayEndMinutes: 1440,
      scheduleVisibleWeekdays: <int>[1, 2, 3, 4, 5, 6, 7],
      scheduleLabelTextScale: 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'languageCode': languageCode,
      'themeModeIndex': themeModeIndex,
      'themeColorsString': themeColorsString,
      'customThemeColorsString': customThemeColorsString,
      'statusFilterIndex': statusFilterIndex,
      'timeFilterIndex': timeFilterIndex,
      'sortOrderIndex': sortOrderIndex,
      'selectedCategories': selectedCategories,
      'viewMode': viewMode,
      'viewOpenInNewPage': viewOpenInNewPage,
      'historyViewMode': historyViewMode,
      'scheduleDayStartMinutes': scheduleDayStartMinutes,
      'scheduleDayEndMinutes': scheduleDayEndMinutes,
      'scheduleVisibleWeekdays': scheduleVisibleWeekdays,
      'scheduleLabelTextScale': scheduleLabelTextScale,
    };
  }

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    final defaults = UserPreferencesModel.create();
    return UserPreferencesModel(
      languageCode: (json['languageCode'] as String?) ?? defaults.languageCode,
      themeModeIndex:
          (json['themeModeIndex'] as num?)?.toInt() ?? defaults.themeModeIndex,
      themeColorsString:
          (json['themeColorsString'] as String?) ?? defaults.themeColorsString,
      customThemeColorsString:
          (json['customThemeColorsString'] as String?) ??
          defaults.customThemeColorsString,
      statusFilterIndex:
          (json['statusFilterIndex'] as num?)?.toInt() ??
          defaults.statusFilterIndex,
      timeFilterIndex:
          (json['timeFilterIndex'] as num?)?.toInt() ?? defaults.timeFilterIndex,
      sortOrderIndex:
          (json['sortOrderIndex'] as num?)?.toInt() ?? defaults.sortOrderIndex,
      selectedCategories:
          (json['selectedCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          defaults.selectedCategories,
      viewMode: (json['viewMode'] as String?) ?? defaults.viewMode,
      viewOpenInNewPage:
          (json['viewOpenInNewPage'] as bool?) ?? defaults.viewOpenInNewPage,
      historyViewMode:
          (json['historyViewMode'] as String?) ?? defaults.historyViewMode,
      scheduleDayStartMinutes:
          (json['scheduleDayStartMinutes'] as num?)?.toInt() ??
          defaults.scheduleDayStartMinutes,
      scheduleDayEndMinutes:
          (json['scheduleDayEndMinutes'] as num?)?.toInt() ??
          defaults.scheduleDayEndMinutes,
      scheduleVisibleWeekdays:
          (json['scheduleVisibleWeekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          defaults.scheduleVisibleWeekdays,
      scheduleLabelTextScale:
          (json['scheduleLabelTextScale'] as num?)?.toDouble() ??
          defaults.scheduleLabelTextScale,
    );
  }
}
