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
      syncEnabled: (fields[4] as bool?) ?? false,
      serverUrl: (fields[5] as String?) ?? '',
      authToken: (fields[6] as String?) ?? '',
      dekId: fields[7] as String?,
      didBootstrapLocalRecords: (fields[8] as bool?) ?? false,
      didBootstrapSettings: (fields[9] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, SyncState obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.deviceId)
      ..writeByte(1)
      ..write(obj.lastHlcWallMsUtc)
      ..writeByte(2)
      ..write(obj.lastHlcCounter)
      ..writeByte(3)
      ..write(obj.lastServerSeq)
      ..writeByte(4)
      ..write(obj.syncEnabled)
      ..writeByte(5)
      ..write(obj.serverUrl)
      ..writeByte(6)
      ..write(obj.authToken)
      ..writeByte(7)
      ..write(obj.dekId)
      ..writeByte(8)
      ..write(obj.didBootstrapLocalRecords)
      ..writeByte(9)
      ..write(obj.didBootstrapSettings);
  }
}
