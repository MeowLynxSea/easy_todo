import 'dart:convert';

import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/todo_attachment_model.dart';
import 'package:easy_todo/services/attachment_read_service.dart';
import 'package:easy_todo/services/blob_url_service.dart';
import 'package:easy_todo/services/video_player_controller_factory.dart';
import 'package:easy_todo/utils/attachment_file_type.dart';
import 'package:easy_todo/widgets/attachment_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:just_audio/just_audio.dart';
import 'package:printing/printing.dart';
import 'package:video_player/video_player.dart';

enum MarkdownPreviewMode { rendered, source }

class AttachmentPreviewScreen extends StatefulWidget {
  final TodoAttachmentModel attachment;
  final AttachmentFileType fileType;
  final bool showCloseButton;

  const AttachmentPreviewScreen({
    super.key,
    required this.attachment,
    required this.fileType,
    required this.showCloseButton,
  });

  @override
  State<AttachmentPreviewScreen> createState() =>
      _AttachmentPreviewScreenState();
}

class _AttachmentPreviewScreenState extends State<AttachmentPreviewScreen> {
  MarkdownPreviewMode _markdownMode = MarkdownPreviewMode.rendered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: widget.showCloseButton
            ? IconButton(
                tooltip: l10n.close,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              )
            : null,
        title: Text(widget.attachment.fileName),
        actions: [
          if (widget.fileType == AttachmentFileType.markdown)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SegmentedButton<MarkdownPreviewMode>(
                segments: [
                  ButtonSegment(
                    value: MarkdownPreviewMode.rendered,
                    label: Text(l10n.todoAttachmentMarkdownRendered),
                    icon: const Icon(Icons.visibility_outlined),
                  ),
                  ButtonSegment(
                    value: MarkdownPreviewMode.source,
                    label: Text(l10n.todoAttachmentMarkdownSource),
                    icon: const Icon(Icons.code_outlined),
                  ),
                ],
                selected: {_markdownMode},
                onSelectionChanged: (next) {
                  setState(() => _markdownMode = next.first);
                },
              ),
            ),
        ],
      ),
      body: _AttachmentPreviewBody(
        attachment: widget.attachment,
        fileType: widget.fileType,
        markdownMode: _markdownMode,
      ),
    );
  }
}

class _AttachmentPreviewBody extends StatelessWidget {
  final TodoAttachmentModel attachment;
  final AttachmentFileType fileType;
  final MarkdownPreviewMode markdownMode;

  const _AttachmentPreviewBody({
    required this.attachment,
    required this.fileType,
    required this.markdownMode,
  });

  @override
  Widget build(BuildContext context) {
    return switch (fileType) {
      AttachmentFileType.image => _AttachmentImagePreview(
        attachment: attachment,
      ),
      AttachmentFileType.audio => _AttachmentAudioPreview(
        attachment: attachment,
      ),
      AttachmentFileType.video => _AttachmentVideoPreview(
        attachment: attachment,
      ),
      AttachmentFileType.pdf => _AttachmentPdfPreview(attachment: attachment),
      AttachmentFileType.text => _AttachmentTextPreview(attachment: attachment),
      AttachmentFileType.markdown => _AttachmentMarkdownPreview(
        attachment: attachment,
        mode: markdownMode,
      ),
      AttachmentFileType.other => const SizedBox.shrink(),
    };
  }
}

class _AttachmentImagePreview extends StatelessWidget {
  final TodoAttachmentModel attachment;

  const _AttachmentImagePreview({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final reader = AttachmentReadService();
    final path = attachment.localPath;

    if (path == null || path.trim().isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(child: Text(l10n.todoAttachmentNotAvailable));
    }

    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: reader.readAllBytes(attachment),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) {
            final l10n = AppLocalizations.of(context)!;
            return Center(child: Text(l10n.todoAttachmentNotAvailable));
          }
          return InteractiveViewer(
            child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
          );
        },
      );
    }

    return InteractiveViewer(
      child: Center(
        child: AttachmentImage(filePath: path, fit: BoxFit.contain),
      ),
    );
  }
}

class _AttachmentPdfPreview extends StatelessWidget {
  final TodoAttachmentModel attachment;

  const _AttachmentPdfPreview({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final reader = AttachmentReadService();
    return FutureBuilder<Uint8List>(
      future: reader.readAllBytes(attachment),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return Center(child: Text(l10n.todoAttachmentNotAvailable));
        }

        return PdfPreview(
          build: (format) async => bytes,
          canChangeOrientation: false,
          canChangePageFormat: false,
          allowPrinting: false,
          allowSharing: false,
          canDebug: false,
        );
      },
    );
  }
}

class _AttachmentTextPreview extends StatelessWidget {
  final TodoAttachmentModel attachment;

