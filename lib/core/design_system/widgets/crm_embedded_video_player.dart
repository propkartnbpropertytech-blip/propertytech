import 'package:flutter/material.dart';
import 'crm_embedded_video_player_web.dart' if (dart.library.io) 'crm_embedded_video_player_mobile.dart';

class CRMEmbeddedVideoPlayer extends StatelessWidget {
  final String videoUrl;
  const CRMEmbeddedVideoPlayer({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return VideoPlayerPlatformImpl(videoUrl: videoUrl);
  }
}
