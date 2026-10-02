import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'crm_network_image.dart';

class VideoPlayerPlatformImpl extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerPlatformImpl({super.key, required this.videoUrl});

  @override
  State<VideoPlayerPlatformImpl> createState() => _VideoPlayerPlatformImplState();
}

class _VideoPlayerPlatformImplState extends State<VideoPlayerPlatformImpl> {
  double _aspectRatio = 16 / 9;
  late final String _viewId;
  html.VideoElement? _videoElement;
  bool _isPlaying = false;

  String get _posterUrl {
    final url = widget.videoUrl.trim();
    if (url.contains('/video/upload/')) {
      return url.replaceAll(RegExp(r'\.(mp4|mov|webm|avi|mkv)$', caseSensitive: false), '.jpg');
    }
    return url;
  }

  void _startPlayback() {
    if (_isPlaying) return;

    _viewId = 'video-player-${widget.videoUrl.hashCode}-${DateTime.now().microsecondsSinceEpoch}';

    final element = html.VideoElement()
      ..src = widget.videoUrl
      ..autoplay = true
      ..controls = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..style.borderRadius = '8px'
      ..style.backgroundColor = 'transparent';

    element.onLoadedMetadata.listen((_) {
      if (mounted) {
        final w = element.videoWidth;
        final h = element.videoHeight;
        if (w > 0 && h > 0) {
          setState(() {
            _aspectRatio = w / h;
          });
        }
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int id) => element,
    );

    _videoElement = element;
    setState(() {
      _isPlaying = true;
    });
  }

  @override
  void dispose() {
    if (_videoElement != null) {
      try {
        _videoElement!.pause();
        _videoElement!.src = '';
        _videoElement!.remove();
      } catch (_) {}
      _videoElement = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPlaying) {
      return AspectRatio(
        aspectRatio: _aspectRatio,
        child: HtmlElementView(viewType: _viewId),
      );
    }

    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black87,
            child: CrmNetworkImage(
              url: _posterUrl,
              fit: BoxFit.contain,
              placeholder: (context) => const Center(
                child: Icon(Icons.videocam_rounded, size: 48, color: Colors.white24),
              ),
              error: (context) => const Center(
                child: Icon(Icons.videocam_rounded, size: 48, color: Colors.white24),
              ),
            ),
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.3),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _startPlayback,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
