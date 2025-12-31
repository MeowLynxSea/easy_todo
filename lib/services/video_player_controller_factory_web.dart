import 'package:video_player/video_player.dart';

VideoPlayerController createVideoPlayerController(String filePathOrUrl) {
  return VideoPlayerController.networkUrl(Uri.parse(filePathOrUrl));
}
