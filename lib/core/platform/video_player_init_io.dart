import 'dart:io';
import 'package:video_player_win/video_player_win_plugin.dart';

void initWindowsVideoPlayerImpl() {
  if (Platform.isWindows) {
    WindowsVideoPlayer.registerWith();
  }
}
