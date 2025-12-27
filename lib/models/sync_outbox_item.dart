class SyncOutboxItem {
  final String type;
  final String recordId;
  final int lastEnqueuedAtMsUtc;

  const SyncOutboxItem({
    required this.type,
    required this.recordId,
    required this.lastEnqueuedAtMsUtc,
  });
}
