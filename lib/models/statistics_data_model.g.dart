// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_data_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StatisticsDataModelAdapter extends TypeAdapter<StatisticsDataModel> {
  @override
  final int typeId = 6;

  @override
  StatisticsDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StatisticsDataModel(
      id: fields[0] as String,
      repeatTodoId: fields[1] as String,
      todoId: fields[2] as String,
      value: fields[3] as double,
      unit: fields[4] as String,
      date: fields[5] as DateTime,
      createdAt: fields[6] as DateTime,
      todoCreatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StatisticsDataModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.repeatTodoId)
      ..writeByte(2)
      ..write(obj.todoId)
      ..writeByte(3)
      ..write(obj.value)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.todoCreatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatisticsDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
