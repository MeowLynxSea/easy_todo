import 'package:hive/hive.dart';
import 'package:easy_todo/models/sync_meta.dart';

class SyncMetaAdapter extends TypeAdapter<SyncMeta> {
  @override
  final int typeId = 103;

  @override
  SyncMeta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncMeta(
      type: fields[0] as String,
      recordId: fields[1] as String,
      hlcWallMsUtc: fields[2] as int,
      hlcCounter: fields[3] as int,
      hlcDeviceId: fields[4] as String,
      deletedAtMsUtc: fields[5] as int?,
      schemaVersion: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SyncMeta obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.recordId)
      ..writeByte(2)
      ..write(obj.hlcWallMsUtc)
      ..writeByte(3)
      ..write(obj.hlcCounter)
      ..writeByte(4)
      ..write(obj.hlcDeviceId)
      ..writeByte(5)
      ..write(obj.deletedAtMsUtc)
      ..writeByte(6)
      ..write(obj.schemaVersion);
  }
}
