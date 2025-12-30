class TodoAttachmentChunkRecordId {
  final String attachmentId;
  final int chunkIndex;

  const TodoAttachmentChunkRecordId({
    required this.attachmentId,
    required this.chunkIndex,
  });

  static String build(String attachmentId, int chunkIndex) =>
      '$attachmentId:$chunkIndex';

  static TodoAttachmentChunkRecordId? tryParse(String recordId) {
    final trimmed = recordId.trim();
    final sep = trimmed.lastIndexOf(':');
    if (sep <= 0 || sep == trimmed.length - 1) return null;

    final attachmentId = trimmed.substring(0, sep);
    final indexStr = trimmed.substring(sep + 1);
    final index = int.tryParse(indexStr);
    if (attachmentId.isEmpty || index == null || index < 0) return null;
    return TodoAttachmentChunkRecordId(
      attachmentId: attachmentId,
      chunkIndex: index,
    );
  }
}
