// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsModelAdapter extends TypeAdapter<AppSettingsModel> {
  @override
  final int typeId = 3;

  @override
  AppSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettingsModel(
      biometricLockEnabled: fields[0] == null ? false : fields[0] as bool,
      autoUpdateEnabled: fields[1] == null ? true : fields[1] as bool,
      viewMode: fields[2] == null ? 'list' : fields[2] as String,
      viewOpenInNewPage: fields[3] == null ? false : fields[3] as bool,
      historyViewMode: fields[4] == null ? 'list' : fields[4] as String,
      scheduleDayStartMinutes: fields[5] == null ? 0 : fields[5] as int,
      scheduleDayEndMinutes: fields[6] == null ? 1440 : fields[6] as int,
      scheduleVisibleWeekdays: fields[7] == null
          ? [1, 2, 3, 4, 5, 6, 7]
          : (fields[7] as List).cast<int>(),
      scheduleLabelTextScale: fields[8] == null ? 1.0 : fields[8] as double,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettingsModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.biometricLockEnabled)
      ..writeByte(1)
      ..write(obj.autoUpdateEnabled)
      ..writeByte(2)
      ..write(obj.viewMode)
      ..writeByte(3)
      ..write(obj.viewOpenInNewPage)
      ..writeByte(4)
      ..write(obj.historyViewMode)
      ..writeByte(5)
      ..write(obj.scheduleDayStartMinutes)
      ..writeByte(6)
      ..write(obj.scheduleDayEndMinutes)
      ..writeByte(7)
      ..write(obj.scheduleVisibleWeekdays)
      ..writeByte(8)
      ..write(obj.scheduleLabelTextScale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
