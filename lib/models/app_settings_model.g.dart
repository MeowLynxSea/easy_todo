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
    );
  }

  @override
  void write(BinaryWriter writer, AppSettingsModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.biometricLockEnabled)
      ..writeByte(1)
      ..write(obj.autoUpdateEnabled)
      ..writeByte(2)
      ..write(obj.viewMode)
      ..writeByte(3)
      ..write(obj.viewOpenInNewPage)
      ..writeByte(4)
      ..write(obj.historyViewMode);
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
