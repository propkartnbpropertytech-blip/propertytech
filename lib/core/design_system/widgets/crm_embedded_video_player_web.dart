import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class VideoPlayerPlatformImpl extends StatelessWidget {
  final String videoUrl;
  const VideoPlayerPlatformImpl({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    final viewId = 'video-player-${videoUrl.hashCode}';
    
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) => html.VideoElement()
        ..src = videoUrl
        ..autoplay = false
        ..controls = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.borderRadius = '8px'
        ..style.objectFit = 'cover',
    );

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: HtmlElementView(viewType: viewId),
    );
  }
}
