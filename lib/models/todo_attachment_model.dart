import 'dart:typed_data';

import 'package:hive/hive.dart';

part 'todo_attachment_model.g.dart';

@HiveType(typeId: 8)
class TodoAttachmentModel extends HiveObject {
  static const Object _unset = Object();

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String todoId;

  @HiveField(2)
  final String fileName;

  @HiveField(3)
  final String mimeType;

  @HiveField(4)
  final int size;

  @HiveField(5)
  final String sha256B64;

  @HiveField(6)
  final int chunkSize;

  @HiveField(7)
  final int chunkCount;

  @HiveField(8)
  final int createdAtMsUtc;

  @HiveField(9)
  final String? thumbnailAttachmentId;

  /// Local file path; not synced.
  @HiveField(10)
  final String? localPath;

  @HiveField(11, defaultValue: 0)
  final int receivedChunkCount;

  /// Bitset of received chunks (len = ceil(chunkCount/8)); not synced.
  @HiveField(12)
  final Uint8List? receivedChunkBitmap;

  /// True when the attachment file is available locally; not synced.
  @HiveField(13, defaultValue: false)
  final bool isComplete;

  TodoAttachmentModel({
    required this.id,
    required this.todoId,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.sha256B64,
    required this.chunkSize,
    required this.chunkCount,
    required this.createdAtMsUtc,
    this.thumbnailAttachmentId,
    this.localPath,
    this.receivedChunkCount = 0,
    this.receivedChunkBitmap,
    this.isComplete = false,
  });

  TodoAttachmentModel copyWith({
    String? id,
    String? todoId,
    String? fileName,
    String? mimeType,
    int? size,
    String? sha256B64,
    int? chunkSize,
    int? chunkCount,
    int? createdAtMsUtc,
    Object? thumbnailAttachmentId = _unset,
    Object? localPath = _unset,
    int? receivedChunkCount,
    Object? receivedChunkBitmap = _unset,
    bool? isComplete,
  }) {
    return TodoAttachmentModel(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      sha256B64: sha256B64 ?? this.sha256B64,
      chunkSize: chunkSize ?? this.chunkSize,
      chunkCount: chunkCount ?? this.chunkCount,
      createdAtMsUtc: createdAtMsUtc ?? this.createdAtMsUtc,
      thumbnailAttachmentId: identical(thumbnailAttachmentId, _unset)
          ? this.thumbnailAttachmentId
          : thumbnailAttachmentId as String?,
      localPath: identical(localPath, _unset)
          ? this.localPath
          : localPath as String?,
      receivedChunkCount: receivedChunkCount ?? this.receivedChunkCount,
      receivedChunkBitmap: identical(receivedChunkBitmap, _unset)
          ? this.receivedChunkBitmap
          : receivedChunkBitmap as Uint8List?,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toSyncJson() => {
    'attachmentId': id,
    'todoId': todoId,
    'fileName': fileName,
    'mimeType': mimeType,
    'size': size,
    'sha256': sha256B64,
    'chunkSize': chunkSize,
    'chunkCount': chunkCount,
    'createdAtMsUtc': createdAtMsUtc,
    if (thumbnailAttachmentId != null)
      'thumbnailAttachmentId': thumbnailAttachmentId,
  };

  factory TodoAttachmentModel.fromSyncJson(Map<String, dynamic> json) {
    return TodoAttachmentModel(
      id: json['attachmentId'] as String,
      todoId: json['todoId'] as String,
      fileName: json['fileName'] as String,
      mimeType: (json['mimeType'] as String?) ?? 'application/octet-stream',
      size: (json['size'] as num).toInt(),
      sha256B64: json['sha256'] as String,
      chunkSize: (json['chunkSize'] as num).toInt(),
      chunkCount: (json['chunkCount'] as num).toInt(),
      createdAtMsUtc: (json['createdAtMsUtc'] as num).toInt(),
      thumbnailAttachmentId: json['thumbnailAttachmentId'] as String?,
    );
  }
}
