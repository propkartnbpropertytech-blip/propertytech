import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:propkart/core/api/dio_client.dart';
import 'package:propkart/core/api/cloudinary_uploader.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

class CRMVideoPicker extends StatefulWidget {
  final List<String> videoUrls;
  final Function(String url) onVideoAdded;
  final Function(int index) onVideoRemoved;
  final int maxVideos;
  final String uploadEndpoint;

  const CRMVideoPicker({
    super.key,
    required this.videoUrls,
    required this.onVideoAdded,
    required this.onVideoRemoved,
    this.maxVideos = 3,
    this.uploadEndpoint = '/properties/upload-media',
  });

  @override
  State<CRMVideoPicker> createState() => _CRMVideoPickerState();
}

class _CRMVideoPickerState extends State<CRMVideoPicker> {
  bool _isUploading = false;
  String? _uploadError;

  Future<void> _showSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.videocam_rounded),
              title: const Text('Record Video (Camera)'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _lookupMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'ogg':
        return 'video/ogg';
      case 'mkv':
        return 'video/x-matroska';
      default:
        return 'video/mp4';
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 5),
    );
    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      List<int> uploadBytes;
      final mimeType = _lookupMimeType(pickedFile.name);

      if (kIsWeb) {
        uploadBytes = await pickedFile.readAsBytes();
        if (uploadBytes.length > 100 * 1024 * 1024) {
          throw Exception("Video size exceeds the 100 MB limit.");
        }
      } else {
        final file = File(pickedFile.path);
        final length = await file.length();
        if (length > 100 * 1024 * 1024) {
          throw Exception("Video size exceeds the 100 MB limit.");
        }
        uploadBytes = await file.readAsBytes();
      }

      final url = await CloudinaryUploader.upload(
        bytes: uploadBytes,
        filename: pickedFile.name,
        mimeType: mimeType,
        resourceType: 'video',
        fallbackEndpoint: widget.uploadEndpoint,
      );

      widget.onVideoAdded(url);
    } catch (e) {
      setState(() {
        _uploadError = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showUploadField = widget.videoUrls.length < widget.maxVideos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Property Videos (${widget.videoUrls.length}/${widget.maxVideos})',
              style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
            ),
            if (_isUploading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: CRMSpacing.s),
        
        if (showUploadField) ...[
          InkWell(
            onTap: _isUploading ? null : _showSourceDialog,
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            child: CustomPaint(
              painter: DashedBorderPainter(
                color: CRMColors.primaryOf(context).withOpacity(0.4),
                radius: CRMBorderRadius.s,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: CRMSpacing.l),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_call_rounded,
                      size: 36,
                      color: CRMColors.primaryOf(context),
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Text(
                      'Tap to Upload Video',
                      style: CRMTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CRMColors.primaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Supports MP4, WebM, MOV (Max 50 MB)',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: CRMSpacing.s + 2),
            decoration: BoxDecoration(
              color: CRMColors.backgroundOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              border: Border.all(color: CRMColors.borderOf(context)),
            ),
            child: Center(
              child: Text(
                'Maximum limit of ${widget.maxVideos} videos reached',
                style: CRMTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: CRMColors.textSecondaryOf(context),
                ),
              ),
            ),
          ),
        ],

        if (_uploadError != null) ...[
          const SizedBox(height: CRMSpacing.s),
          Text(
            _uploadError!,
            style: CRMTypography.caption.copyWith(color: Colors.redAccent),
          ),
        ],

        if (widget.videoUrls.isNotEmpty) ...[
          const SizedBox(height: CRMSpacing.m),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final crossAxisCount = isMobile ? 1 : (constraints.maxWidth > 900 ? 3 : 2);
              final itemSpacing = CRMSpacing.s;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.videoUrls.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: itemSpacing,
                  mainAxisSpacing: itemSpacing,
                  childAspectRatio: isMobile ? 16 / 9 : 4 / 3,
                ),
                itemBuilder: (context, index) {
                  final videoUrl = widget.videoUrls[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: CRMColors.cardBgOf(context),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      border: Border.all(color: CRMColors.borderOf(context), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(CRMBorderRadius.s - 1)),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  color: Colors.black87,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.play_circle_fill_rounded,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Video Attachment',
                                          style: TextStyle(color: Colors.white70, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 14),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => widget.onVideoRemoved(index),
                                      tooltip: 'Remove Video',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(CRMSpacing.s),
                          child: Text(
                            'Video #${index + 1}',
                            style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.radius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final dashPath = Path();
    double distance = 0.0;

    for (final PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  Widget? get child => null;

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.radius != radius;
  }
}