  const _AttachmentTextPreview({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final reader = AttachmentReadService();
    final theme = Theme.of(context);

    return FutureBuilder<Uint8List>(
      future: reader.readAllBytes(attachment),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return Center(child: Text(l10n.todoAttachmentNotAvailable));
        }
        final text = utf8.decode(bytes, allowMalformed: true);
        return SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SelectableText(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttachmentMarkdownPreview extends StatelessWidget {
  final TodoAttachmentModel attachment;
  final MarkdownPreviewMode mode;

  const _AttachmentMarkdownPreview({
    required this.attachment,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final reader = AttachmentReadService();
    final theme = Theme.of(context);

    return FutureBuilder<Uint8List>(
      future: reader.readAllBytes(attachment),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return Center(child: Text(l10n.todoAttachmentNotAvailable));
        }
        final text = utf8.decode(bytes, allowMalformed: true);

        if (mode == MarkdownPreviewMode.source) {
          return SelectionArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SelectableText(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          );
        }

        return Markdown(
          data: text,
          selectable: true,
          padding: const EdgeInsets.all(16),
        );
      },
    );
  }
}

class _AttachmentAudioPreview extends StatefulWidget {
  final TodoAttachmentModel attachment;

  const _AttachmentAudioPreview({required this.attachment});

  @override
  State<_AttachmentAudioPreview> createState() =>
      _AttachmentAudioPreviewState();
}

class _AttachmentAudioPreviewState extends State<_AttachmentAudioPreview> {
  final AttachmentReadService _reader = AttachmentReadService();
  final AudioPlayer _player = AudioPlayer();

  Future<void>? _initFuture;
  String? _objectUrl;

  @override
  void initState() {
    super.initState();
    _initFuture = _init();
  }

  @override
  void dispose() {
    _player.dispose();
    final url = _objectUrl;
    if (url != null) revokeObjectUrl(url);
    super.dispose();
  }

  Future<void> _init() async {
    final path = widget.attachment.localPath;
    if (path == null || path.trim().isEmpty) {
      throw StateError('Missing localPath');
    }

    final mimeType = effectiveAttachmentMimeType(
      fileName: widget.attachment.fileName,
      mimeType: widget.attachment.mimeType,
    );

    if (kIsWeb) {
      final bytes = await _reader.readAllBytes(widget.attachment);
      _objectUrl = createObjectUrlFromBytes(bytes, mimeType: mimeType);
      await _player.setUrl(_objectUrl!);
      return;
    }

    await _player.setFilePath(path);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final l10n = AppLocalizations.of(context)!;
          return Center(child: Text(l10n.todoAttachmentNotAvailable));
        }
        return _AudioPlayerControls(player: _player);
      },
    );
  }
}

class _AudioPlayerControls extends StatelessWidget {
  final AudioPlayer player;

  const _AudioPlayerControls({required this.player});

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    }
    return '${two(minutes)}:${two(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, stateSnapshot) {
        final state = stateSnapshot.data;
        final processingState = state?.processingState;
        final playing = state?.playing ?? false;

        return StreamBuilder<Duration?>(
          stream: player.durationStream,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;

            return StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final maxMs = duration.inMilliseconds.clamp(0, 1 << 31);
                final posMs = position.inMilliseconds.clamp(0, maxMs);

                final isBuffering =
                    processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.audiotrack_outlined,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Slider(
                        value: posMs.toDouble(),
                        max: maxMs.toDouble(),
                        onChanged: maxMs <= 0
                            ? null
                            : (v) => player.seek(
                                Duration(milliseconds: v.round()),
                              ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(Duration(milliseconds: posMs)),
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            _formatDuration(duration),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: isBuffering
                            ? null
                            : () async {
                                if (playing) {
                                  await player.pause();
                                } else {
                                  await player.play();
                                }
                              },
                        icon: Icon(
                          isBuffering
                              ? Icons.hourglass_empty
                              : playing
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          isBuffering
                              ? l10n.loading
                              : (playing ? l10n.pause : l10n.start),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AttachmentVideoPreview extends StatefulWidget {
  final TodoAttachmentModel attachment;

  const _AttachmentVideoPreview({required this.attachment});

  @override
  State<_AttachmentVideoPreview> createState() =>
      _AttachmentVideoPreviewState();
}

class _AttachmentVideoPreviewState extends State<_AttachmentVideoPreview> {
  final AttachmentReadService _reader = AttachmentReadService();

  VideoPlayerController? _controller;
  Future<void>? _initFuture;
  String? _objectUrl;

  @override
  void initState() {
    super.initState();
    _initFuture = _init();
  }

  @override
  void dispose() {
    final controller = _controller;
    controller?.removeListener(_onControllerChanged);
    controller?.dispose();
    final url = _objectUrl;
    if (url != null) revokeObjectUrl(url);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _init() async {
    final path = widget.attachment.localPath;
    if (path == null || path.trim().isEmpty) {
      throw StateError('Missing localPath');
    }

    if (kIsWeb) {
      final mimeType = effectiveAttachmentMimeType(
        fileName: widget.attachment.fileName,
        mimeType: widget.attachment.mimeType,
      );
      final bytes = await _reader.readAllBytes(widget.attachment);
      _objectUrl = createObjectUrlFromBytes(bytes, mimeType: mimeType);
      _controller = createVideoPlayerController(_objectUrl!);
    } else {
      _controller = createVideoPlayerController(path);
    }

    final controller = _controller!;
    await controller.initialize();
    controller.addListener(_onControllerChanged);
    controller.setLooping(true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final l10n = AppLocalizations.of(context)!;
          return Center(child: Text(l10n.todoAttachmentNotAvailable));
        }
        final controller = _controller;
        if (controller == null || !controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return _VideoPlayerControls(controller: controller);
      },
    );
  }
}

class _VideoPlayerControls extends StatelessWidget {
  final VideoPlayerController controller;

  const _VideoPlayerControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isPlaying = controller.value.isPlaying;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  if (isPlaying) {
                    await controller.pause();
                  } else {
                    await controller.play();
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                    if (!isPlaying)
                      Icon(
                        Icons.play_circle_fill_outlined,
                        size: 72,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            VideoProgressIndicator(controller, allowScrubbing: true),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                if (isPlaying) {
                  await controller.pause();
                } else {
                  await controller.play();
                }
              },
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(isPlaying ? l10n.pause : l10n.start),
            ),
          ],
        ),
      ),
    );
  }
}
