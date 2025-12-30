import 'dart:async';
import 'dart:typed_data';

import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/sync_outbox_item.dart';
import 'package:easy_todo/models/todo_attachment_model.dart';
import 'package:easy_todo/providers/sync_provider.dart';
import 'package:easy_todo/services/attachment_download.dart';
import 'package:easy_todo/services/attachment_storage_service.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/file_service.dart';
import 'package:easy_todo/services/sync_write_service.dart';
import 'package:easy_todo/services/todo_attachment_service.dart';
import 'package:easy_todo/utils/todo_attachment_record_id.dart';
import 'package:easy_todo/widgets/attachment_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class TodoAttachmentsSection extends StatefulWidget {
  final String todoId;

  const TodoAttachmentsSection({super.key, required this.todoId});

  @override
  State<TodoAttachmentsSection> createState() => _TodoAttachmentsSectionState();
}

class _TodoAttachmentsSectionState extends State<TodoAttachmentsSection> {
  final HiveService _hiveService = HiveService();
  final SyncWriteService _syncWriteService = SyncWriteService();
  final TodoAttachmentService _attachmentService = TodoAttachmentService();
  final AttachmentStorageService _attachmentStorage =
      AttachmentStorageService();

  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Consumer<SyncProvider>(
      builder: (context, sync, child) {
        final canSyncNow =
            sync.isConfigured &&
            sync.syncEnabled &&
            sync.isUnlocked &&
            sync.status != SyncStatus.running;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.todoAttachments,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (sync.status == SyncStatus.running)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  tooltip: l10n.retry,
                  onPressed: canSyncNow ? () => _retrySync() : null,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: l10n.todoAttachmentAdd,
                  onPressed: !_busy ? () => _addAttachment() : null,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file),
                ),
              ],
            ),
            if (sync.lastErrorCode == SyncErrorCode.quotaExceeded)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ErrorBanner(
                  icon: Icons.cloud_off_outlined,
                  text: l10n.cloudSyncErrorQuotaExceeded,
                ),
              ),
            ValueListenableBuilder<Box<TodoAttachmentModel>>(
              valueListenable: _hiveService.todoAttachmentsBox.listenable(),
              builder: (context, box, child) {
                final attachments =
                    box.values
                        .where((a) => a.todoId == widget.todoId)
                        .where(
                          (a) => !_syncWriteService.isTombstonedSync(
                            SyncTypes.todoAttachment,
                            a.id,
                          ),
                        )
                        .toList(growable: false)
                      ..sort(
                        (a, b) => b.createdAtMsUtc.compareTo(a.createdAtMsUtc),
                      );

                if (attachments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.todoAttachmentsEmpty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ValueListenableBuilder<Box<SyncOutboxItem>>(
                  valueListenable: _hiveService.syncOutboxBox.listenable(),
                  builder: (context, outbox, child) {
                    final pendingChunksByAttachment = _computePendingChunks(
                      outbox,
                    );

                    return Column(
                      children: [
                        for (final a in attachments)
                          _AttachmentTile(
                            attachment: a,
                            pendingChunkCount:
                                pendingChunksByAttachment[a.id] ?? 0,
                            pendingMeta: outbox.containsKey(
                              SyncWriteService.metaKeyOf(
                                SyncTypes.todoAttachment,
                                a.id,
                              ),
                            ),
                            pendingCommit: outbox.containsKey(
                              SyncWriteService.metaKeyOf(
                                SyncTypes.todoAttachmentCommit,
                                a.id,
                              ),
                            ),
                            onOpenImage: _openImagePreview,
                            onExport: _exportAttachment,
                            onRemove: _removeAttachment,
                            onRetry: canSyncNow ? () => _retrySync() : null,
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Map<String, int> _computePendingChunks(Box<SyncOutboxItem> outbox) {
    final counts = <String, int>{};
    final prefix = '${SyncTypes.todoAttachmentChunk}:';

    for (final key in outbox.keys.cast<String>()) {
      if (!key.startsWith(prefix)) continue;
      final recordId = key.substring(prefix.length);
      final parsed = TodoAttachmentChunkRecordId.tryParse(recordId);
      if (parsed == null) continue;
      counts[parsed.attachmentId] = (counts[parsed.attachmentId] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _retrySync() async {
    final sync = context.read<SyncProvider>();
    if (sync.status == SyncStatus.running) return;
    try {
      await sync.syncNow(trigger: SyncRunTrigger.manual);
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final message = sync.lastErrorCode == SyncErrorCode.quotaExceeded
          ? l10n.cloudSyncErrorQuotaExceeded
          : (sync.lastErrorDetail ?? l10n.cloudSyncErrorUnknown);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _addAttachment() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    setState(() => _busy = true);
    try {
      final mimeType = _guessMimeType(file.name);
      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null) {
          throw StateError('Missing file bytes');
        }
        await _attachmentService.addAttachment(
          todoId: widget.todoId,
          fileName: file.name,
          bytes: bytes,
          mimeType: mimeType,
        );
      } else {
        final path = file.path;
        if (path == null || path.trim().isEmpty) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.cannotAccessFile),
              backgroundColor: errorColor,
            ),
          );
          return;
        }
        await _attachmentService.addAttachment(
          todoId: widget.todoId,
          fileName: file.name,
          sourcePath: path,
          mimeType: mimeType,
        );
      }

      if (!mounted) return;
      unawaited(_retrySync());
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.todoAttachmentAddFailed(e.toString())),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _guessMimeType(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.gif')) return 'image/gif';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.bmp')) return 'image/bmp';
    if (name.endsWith('.heic')) return 'image/heic';
    if (name.endsWith('.heif')) return 'image/heif';
    return 'application/octet-stream';
  }

  bool _isImageAttachment(TodoAttachmentModel attachment) {
    final mime = attachment.mimeType.trim().toLowerCase();
    if (mime.startsWith('image/')) return true;
    return _guessMimeType(attachment.fileName).startsWith('image/');
  }

  Future<void> _openImagePreview(TodoAttachmentModel attachment) async {
    final path = attachment.localPath;
    if (!_isImageAttachment(attachment)) return;
    if (path == null || path.trim().isEmpty || !attachment.isComplete) return;

    final l10n = AppLocalizations.of(context)!;
    if (kIsWeb) {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            child: Stack(
              children: [
                Positioned.fill(
                  child: FutureBuilder<Uint8List>(
                    future: _readAllBytes(attachment),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final bytes = snapshot.data;
                      if (bytes == null || bytes.isEmpty) {
                        return Center(
                          child: Text(l10n.todoAttachmentNotAvailable),
                        );
                      }
                      return InteractiveViewer(
                        child: Image.memory(bytes, fit: BoxFit.contain),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  child: AttachmentImage(filePath: path, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  tooltip: l10n.close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportAttachment(TodoAttachmentModel attachment) async {
    final l10n = AppLocalizations.of(context)!;
    final path = attachment.localPath;
    if (path == null || path.trim().isEmpty || !attachment.isComplete) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.todoAttachmentNotAvailable)));
      return;
    }

    try {
      if (kIsWeb) {
        final bytes = await _readAllBytes(attachment);
        await downloadBytes(
          bytes,
          fileName: attachment.fileName,
          mimeType: attachment.mimeType,
        );
        return;
      }
      await Share.shareXFiles([
        XFile(path, name: attachment.fileName, mimeType: attachment.mimeType),
      ]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.shareFailed(e.toString()))));
    }
  }

  Future<Uint8List> _readAllBytes(TodoAttachmentModel attachment) async {
    final path = attachment.localPath;
    if (path == null || path.trim().isEmpty) {
      throw StateError('Missing localPath');
    }

    final chunkSize = attachment.chunkSize > 0
        ? attachment.chunkSize
        : TodoAttachmentService.chunkSizeBytes;
    final chunkCount = attachment.chunkCount;
    final size = attachment.size;

    final builder = BytesBuilder(copy: false);
    for (var i = 0; i < chunkCount; i++) {
      final offset = i * chunkSize;
      final length = (size - offset).clamp(0, chunkSize).toInt();
      final chunk = await _attachmentStorage.readChunk(
        filePath: path,
        offset: offset,
        length: length,
      );
      builder.add(chunk);
    }
    return builder.toBytes();
  }

  Future<void> _removeAttachment(TodoAttachmentModel attachment) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.todoAttachmentRemoveConfirmTitle),
        content: Text(l10n.todoAttachmentRemoveConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await _attachmentService.removeAttachment(attachment.id);
      if (!mounted) return;
      unawaited(_retrySync());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _AttachmentTile extends StatelessWidget {
  final TodoAttachmentModel attachment;
  final int pendingChunkCount;
  final bool pendingMeta;
  final bool pendingCommit;
  final ValueChanged<TodoAttachmentModel> onOpenImage;
  final ValueChanged<TodoAttachmentModel> onExport;
  final ValueChanged<TodoAttachmentModel> onRemove;
  final VoidCallback? onRetry;

  const _AttachmentTile({
    required this.attachment,
    required this.pendingChunkCount,
    required this.pendingMeta,
    required this.pendingCommit,
    required this.onOpenImage,
    required this.onExport,
    required this.onRemove,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final isDownloading =
        !attachment.isComplete &&
        attachment.chunkCount > 0 &&
        attachment.receivedChunkCount < attachment.chunkCount;

    final isUploading =
        pendingMeta ||
        pendingCommit ||
        (attachment.chunkCount > 0 && pendingChunkCount > 0);

    final totalChunks = attachment.chunkCount;
    final uploadedChunks = (totalChunks - pendingChunkCount).clamp(
      0,
      totalChunks,
    );

    final progressValue = isDownloading && totalChunks > 0
        ? attachment.receivedChunkCount / totalChunks
        : isUploading && totalChunks > 0
        ? uploadedChunks / totalChunks
        : null;

    final status = isDownloading
        ? totalChunks > 0
              ? '${l10n.todoAttachmentDownloading} ${attachment.receivedChunkCount}/$totalChunks'
              : l10n.todoAttachmentDownloading
        : isUploading
        ? totalChunks > 0
              ? '${l10n.todoAttachmentUploading} $uploadedChunks/$totalChunks'
              : l10n.todoAttachmentUploading
        : l10n.todoAttachmentReady;

    final canExport =
        attachment.isComplete &&
        (attachment.localPath?.trim().isNotEmpty ?? false);

    final isImage =
        attachment.mimeType.toLowerCase().startsWith('image/') ||
        attachment.fileName.toLowerCase().endsWith('.jpg') ||
        attachment.fileName.toLowerCase().endsWith('.jpeg') ||
        attachment.fileName.toLowerCase().endsWith('.png') ||
        attachment.fileName.toLowerCase().endsWith('.gif') ||
        attachment.fileName.toLowerCase().endsWith('.webp') ||
        attachment.fileName.toLowerCase().endsWith('.bmp') ||
        attachment.fileName.toLowerCase().endsWith('.heic') ||
        attachment.fileName.toLowerCase().endsWith('.heif');

    final leading = isImage && canExport
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AttachmentImage(
              filePath: attachment.localPath!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          )
        : Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: leading,
        title: Text(
          attachment.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${FileService.formatFileSize(attachment.size)} · $status',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (progressValue != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: progressValue),
              ),
            ],
          ],
        ),
        onTap: isImage ? () => onOpenImage(attachment) : null,
        trailing: Wrap(
          spacing: 4,
          children: [
            if (onRetry != null && (isDownloading || isUploading))
              IconButton(
                tooltip: l10n.retry,
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
              ),
            IconButton(
              tooltip: l10n.todoAttachmentExport,
              onPressed: canExport ? () => onExport(attachment) : null,
              icon: const Icon(Icons.ios_share_outlined),
            ),
            IconButton(
              tooltip: l10n.delete,
              onPressed: () => onRemove(attachment),
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ErrorBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
