import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController createVideoPlayerController(String filePathOrUrl) {
  return VideoPlayerController.file(File(filePathOrUrl));
}
