// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationSettingsModelAdapter
    extends TypeAdapter<NotificationSettingsModel> {
  @override
  final int typeId = 2;

  @override
  NotificationSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationSettingsModel(
      notificationsEnabled: fields[0] as bool,
      dailySummaryEnabled: fields[1] as bool,
      dailySummaryTime: fields[2] as TimeOfDay?,
      defaultReminderEnabled: fields[3] as bool,
      defaultReminderMinutesBefore: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSettingsModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.notificationsEnabled)
      ..writeByte(1)
      ..write(obj.dailySummaryEnabled)
      ..writeByte(2)
      ..write(obj.dailySummaryTime)
      ..writeByte(3)
      ..write(obj.defaultReminderEnabled)
      ..writeByte(4)
      ..write(obj.defaultReminderMinutesBefore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
