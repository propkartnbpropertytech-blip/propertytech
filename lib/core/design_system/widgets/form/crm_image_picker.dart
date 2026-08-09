import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:propkart/core/api/dio_client.dart';
import 'package:propkart/core/api/cloudinary_uploader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

class CRMImagePicker extends StatefulWidget {
  final List<String> imageUrls;
  final Function(String url) onImageAdded;
  final Function(int index) onImageRemoved;
  final Function(int index, String url) onImageReplaced;
  final Function(List<String> urls)? onImagesReordered;
  final int maxImages;
  final String uploadEndpoint;

  const CRMImagePicker({
    super.key,
    required this.imageUrls,
    required this.onImageAdded,
    required this.onImageRemoved,
    required this.onImageReplaced,
    this.onImagesReordered,
    this.maxImages = 3,
    this.uploadEndpoint = '/properties/upload-media',
  });

  @override
  State<CRMImagePicker> createState() => _CRMImagePickerState();
}

class _CRMImagePickerState extends State<CRMImagePicker> {
  bool _isUploading = false;

  Future<void> _showSourceDialog(int index) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo (Camera)'),
              onTap: () {
                Navigator.pop(context);
                _pickImageSingle(index, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                if (index < widget.imageUrls.length) {
                  // If replacing, pick a single image
                  _pickImageSingle(index, ImageSource.gallery);
                } else {
                  // If adding new, allow multiple image selection
                  _pickImagesMultiple(ImageSource.gallery);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageSingle(int index, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      List<int> uploadBytes;
      String filename = pickedFile.name;

      if (kIsWeb) {
        uploadBytes = await pickedFile.readAsBytes();
        if (uploadBytes.length > 10 * 1024 * 1024) {
          throw Exception("Image size exceeds the 10 MB file limit.");
        }
      } else {
        final File file = File(pickedFile.path);
        final String targetPath = "${Directory.systemTemp.path}/compressed_img_${DateTime.now().millisecondsSinceEpoch}.jpg";
        
        XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 70,
          minWidth: 1000,
          minHeight: 1000,
        );

        File uploadFile = file;
        if (compressedFile != null) {
          uploadFile = File(compressedFile.path);
          filename = 'upload_image.jpg';
        }

        uploadBytes = await uploadFile.readAsBytes();
        if (uploadBytes.length > 10 * 1024 * 1024) {
          throw Exception("Compressed image exceeds the 10 MB file limit.");
        }
      }

      final publicUrl = await CloudinaryUploader.upload(
        bytes: uploadBytes,
        filename: filename,
        mimeType: 'image/jpeg',
        resourceType: 'image',
        fallbackEndpoint: widget.uploadEndpoint,
      );

      setState(() {
        if (index < widget.imageUrls.length) {
          widget.onImageReplaced(index, publicUrl);
        } else {
          widget.onImageAdded(publicUrl);
        }
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload image: $e"), backgroundColor: CRMColors.danger),
        );
      }
    }
  }

  Future<void> _pickImagesMultiple(ImageSource source) async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = [];
    
    if (source == ImageSource.gallery) {
      final results = await picker.pickMultiImage();
      if (results.isNotEmpty) {
        pickedFiles.addAll(results);
      }
    } else {
      final result = await picker.pickImage(source: source);
      if (result != null) {
        pickedFiles.add(result);
      }
    }
    
    if (pickedFiles.isEmpty) return;

    final remainingSlots = widget.maxImages - widget.imageUrls.length;
    if (remainingSlots <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Maximum limit of ${widget.maxImages} photos reached."),
            backgroundColor: CRMColors.danger,
          ),
        );
      }
      return;
    }

    final filesToUpload = pickedFiles.take(remainingSlots).toList();
    if (pickedFiles.length > remainingSlots) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Only uploading first $remainingSlots image(s). Limit is ${widget.maxImages}."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    setState(() {
      _isUploading = true;
    });

    try {
      for (final pickedFile in filesToUpload) {
        List<int> uploadBytes;
        String filename = pickedFile.name;

        if (kIsWeb) {
          uploadBytes = await pickedFile.readAsBytes();
          if (uploadBytes.length > 10 * 1024 * 1024) {
            throw Exception("Image size exceeds the 10 MB file limit.");
          }
        } else {
          final File file = File(pickedFile.path);
          final String targetPath = "${Directory.systemTemp.path}/compressed_img_${DateTime.now().millisecondsSinceEpoch}.jpg";
          
          XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            targetPath,
            quality: 70,
            minWidth: 1000,
            minHeight: 1000,
          );

          File uploadFile = file;
          if (compressedFile != null) {
            uploadFile = File(compressedFile.path);
            filename = 'upload_image.jpg';
          }

          uploadBytes = await uploadFile.readAsBytes();
          if (uploadBytes.length > 10 * 1024 * 1024) {
            throw Exception("Compressed image exceeds the 10 MB file limit.");
          }
        }

        final publicUrl = await CloudinaryUploader.upload(
          bytes: uploadBytes,
          filename: filename,
          mimeType: 'image/jpeg',
          resourceType: 'image',
          fallbackEndpoint: widget.uploadEndpoint,
        );
        
        if (mounted) {
          widget.onImageAdded(publicUrl);
        }
      }
      
      setState(() {
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload image: $e"), backgroundColor: CRMColors.danger),
        );
      }
    }
  }

  void _moveImage(int index, int direction) {
    if (widget.onImagesReordered == null) return;
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= widget.imageUrls.length) return;
    
    final List<String> list = List.from(widget.imageUrls);
    final temp = list[index];
    list[index] = list[newIndex];
    list[newIndex] = temp;
    
    widget.onImagesReordered!(list);
  }

  @override
  Widget build(BuildContext context) {
    final showUploadField = widget.imageUrls.length < widget.maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos / Attachments (${widget.imageUrls.length}/${widget.maxImages})',
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
            onTap: _isUploading ? null : () => _showSourceDialog(widget.imageUrls.length),
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
                      Icons.cloud_upload_outlined,
                      size: 32,
                      color: CRMColors.primaryOf(context),
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Text(
                      'Tap to Upload Photos',
                      style: CRMTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CRMColors.primaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Supports multiple image selection (Max 10)',
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
                'Maximum limit of ${widget.maxImages} photos reached',
                style: CRMTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: CRMColors.textSecondaryOf(context),
                ),
              ),
            ),
          ),
        ],

        if (_isUploading) ...[
          const SizedBox(height: CRMSpacing.s),
          Center(
            child: Text(
              'Uploading images... Please wait.',
              style: CRMTypography.caption.copyWith(color: CRMColors.primaryOf(context)),
            ),
          ),
        ],

        if (widget.imageUrls.isNotEmpty) ...[
          const SizedBox(height: CRMSpacing.m),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final crossAxisCount = isMobile ? 1 : (constraints.maxWidth > 900 ? 4 : 3);
              final itemSpacing = CRMSpacing.s;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.imageUrls.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: itemSpacing,
                  mainAxisSpacing: itemSpacing,
                  childAspectRatio: isMobile ? 16 / 10 : 4 / 3.5,
                ),
                itemBuilder: (context, index) {
                  final imageUrl = widget.imageUrls[index];
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
                                if (kIsWeb)
                                  Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    cacheWidth: 240,
                                    cacheHeight: 240,
                                    gaplessPlayback: true,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: CRMColors.backgroundOf(context),
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: CRMColors.textSecondaryOf(context),
                                      ),
                                    ),
                                  )
                                else
                                  CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 240,
                                    memCacheHeight: 240,
                                    fadeInDuration: Duration.zero,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: CRMColors.backgroundOf(context),
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: CRMColors.textSecondaryOf(context),
                                      ),
                                    ),
                                  ),
                                // Reorder Arrows stacked on top of the image preview
                                if (index > 0)
                                  Positioned(
                                    left: 8,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.black54,
                                        child: IconButton(
                                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 10),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _moveImage(index, -1),
                                          tooltip: 'Move Left',
                                        ),
                                      ),
                                    ),
                                  ),
                                if (index < widget.imageUrls.length - 1)
                                  Positioned(
                                    right: 8,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.black54,
                                        child: IconButton(
                                          icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _moveImage(index, 1),
                                          tooltip: 'Move Right',
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xs, vertical: CRMSpacing.xxs),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: CRMColors.borderOf(context), width: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Text(
                                  'Photo ${index + 1}',
                                  style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, size: 16, color: CRMColors.primaryOf(context)),
                                    onPressed: () => _showSourceDialog(index),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    tooltip: 'Replace Photo',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: CRMColors.danger),
                                    onPressed: () => widget.onImageRemoved(index),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    tooltip: 'Delete Photo',
                                  ),
                                ],
                              ),
                            ],
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

    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    ));

    final dashPath = Path();
    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final len = dashLength;
        if (distance + len > pathMetric.length) {
          dashPath.addPath(
            pathMetric.extractPath(distance, pathMetric.length),
            Offset.zero,
          );
        } else {
          dashPath.addPath(
            pathMetric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.radius != radius;
  }
}
