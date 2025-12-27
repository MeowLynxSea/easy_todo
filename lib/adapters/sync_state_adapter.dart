import 'package:hive/hive.dart';
import 'package:easy_todo/models/sync_state.dart';

class SyncStateAdapter extends TypeAdapter<SyncState> {
  @override
  final int typeId = 102;

  @override
  SyncState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncState(
      deviceId: fields[0] as String,
      lastHlcWallMsUtc: fields[1] as int,
      lastHlcCounter: fields[2] as int,
      lastServerSeq: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SyncState obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.deviceId)
      ..writeByte(1)
      ..write(obj.lastHlcWallMsUtc)
      ..writeByte(2)
      ..write(obj.lastHlcCounter)
      ..writeByte(3)
      ..write(obj.lastServerSeq);
  }
}
