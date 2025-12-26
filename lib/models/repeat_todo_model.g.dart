// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repeat_todo_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RepeatTodoModelAdapter extends TypeAdapter<RepeatTodoModel> {
  @override
  final int typeId = 5;

  @override
  RepeatTodoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RepeatTodoModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      repeatType: fields[3] as RepeatType,
      weekDays: (fields[4] as List?)?.cast<int>(),
      dayOfMonth: fields[5] as int?,
      startDate: fields[6] as DateTime?,
      endDate: fields[7] as DateTime?,
      createdAt: fields[8] as DateTime,
      isActive: fields[9] as bool,
      lastGeneratedDate: fields[10] as DateTime?,
      order: fields[11] as int,
      dataStatisticsEnabled: fields[12] as bool,
      statisticsModes: (fields[13] as List?)?.cast<StatisticsMode>(),
      dataUnit: fields[14] as String?,
      aiCategory: fields[15] as String?,
      aiPriority: fields[16] == null ? 0 : fields[16] as int,
      aiProcessed: fields[17] == null ? false : fields[17] as bool,
      startTimeMinutes: fields[18] as int?,
      endTimeMinutes: fields[19] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, RepeatTodoModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.repeatType)
      ..writeByte(4)
      ..write(obj.weekDays)
      ..writeByte(5)
      ..write(obj.dayOfMonth)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.endDate)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.lastGeneratedDate)
      ..writeByte(11)
      ..write(obj.order)
      ..writeByte(12)
      ..write(obj.dataStatisticsEnabled)
      ..writeByte(13)
      ..write(obj.statisticsModes)
      ..writeByte(14)
      ..write(obj.dataUnit)
      ..writeByte(15)
      ..write(obj.aiCategory)
      ..writeByte(16)
      ..write(obj.aiPriority)
      ..writeByte(17)
      ..write(obj.aiProcessed)
      ..writeByte(18)
      ..write(obj.startTimeMinutes)
      ..writeByte(19)
      ..write(obj.endTimeMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatTodoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
