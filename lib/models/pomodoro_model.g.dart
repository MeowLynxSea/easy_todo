// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pomodoro_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PomodoroModelAdapter extends TypeAdapter<PomodoroModel> {
  @override
  final int typeId = 4;

  @override
  PomodoroModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PomodoroModel(
      id: fields[0] as String,
      todoId: fields[1] as String,
      duration: fields[2] as int,
      actualDuration: fields[3] as int?,
      startTime: fields[4] as DateTime,
      endTime: fields[5] as DateTime?,
      isCompleted: fields[6] as bool,
      isBreak: fields[7] as bool,
      workDuration: fields[8] as int,
      breakDuration: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PomodoroModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.todoId)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.actualDuration)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.isBreak)
      ..writeByte(8)
      ..write(obj.workDuration)
      ..writeByte(9)
      ..write(obj.breakDuration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
