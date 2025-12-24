import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';

class RepeatTypeAdapter extends TypeAdapter<RepeatType> {
  @override
  final int typeId = 101;

  @override
  RepeatType read(BinaryReader reader) {
    final index = reader.readInt();

    // Add bounds checking to prevent IndexOutOfRangeException
    if (index < 0 || index >= RepeatType.values.length) {
      debugPrint(
        'Warning: Invalid RepeatType index $index, defaulting to daily',
      );
      return RepeatType.daily;
    }

    return RepeatType.values[index];
  }

  @override
  void write(BinaryWriter writer, RepeatType obj) {
    writer.writeInt(obj.index);
  }
}
