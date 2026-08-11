import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';

/// Breadcrumb navigation item
class LibraryBreadcrumb extends StatelessWidget {
  final String currentPageName;
  final VoidCallback? onBack;

  const LibraryBreadcrumb({
    super.key,
    required this.currentPageName,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CRMSpacing.m),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/dashboard'),
              child: Text(
                'CRM',
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 14,
            color: CRMColors.textMutedOf(context),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/library'),
              child: Text(
                'Library',
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 14,
            color: CRMColors.textMutedOf(context),
          ),
          Text(
            currentPageName,
            style: CRMTypography.captionBold.copyWith(
              color: CRMColors.primaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simulated Drag and Drop File Upload Zone
class DragDropUploadZone extends StatefulWidget {
  final Function(String fileName, String extension, String size, String fileUrl) onFileSelected;
  final Function(String detectedName)? onOcrDetected;
  final String? initialFileName;
  final String? initialFileSize;

  const DragDropUploadZone({
    super.key,
    required this.onFileSelected,
    this.onOcrDetected,
    this.initialFileName,
    this.initialFileSize,
  });

  @override
  State<DragDropUploadZone> createState() => _DragDropUploadZoneState();
}

class _DragDropUploadZoneState extends State<DragDropUploadZone> {
  bool _isHovering = false;
  bool _isSimulatingUpload = false;
  bool _isAnalyzingOcr = false;
  double _uploadProgress = 0.0;
  String? _fileName;
  String? _fileSize;

  @override
  void initState() {
    super.initState();
    _fileName = widget.initialFileName;
    _fileSize = widget.initialFileSize;
  }

  Future<void> _runOcrSpaceApi(PlatformFile file) async {
    setState(() {
      _isAnalyzingOcr = true;
    });

    try {
      final dio = Dio();
      final formData = FormData();
      formData.fields.add(const MapEntry('apikey', 'K84667566288957'));
      formData.fields.add(const MapEntry('language', 'eng'));
      formData.fields.add(const MapEntry('isOverlayRequired', 'false'));

      if (kIsWeb) {
        if (file.bytes != null) {
          formData.files.add(MapEntry(
            'file',
            MultipartFile.fromBytes(file.bytes!, filename: file.name),
          ));
        } else {
          debugPrint("[OCR] No file bytes available on web");
          setState(() {
            _isAnalyzingOcr = false;
          });
          return;
        }
      } else {
        if (file.path != null) {
          formData.files.add(MapEntry(
            'file',
            await MultipartFile.fromFile(file.path!, filename: file.name),
          ));
        } else {
          debugPrint("[OCR] No file path available on mobile/desktop");
          setState(() {
            _isAnalyzingOcr = false;
          });
          return;
        }
      }

      debugPrint("[OCR] Sending request to OCR.space API...");
      final response = await dio.post(
        'https://api.ocr.space/parse/image',
        data: formData,
      );

      debugPrint("[OCR] Response status: ${response.statusCode}");
      if (response.statusCode == 200 && response.data != null) {
        final results = response.data['ParsedResults'];
        if (results != null && results is List && results.isNotEmpty) {
          final parsedText = results[0]['ParsedText'] as String?;
          if (parsedText != null && parsedText.isNotEmpty) {
            debugPrint("[OCR] Parsed Text: $parsedText");
            final detectedName = _extractNameFromOcrText(parsedText);
            if (detectedName != null && detectedName.isNotEmpty) {
              debugPrint("[OCR] Detected Name: $detectedName");
              if (widget.onOcrDetected != null) {
                widget.onOcrDetected!(detectedName);
              }
            } else {
              debugPrint("[OCR] Could not extract a name from OCR text");
            }
          }
        }
      }
    } catch (e) {
      debugPrint("[OCR] Failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzingOcr = false;
        });
      }
    }
  }

  String? _extractNameFromOcrText(String text) {
    final lines = text.split('\n').map((l) => l.trim()).toList();

    // 1. Check for "Name:" or "Name" patterns
    final nameRegex = RegExp(r'(?:Name|NAME)\s*[:\-\s]\s*([A-Za-z\s]+)', caseSensitive: false);
    for (final line in lines) {
      final match = nameRegex.firstMatch(line);
      if (match != null) {
        final extracted = match.group(1)?.trim();
        if (extracted != null && extracted.length > 2) {
          return _cleanName(extracted);
        }
      }
    }

    // 2. Aadhaar pattern: name is often the line before "DOB" or "Year of Birth" or "Gender"
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (line.contains('dob') || line.contains('date of birth') || line.contains('yob') || line.contains('year of birth')) {
        if (i > 0) {
          final potentialName = lines[i - 1].trim();
          if (potentialName.length > 2 && RegExp(r'^[A-Za-z\s]+$').hasMatch(potentialName)) {
            return _cleanName(potentialName);
          }
        }
      }
    }

    // 3. Fallback: find the first line that looks like a name (2-3 words, only alphabetic)
    for (final line in lines) {
      final words = line.split(RegExp(r'\s+'));
      if (words.length >= 2 && words.length <= 4) {
        if (RegExp(r'^[A-Za-z\s]+$').hasMatch(line)) {
          final lower = line.toLowerCase();
          if (!lower.contains('government') &&
              !lower.contains('india') &&
              !lower.contains('unique') &&
              !lower.contains('identity') &&
              !lower.contains('address') &&
              !lower.contains('authority')) {
            return _cleanName(line);
          }
        }
      }
    }
    return null;
  }

  String _cleanName(String name) {
    return name.replaceAll(RegExp(r'[^A-Za-z\s]'), '').trim();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final name = file.name;
        final ext = (file.extension ?? name.split('.').last).toLowerCase();

        if (ext != 'pdf') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Strict Warning: Only PDF documents are allowed to be uploaded!'),
                backgroundColor: CRMColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        final sizeBytes = file.size;
        // Enforce max size 10MB (matches UI copy)
        if (sizeBytes > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Strict Warning: File size exceeds the 10MB limit!'),
                backgroundColor: CRMColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        final double sizeMB = sizeBytes / (1024 * 1024);
        final sizeStr = sizeMB > 0.1 ? '${sizeMB.toStringAsFixed(1)} MB' : '${(sizeBytes / 1024).toStringAsFixed(0)} KB';

        setState(() {
          _isSimulatingUpload = true;
          _uploadProgress = 0.0;
          _fileName = name;
          _fileSize = sizeStr;
        });

        // Simulate a smooth modern upload progression while uploading
        for (int i = 0; i <= 4; i++) {
          await Future.delayed(const Duration(milliseconds: 80));
          if (!mounted) return;
          setState(() {
            _uploadProgress = i / 10.0;
          });
        }

        // Extract bytes for Cloudinary upload
        final List<int>? bytes = file.bytes ?? (kIsWeb ? null : await File(file.path!).readAsBytes());
        String uploadedUrl = '';
        if (bytes == null || bytes.isEmpty) {
          if (mounted) {
            setState(() {
              _isSimulatingUpload = false;
              _fileName = null;
              _fileSize = null;
              _uploadProgress = 0.0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not read file bytes. Please try again.'),
                backgroundColor: CRMColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        try {
          // CLOUDINARY_ONLY_V4 — upload straight to ujn8lj3r/library_docs (never Supabase Storage)
          debugPrint("[CLOUDINARY_ONLY_V4] Uploading $name (${bytes.length} bytes) → library_docs");
          final uploadBytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

          final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          const folder = 'library_docs';
          final String toSign =
              'folder=$folder&timestamp=$timestamp${ApiConstants.cloudinaryApiSecret}';
          final String signature = sha1.convert(utf8.encode(toSign)).toString();

          final formData = FormData.fromMap({
            'file': MultipartFile.fromBytes(
              uploadBytes,
              filename: name,
              contentType: MediaType('application', 'pdf'),
            ),
            'api_key': ApiConstants.cloudinaryApiKey,
            'timestamp': timestamp,
            'signature': signature,
            'folder': folder,
          });

          final cloudResponse = await Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 60),
              sendTimeout: const Duration(seconds: 60),
            ),
          ).post(
            'https://api.cloudinary.com/v1_1/${ApiConstants.cloudinaryCloudName}/image/upload',
            data: formData,
          );

          uploadedUrl = (cloudResponse.data?['secure_url'] ?? '').toString();

          if (uploadedUrl.isEmpty ||
              !uploadedUrl.contains('res.cloudinary.com') ||
              !uploadedUrl.contains(ApiConstants.cloudinaryCloudName) ||
              uploadedUrl.contains('supabase.co') ||
              uploadedUrl.contains('storage/v1')) {
            throw Exception('Cloudinary-only required. Got: $uploadedUrl');
          }

          if (!mounted) return;
          setState(() {
            _uploadProgress = 1.0;
            _isSimulatingUpload = false;
          });
          debugPrint("[CLOUDINARY_ONLY_V4] OK: $uploadedUrl");
          widget.onFileSelected(name, ext, sizeStr, uploadedUrl);
        } catch (uploadError) {
          debugPrint("[CLOUDINARY_ONLY_V4] FAILED: $uploadError");
          if (!mounted) return;
          setState(() {
            _isSimulatingUpload = false;
            _fileName = null;
            _fileSize = null;
            _uploadProgress = 0.0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cloudinary upload failed: $uploadError'),
              backgroundColor: CRMColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // Run OCR auto-detection if it is an image or PDF
        if (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'pdf') {
          await _runOcrSpaceApi(file);
        }
      }
    } catch (e) {
      debugPrint("File picking failed: $e");
    }
  }

  void _removeFile() {
    setState(() {
      _fileName = null;
      _fileSize = null;
      _uploadProgress = 0.0;
      _isAnalyzingOcr = false;
    });
    widget.onFileSelected('', '', '', '');
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _fileName != null && _fileName!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document File *',
          style: CRMTypography.label.copyWith(color: CRMColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: CRMSpacing.xs),
        MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _isSimulatingUpload || _isAnalyzingOcr ? null : (hasFile ? null : _pickFile),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(CRMSpacing.xl),
              decoration: BoxDecoration(
                color: _isHovering
                    ? CRMColors.primaryOf(context).withOpacity(0.04)
                    : CRMColors.cardBgOf(context),
                borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                border: Border.all(
                  color: hasFile
                      ? CRMColors.primaryOf(context).withOpacity(0.5)
                      : (_isHovering ? CRMColors.primaryOf(context) : CRMColors.borderOf(context)),
                  width: _isHovering || hasFile ? 1.5 : 1.0,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSimulatingUpload) ...[
                    Icon(Icons.cloud_upload_rounded, color: CRMColors.primaryOf(context), size: 40),
                    const SizedBox(height: CRMSpacing.m),
                    Text(
                      'Uploading $_fileName...',
                      style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: CRMColors.borderOf(context),
                        valueColor: AlwaysStoppedAnimation<Color>(CRMColors.primaryOf(context)),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Text(
                      '${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                  ] else if (_isAnalyzingOcr) ...[
                    Icon(Icons.document_scanner_rounded, color: CRMColors.primaryOf(context), size: 40),
                    const SizedBox(height: CRMSpacing.m),
                    Text(
                      'Auto-detecting agent name via OCR...',
                      style: CRMTypography.bodyMedium.copyWith(
                        color: CRMColors.textOf(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    const SizedBox(
                      width: 150,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                      ),
                    ),
                  ] else if (hasFile) ...[
                    Row(
                      children: [
                        FileIconHelper.getIconForExtension(_fileName!.split('.').last, size: 36),
                        const SizedBox(width: CRMSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fileName!,
                                style: CRMTypography.bodyMedium.copyWith(
                                  color: CRMColors.textOf(context),
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _fileSize ?? 'Unknown size',
                                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: CRMColors.danger),
                          onPressed: _removeFile,
                          tooltip: 'Remove document',
                        ),
                      ],
                    ),
                  ] else ...[
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: _isHovering ? CRMColors.primaryOf(context) : CRMColors.textMutedOf(context),
                      size: 44,
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    Text(
                      'Drag & drop document here or click to browse',
                      style: CRMTypography.bodyMedium.copyWith(
                        color: CRMColors.textOf(context),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: CRMSpacing.xxs),
                    Text(
                      'Supports PDF only (Max 10MB)',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Image upload zone for Service Agent profile photo (Round / Circular avatar UI with auto-compression < 850KB).
class AgentImageUploadZone extends StatefulWidget {
  final Function(String imageUrl) onImageUploaded;
  final String? initialImageUrl;

  const AgentImageUploadZone({
    super.key,
    required this.onImageUploaded,
    this.initialImageUrl,
  });

  @override
  State<AgentImageUploadZone> createState() => _AgentImageUploadZoneState();
}

class _AgentImageUploadZoneState extends State<AgentImageUploadZone> {
  bool _isHovering = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _imageUrl;
  String _uploadStatusText = 'Uploading...';

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl;
  }

  Future<Uint8List> _compressToUnder850KB(Uint8List inputBytes, String ext) async {
    const int maxAllowedBytes = 850 * 1024; // 870,400 bytes

    if (inputBytes.length <= maxAllowedBytes) {
      return inputBytes;
    }

    // 1. Try FlutterImageCompress on non-web
    if (!kIsWeb) {
      try {
        int quality = 80;
        int minDimension = 1200;
        Uint8List current = inputBytes;

        while (current.length > maxAllowedBytes && quality >= 20) {
          final compressed = await FlutterImageCompress.compressWithList(
            inputBytes,
            quality: quality,
            minWidth: minDimension,
            minHeight: minDimension,
            format: ext == 'png' ? CompressFormat.png : CompressFormat.jpeg,
          );
          if (compressed.isNotEmpty) {
            current = compressed;
          }
          quality -= 15;
          minDimension = (minDimension * 0.85).round();
        }

        if (current.length <= maxAllowedBytes) {
          return current;
        }
      } catch (e) {
        debugPrint('[COMPRESS] FlutterImageCompress fallback: $e');
      }
    }

    // 2. Fallback via ui.instantiateImageCodec (works on Web, Desktop, Mobile)
    try {
      double scale = 0.8;
      Uint8List current = inputBytes;

      while (current.length > maxAllowedBytes && scale >= 0.15) {
        final ui.Codec codec = await ui.instantiateImageCodec(inputBytes);
        final ui.FrameInfo frame = await codec.getNextFrame();
        final int targetW = (frame.image.width * scale).round();
        final int targetH = (frame.image.height * scale).round();

        final ui.Codec scaledCodec = await ui.instantiateImageCodec(
          inputBytes,
          targetWidth: targetW > 40 ? targetW : 40,
          targetHeight: targetH > 40 ? targetH : 40,
        );
        final ui.FrameInfo scaledFrame = await scaledCodec.getNextFrame();
        final ByteData? byteData = await scaledFrame.image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          current = byteData.buffer.asUint8List();
        }
        scale -= 0.15;
      }
      return current;
    } catch (e) {
      debugPrint('[COMPRESS] Codec downscale error: $e');
      return inputBytes;
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final ext = (file.extension ?? 'jpg').toLowerCase();

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.1;
        _uploadStatusText = 'Reading image...';
      });

      final List<int>? rawBytes =
          file.bytes ?? (kIsWeb ? null : await File(file.path!).readAsBytes());
      if (rawBytes == null || rawBytes.isEmpty) {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read image file. Please try again.'),
              backgroundColor: CRMColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      Uint8List uploadBytes = rawBytes is Uint8List ? rawBytes : Uint8List.fromList(rawBytes);

      // Auto compress to under 850 KB if larger
      if (uploadBytes.length > 850 * 1024) {
        if (mounted) {
          setState(() {
            _uploadStatusText = 'Compressing image under 850 KB...';
            _uploadProgress = 0.3;
          });
        }
        uploadBytes = await _compressToUnder850KB(uploadBytes, ext);
      }

      if (mounted) {
        setState(() {
          _uploadStatusText = 'Uploading to Cloudinary...';
          _uploadProgress = 0.6;
        });
      }

      try {
        final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        const folder = 'agent_images';
        final String toSign =
            'folder=$folder&timestamp=$timestamp${ApiConstants.cloudinaryApiSecret}';
        final String signature = sha1.convert(utf8.encode(toSign)).toString();

        final contentType = ext == 'png'
            ? MediaType('image', 'png')
            : ext == 'webp'
                ? MediaType('image', 'webp')
                : MediaType('image', 'jpeg');

        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            uploadBytes,
            filename: file.name,
            contentType: contentType,
          ),
          'api_key': ApiConstants.cloudinaryApiKey,
          'timestamp': timestamp,
          'signature': signature,
          'folder': folder,
        });

        final cloudResponse = await Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
          ),
        ).post(
          'https://api.cloudinary.com/v1_1/${ApiConstants.cloudinaryCloudName}/image/upload',
          data: formData,
        );

        final uploadedUrl =
            (cloudResponse.data?['secure_url'] ?? '').toString();

        if (uploadedUrl.isEmpty || !uploadedUrl.contains('res.cloudinary.com')) {
          throw Exception('Invalid Cloudinary response: $uploadedUrl');
        }

        if (!mounted) return;
        setState(() {
          _uploadProgress = 1.0;
          _isUploading = false;
          _imageUrl = uploadedUrl;
        });
        widget.onImageUploaded(uploadedUrl);
      } catch (uploadError) {
        debugPrint('[AGENT_IMAGE_UPLOAD] FAILED: $uploadError');
        if (!mounted) return;
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: $uploadError'),
            backgroundColor: CRMColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Image picking failed: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
      _uploadProgress = 0.0;
    });
    widget.onImageUploaded('');
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imageUrl != null && _imageUrl!.isNotEmpty;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Service Agent Profile Photo',
            style: CRMTypography.label.copyWith(
              color: CRMColors.textSecondaryOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CRMSpacing.s),
          MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular Outer Container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isHovering
                          ? CRMColors.primaryOf(context).withOpacity(0.08)
                          : CRMColors.cardBgOf(context),
                      border: Border.all(
                        color: _isHovering || hasImage
                            ? CRMColors.primaryOf(context)
                            : CRMColors.borderOf(context).withOpacity(0.8),
                        width: _isHovering || hasImage ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CRMColors.primaryOf(context).withOpacity(_isHovering ? 0.15 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isUploading
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              value: _uploadProgress > 0 ? _uploadProgress : null,
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                CRMColors.primaryOf(context),
                              ),
                            ),
                          )
                        : (hasImage
                            ? ClipOval(
                                child: Image.network(
                                  _imageUrl!,
                                  width: 104,
                                  height: 104,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: CRMColors.primaryOf(context).withOpacity(0.1),
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 48,
                                      color: CRMColors.primaryOf(context),
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_rounded,
                                    color: _isHovering
                                        ? CRMColors.primaryOf(context)
                                        : CRMColors.primaryOf(context).withOpacity(0.7),
                                    size: 30,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add Photo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: CRMColors.primaryOf(context),
                                    ),
                                  ),
                                ],
                              )),
                  ),

                  // Camera Edit Badge / Remove Badge at Bottom Right
                  if (hasImage && !_isUploading)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: _removeImage,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CRMColors.danger,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else if (!hasImage && !_isUploading)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CRMColors.primaryOf(context),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: CRMSpacing.xs),
          Text(
            _isUploading
                ? _uploadStatusText
                : (hasImage
                    ? 'Tap photo to change'
                    : 'JPG, PNG, WebP • Auto-compressed < 850 KB'),
            style: CRMTypography.caption.copyWith(
              color: CRMColors.textMutedOf(context),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


class FileIconHelper {
  static Widget getIconForExtension(String extension, {double size = 20}) {
    final ext = extension.toLowerCase().trim();
    IconData icon;
    Color color;

    if (ext == 'pdf') {
      icon = Icons.picture_as_pdf_rounded;
      color = const Color(0xFFEF4444); // red
    } else if (ext == 'doc' || ext == 'docx') {
      icon = Icons.description_rounded;
      color = const Color(0xFF3B82F6); // blue
    } else if (ext == 'xls' || ext == 'xlsx' || ext == 'csv') {
      icon = Icons.table_chart_rounded;
      color = const Color(0xFF10B981); // green
    } else if (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'gif' || ext == 'webp') {
      icon = Icons.image_rounded;
      color = const Color(0xFFF59E0B); // amber/orange
    } else if (ext == 'mp4' || ext == 'avi' || ext == 'mov' || ext == 'mkv') {
      icon = Icons.video_library_rounded;
      color = const Color(0xFF8B5CF6); // purple
    } else {
      icon = Icons.insert_drive_file_rounded;
      color = const Color(0xFF6B7280); // gray
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );
  }
}

/// Simulated document exporter loader
class DocumentExportHelper {
  static Future<void> triggerExport(BuildContext context, String exportFormat) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(CRMSpacing.xl),
            decoration: BoxDecoration(
              color: CRMColors.surfaceElevatedOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.l),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: CRMColors.primaryOf(context)),
                const SizedBox(height: CRMSpacing.m),
                Text(
                  'Generating $exportFormat Report...',
                  style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)),
                ),
                const SizedBox(height: CRMSpacing.xxs),
                Text(
                  'Preparing metadata columns...',
                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Simulate file generation
    await Future.delayed(const Duration(milliseconds: 1500));
    if (context.mounted) {
      Navigator.of(context).pop(); // dismiss loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('Successfully exported document index as $exportFormat!'),
            ],
          ),
          backgroundColor: CRMColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
