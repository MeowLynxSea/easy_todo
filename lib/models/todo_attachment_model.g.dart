// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_attachment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoAttachmentModelAdapter extends TypeAdapter<TodoAttachmentModel> {
  @override
  final int typeId = 8;

  @override
  TodoAttachmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TodoAttachmentModel(
      id: fields[0] as String,
      todoId: fields[1] as String,
      fileName: fields[2] as String,
      mimeType: fields[3] as String,
      size: fields[4] as int,
      sha256B64: fields[5] as String,
      chunkSize: fields[6] as int,
      chunkCount: fields[7] as int,
      createdAtMsUtc: fields[8] as int,
      thumbnailAttachmentId: fields[9] as String?,
      localPath: fields[10] as String?,
      receivedChunkCount: fields[11] == null ? 0 : fields[11] as int,
      receivedChunkBitmap: fields[12] as Uint8List?,
      isComplete: fields[13] == null ? false : fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TodoAttachmentModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.todoId)
      ..writeByte(2)
      ..write(obj.fileName)
      ..writeByte(3)
      ..write(obj.mimeType)
      ..writeByte(4)
      ..write(obj.size)
      ..writeByte(5)
      ..write(obj.sha256B64)
      ..writeByte(6)
      ..write(obj.chunkSize)
      ..writeByte(7)
      ..write(obj.chunkCount)
      ..writeByte(8)
      ..write(obj.createdAtMsUtc)
      ..writeByte(9)
      ..write(obj.thumbnailAttachmentId)
      ..writeByte(10)
      ..write(obj.localPath)
      ..writeByte(11)
      ..write(obj.receivedChunkCount)
      ..writeByte(12)
      ..write(obj.receivedChunkBitmap)
      ..writeByte(13)
      ..write(obj.isComplete);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoAttachmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
