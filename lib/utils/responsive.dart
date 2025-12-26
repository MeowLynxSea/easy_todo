import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const double kWebDesktopMinWidth = 1024;
const double kWebDesktopMinShortestSide = 600;
const double kWebDesktopWideMinWidth = 1280;

bool isWebDesktop(BuildContext context) {
  if (!kIsWeb) return false;
  final size = MediaQuery.sizeOf(context);
  return size.width >= kWebDesktopMinWidth &&
      size.shortestSide >= kWebDesktopMinShortestSide;
}

bool isWebDesktopWide(BuildContext context) {
  if (!isWebDesktop(context)) return false;
  return MediaQuery.sizeOf(context).width >= kWebDesktopWideMinWidth;
}
