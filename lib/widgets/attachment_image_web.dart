import 'package:flutter/material.dart';

class AttachmentImage extends StatelessWidget {
  final String filePath;
  final BoxFit fit;
  final double? width;
  final double? height;

  const AttachmentImage({
    super.key,
    required this.filePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x11000000),
      child: SizedBox(
        width: width,
        height: height,
        child: const Center(child: Icon(Icons.insert_drive_file_outlined)),
      ),
    );
  }
}
