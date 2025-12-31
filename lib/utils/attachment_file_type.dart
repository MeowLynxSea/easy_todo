enum AttachmentFileType { image, audio, video, pdf, text, markdown, other }

AttachmentFileType classifyAttachmentFileType({
  required String fileName,
  required String mimeType,
}) {
  final name = fileName.trim().toLowerCase();
  final mime = mimeType.trim().toLowerCase();

  if (mime.startsWith('image/')) return AttachmentFileType.image;
  if (mime.startsWith('audio/')) return AttachmentFileType.audio;
  if (mime.startsWith('video/')) return AttachmentFileType.video;
  if (mime == 'application/pdf') return AttachmentFileType.pdf;
  if (mime == 'text/plain') return AttachmentFileType.text;
  if (mime == 'text/markdown') return AttachmentFileType.markdown;

  if (name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.png') ||
      name.endsWith('.gif') ||
      name.endsWith('.webp') ||
      name.endsWith('.bmp') ||
      name.endsWith('.heic') ||
      name.endsWith('.heif')) {
    return AttachmentFileType.image;
  }

  if (name.endsWith('.mp3') ||
      name.endsWith('.m4a') ||
      name.endsWith('.aac') ||
      name.endsWith('.wav') ||
      name.endsWith('.flac') ||
      name.endsWith('.ogg') ||
      name.endsWith('.opus')) {
    return AttachmentFileType.audio;
  }

  if (name.endsWith('.mp4') ||
      name.endsWith('.mov') ||
      name.endsWith('.m4v') ||
      name.endsWith('.webm') ||
      name.endsWith('.mkv')) {
    return AttachmentFileType.video;
  }

  if (name.endsWith('.pdf')) return AttachmentFileType.pdf;

  if (name.endsWith('.md') || name.endsWith('.markdown')) {
    return AttachmentFileType.markdown;
  }

  if (name.endsWith('.txt') || name.endsWith('.log')) {
    return AttachmentFileType.text;
  }

  return AttachmentFileType.other;
}

bool isAttachmentPreviewSupported(AttachmentFileType fileType) {
  return switch (fileType) {
    AttachmentFileType.image ||
    AttachmentFileType.audio ||
    AttachmentFileType.video ||
    AttachmentFileType.pdf ||
    AttachmentFileType.text ||
    AttachmentFileType.markdown => true,
    AttachmentFileType.other => false,
  };
}

int? maxPreviewBytesForAttachmentType(AttachmentFileType fileType) {
  const mb = 1024 * 1024;
  return switch (fileType) {
    AttachmentFileType.audio => 20 * mb,
    AttachmentFileType.video => 50 * mb,
    AttachmentFileType.pdf => 25 * mb,
    AttachmentFileType.text => 2 * mb,
    AttachmentFileType.markdown => 2 * mb,
    AttachmentFileType.image || AttachmentFileType.other => null,
  };
}

String guessMimeTypeFromFileName(String fileName) {
  final name = fileName.trim().toLowerCase();

  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.gif')) return 'image/gif';
  if (name.endsWith('.webp')) return 'image/webp';
  if (name.endsWith('.bmp')) return 'image/bmp';
  if (name.endsWith('.heic')) return 'image/heic';
  if (name.endsWith('.heif')) return 'image/heif';

  if (name.endsWith('.mp3')) return 'audio/mpeg';
  if (name.endsWith('.m4a')) return 'audio/mp4';
  if (name.endsWith('.aac')) return 'audio/aac';
  if (name.endsWith('.wav')) return 'audio/wav';
  if (name.endsWith('.flac')) return 'audio/flac';
  if (name.endsWith('.ogg')) return 'audio/ogg';
  if (name.endsWith('.opus')) return 'audio/opus';

  if (name.endsWith('.mp4')) return 'video/mp4';
  if (name.endsWith('.mov')) return 'video/quicktime';
  if (name.endsWith('.m4v')) return 'video/x-m4v';
  if (name.endsWith('.webm')) return 'video/webm';
  if (name.endsWith('.mkv')) return 'video/x-matroska';

  if (name.endsWith('.pdf')) return 'application/pdf';

  if (name.endsWith('.md') || name.endsWith('.markdown')) {
    return 'text/markdown';
  }

  if (name.endsWith('.txt') || name.endsWith('.log')) return 'text/plain';

  return 'application/octet-stream';
}

String effectiveAttachmentMimeType({
  required String fileName,
  required String mimeType,
}) {
  final normalized = mimeType.trim().toLowerCase();
  if (normalized.isEmpty || normalized == 'application/octet-stream') {
    return guessMimeTypeFromFileName(fileName);
  }
  return normalized;
}
