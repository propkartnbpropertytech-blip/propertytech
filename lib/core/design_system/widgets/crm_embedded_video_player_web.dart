import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class VideoPlayerPlatformImpl extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerPlatformImpl({super.key, required this.videoUrl});

  @override
  State<VideoPlayerPlatformImpl> createState() => _VideoPlayerPlatformImplState();
}

class _VideoPlayerPlatformImplState extends State<VideoPlayerPlatformImpl> {
  double _aspectRatio = 16 / 9; // Default aspect ratio
  late final String _viewId;
  late final html.VideoElement _videoElement;

  @override
  void initState() {
    super.initState();
    _viewId = 'video-player-${widget.videoUrl.hashCode}';

    _videoElement = html.VideoElement()
      ..src = widget.videoUrl
      ..autoplay = false
      ..controls = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..style.borderRadius = '8px'
      ..style.backgroundColor = 'transparent';

    _videoElement.onLoadedMetadata.listen((_) {
      if (mounted) {
        final w = _videoElement.videoWidth;
        final h = _videoElement.videoHeight;
        if (w > 0 && h > 0) {
          setState(() {
            _aspectRatio = w / h;
          });
        }
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int id) => _videoElement,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
