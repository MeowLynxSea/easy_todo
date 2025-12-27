import 'package:hive/hive.dart';
import 'package:easy_todo/models/sync_outbox_item.dart';

class SyncOutboxItemAdapter extends TypeAdapter<SyncOutboxItem> {
  @override
  final int typeId = 104;

  @override
  SyncOutboxItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncOutboxItem(
      type: fields[0] as String,
      recordId: fields[1] as String,
      lastEnqueuedAtMsUtc: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SyncOutboxItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.recordId)
      ..writeByte(2)
      ..write(obj.lastEnqueuedAtMsUtc);
  }
}
