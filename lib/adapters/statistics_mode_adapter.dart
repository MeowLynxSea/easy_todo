import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_todo/models/statistics_data_model.dart';

class StatisticsModeAdapter extends TypeAdapter<StatisticsMode> {
  @override
  final int typeId = 7;

  @override
  StatisticsMode read(BinaryReader reader) {
    final index = reader.readByte();

    // Add bounds checking to prevent IndexOutOfRangeException
    if (index < 0 || index >= StatisticsMode.values.length) {
      debugPrint(
        'Warning: Invalid StatisticsMode index $index, defaulting to average',
      );
      return StatisticsMode.average;
    }

    return StatisticsMode.values[index];
  }

  @override
  void write(BinaryWriter writer, StatisticsMode obj) {
    writer.writeByte(obj.index);
  }
}
