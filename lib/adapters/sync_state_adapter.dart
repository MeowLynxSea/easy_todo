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
      dekId: fields[7] as String?,
      didBootstrapLocalRecords: (fields[8] as bool?) ?? false,
      didBootstrapSettings: (fields[9] as bool?) ?? false,
      didBackfillOutboxFromMeta: (fields[10] as bool?) ?? false,
      authProvider: (fields[11] as String?) ?? '',
      authUserId: (fields[12] as String?) ?? '',
      autoSyncIntervalSeconds:
          (fields[13] as int?) ?? SyncState.defaultAutoSyncIntervalSeconds,
    );
  }

  @override
  void write(BinaryWriter writer, SyncState obj) {
    writer
      ..writeByte(13)
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
      ..writeByte(7)
      ..write(obj.dekId)
      ..writeByte(8)
      ..write(obj.didBootstrapLocalRecords)
      ..writeByte(9)
      ..write(obj.didBootstrapSettings)
      ..writeByte(10)
      ..write(obj.didBackfillOutboxFromMeta)
      ..writeByte(11)
      ..write(obj.authProvider)
      ..writeByte(12)
      ..write(obj.authUserId)
      ..writeByte(13)
      ..write(obj.autoSyncIntervalSeconds);
  }
}
