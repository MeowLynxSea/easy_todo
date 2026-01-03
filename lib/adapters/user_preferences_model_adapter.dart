import 'package:easy_todo/models/user_preferences_model.dart';
import 'package:hive/hive.dart';

class UserPreferencesModelAdapter extends TypeAdapter<UserPreferencesModel> {
  @override
  final int typeId = 12;

  @override
  UserPreferencesModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferencesModel(
      languageCode: fields[7] == null ? 'zh' : fields[7] as String,
      themeModeIndex: fields[8] == null ? 2 : fields[8] as int,
      themeColorsString: fields[13] == null ? '' : fields[13] as String,
      customThemeColorsString: fields[14] == null ? '' : fields[14] as String,
      statusFilterIndex: fields[9] == null ? 0 : fields[9] as int,
      timeFilterIndex: fields[10] == null ? 0 : fields[10] as int,
      sortOrderIndex: fields[11] == null ? 0 : fields[11] as int,
      selectedCategories:
          (fields[12] as List?)?.cast<String>() ?? const <String>[],
      viewMode: fields[0] == null ? 'list' : fields[0] as String,
      viewOpenInNewPage: fields[1] == null ? false : fields[1] as bool,
      historyViewMode: fields[2] == null ? 'list' : fields[2] as String,
      scheduleDayStartMinutes: fields[3] == null ? 0 : fields[3] as int,
      scheduleDayEndMinutes: fields[4] == null ? 1440 : fields[4] as int,
      scheduleVisibleWeekdays:
          (fields[5] as List?)?.cast<int>() ?? const <int>[1, 2, 3, 4, 5, 6, 7],
      scheduleVisibleDayCount: fields[17] == null ? 5 : fields[17] as int,
      scheduleLabelTextScale: fields[6] == null ? 1.0 : fields[6] as double,
      scheduleActiveColorGroupId: fields[15] == null
          ? 'preset:warm_cool'
          : fields[15] as String,
      scheduleCustomColorGroupsString: fields[16] == null
          ? ''
          : fields[16] as String,
      navigationTabOrder:
          (fields[18] as List?)?.cast<String>() ??
          const <String>[
            'todos',
            'importanceQuadrant',
            'schedule',
            'history',
            'statistics',
            'preferences',
          ],
      navigationEnabledTabs:
          (fields[19] as List?)?.cast<String>() ??
          const <String>[
            'todos',
            'importanceQuadrant',
            'schedule',
            'history',
            'statistics',
            'preferences',
          ],
      navigationDefaultTab: fields[20] == null ? 'todos' : fields[20] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferencesModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.viewMode)
      ..writeByte(1)
      ..write(obj.viewOpenInNewPage)
      ..writeByte(2)
      ..write(obj.historyViewMode)
      ..writeByte(3)
      ..write(obj.scheduleDayStartMinutes)
      ..writeByte(4)
      ..write(obj.scheduleDayEndMinutes)
      ..writeByte(5)
      ..write(obj.scheduleVisibleWeekdays)
      ..writeByte(17)
      ..write(obj.scheduleVisibleDayCount)
      ..writeByte(6)
      ..write(obj.scheduleLabelTextScale)
      ..writeByte(7)
      ..write(obj.languageCode)
      ..writeByte(8)
      ..write(obj.themeModeIndex)
      ..writeByte(9)
      ..write(obj.statusFilterIndex)
      ..writeByte(10)
      ..write(obj.timeFilterIndex)
      ..writeByte(11)
      ..write(obj.sortOrderIndex)
      ..writeByte(12)
      ..write(obj.selectedCategories)
      ..writeByte(13)
      ..write(obj.themeColorsString)
      ..writeByte(14)
      ..write(obj.customThemeColorsString)
      ..writeByte(15)
      ..write(obj.scheduleActiveColorGroupId)
      ..writeByte(16)
      ..write(obj.scheduleCustomColorGroupsString)
      ..writeByte(18)
      ..write(obj.navigationTabOrder)
      ..writeByte(19)
      ..write(obj.navigationEnabledTabs)
      ..writeByte(20)
      ..write(obj.navigationDefaultTab);
  }
}
