// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoModelAdapter extends TypeAdapter<TodoModel> {
  @override
  final int typeId = 0;

  @override
  TodoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TodoModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      isCompleted: fields[3] as bool,
      createdAt: fields[4] as DateTime,
      completedAt: fields[5] as DateTime?,
      order: fields[6] as int,
      reminderTime: fields[7] as DateTime?,
      reminderEnabled: fields[8] as bool,
      timeSpent: fields[9] as int?,
      repeatTodoId: fields[10] as String?,
      isGeneratedFromRepeat: fields[11] == null ? false : fields[11] as bool,
      dataValue: fields[12] as double?,
      dataUnit: fields[13] as String?,
      aiCategory: fields[14] as String?,
      aiPriority: fields[15] == null ? 0 : fields[15] as int,
      aiProcessed: fields[16] == null ? false : fields[16] as bool,
      startTime: fields[17] as DateTime?,
      endTime: fields[18] as DateTime?,
      generatedKey: fields[19] as String?,
      scheduleColorSeed: fields[20] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TodoModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.completedAt)
      ..writeByte(6)
      ..write(obj.order)
      ..writeByte(7)
      ..write(obj.reminderTime)
      ..writeByte(8)
      ..write(obj.reminderEnabled)
      ..writeByte(9)
      ..write(obj.timeSpent)
      ..writeByte(10)
      ..write(obj.repeatTodoId)
      ..writeByte(11)
      ..write(obj.isGeneratedFromRepeat)
      ..writeByte(12)
      ..write(obj.dataValue)
      ..writeByte(13)
      ..write(obj.dataUnit)
      ..writeByte(14)
      ..write(obj.aiCategory)
      ..writeByte(15)
      ..write(obj.aiPriority)
      ..writeByte(16)
      ..write(obj.aiProcessed)
      ..writeByte(17)
      ..write(obj.startTime)
      ..writeByte(18)
      ..write(obj.endTime)
      ..writeByte(19)
      ..write(obj.generatedKey)
      ..writeByte(20)
      ..write(obj.scheduleColorSeed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
