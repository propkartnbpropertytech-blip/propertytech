import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPlatformImpl extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerPlatformImpl({super.key, required this.videoUrl});

  @override
  State<VideoPlayerPlatformImpl> createState() => _VideoPlayerPlatformImplState();
}

class _VideoPlayerPlatformImplState extends State<VideoPlayerPlatformImpl> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _showControls = true;
  Timer? _controlsTimer;
  int _speedIndex = 0;
  final List<double> _speeds = [1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _resetControlsTimer();
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _errorMessage = error.toString();
          });
        }
      });
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (_controller.value.isPlaying) {
      _controlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _resetControlsTimer();
    }
  }

  void _rewind10Seconds() {
    final currentPosition = _controller.value.position;
    final targetPosition = currentPosition - const Duration(seconds: 10);
    _controller.seekTo(targetPosition < Duration.zero ? Duration.zero : targetPosition);
    _resetControlsTimer();
  }

  void _forward10Seconds() {
    final currentPosition = _controller.value.position;
    final maxDuration = _controller.value.duration;
    final targetPosition = currentPosition + const Duration(seconds: 10);
    _controller.seekTo(targetPosition > maxDuration ? maxDuration : targetPosition);
    _resetControlsTimer();
  }

  void _toggleSpeed() {
    setState(() {
      _speedIndex = (_speedIndex + 1) % _speeds.length;
      final newSpeed = _speeds[_speedIndex];
      _controller.setPlaybackSpeed(newSpeed);
      _resetControlsTimer();
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildControlsOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black45, // Translucent dark overlay
        child: Stack(
          children: [
            // Center controls: Rewind 10s, Play/Pause, Forward 10s
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Rewind 10s
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 36),
                    onPressed: _rewind10Seconds,
                  ),
                  // Play / Pause
                  IconButton(
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                          _controlsTimer?.cancel(); // keep controls visible when paused
                        } else {
                          _controller.play();
                          _resetControlsTimer();
                        }
                      });
                    },
                  ),
                  // Forward 10s
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 36),
                    onPressed: _forward10Seconds,
                  ),
                ],
              ),
            ),

            // Bottom controls: duration, progress bar, speed control
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress indicator
                    VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.redAccent,
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Row with duration text and speed button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Time Text: e.g. "00:12 / 01:30"
                        ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: _controller,
                          builder: (context, value, child) {
                            final current = _formatDuration(value.position);
                            final total = _formatDuration(value.duration);
                            return Text(
                              '$current / $total',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),

                        // Speed indicator / button
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            backgroundColor: Colors.white12,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          onPressed: _toggleSpeed,
                          child: Text(
                            '${_speeds[_speedIndex]}x',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Error playing video: $_errorMessage',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: GestureDetector(
        onTap: _toggleControls,
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              if (_showControls) _buildControlsOverlay(context),
            ],
          ),
        ),
      ),
    );
  }
}
