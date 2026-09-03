import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:propkart/core/api/dio_client.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

class CRMDocumentPicker extends StatefulWidget {
  final String labelText;
  final List<String> allowedExtensions;
  final Function(String url, String fileName) onFileSelected;
  final VoidCallback? onFileRemoved;
  final String? initialFileName;
  final String uploadEndpoint;

  const CRMDocumentPicker({
    super.key,
    required this.labelText,
    required this.onFileSelected,
    this.onFileRemoved,
    this.allowedExtensions = const ['pdf', 'doc', 'docx', 'xlsx', 'xls', 'csv'],
    this.initialFileName,
    this.uploadEndpoint = '/properties/upload-media',
  });

  @override
  State<CRMDocumentPicker> createState() => _CRMDocumentPickerState();
}

class _CRMDocumentPickerState extends State<CRMDocumentPicker> {
  bool _isUploading = false;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _selectedFileName = widget.initialFileName;
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (!kIsWeb && file.path == null) return;

    setState(() {
      _isUploading = true;
      _selectedFileName = file.name;
    });

    try {
      MultipartFile multipartFile;

      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception("Could not read file data.");
        }
        if (file.size > 10 * 1024 * 1024) {
          throw Exception("Document size exceeds the 10 MB limit.");
        }
        multipartFile = MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        );
      } else {
        final File uploadFile = File(file.path!);
        final int size = await uploadFile.length();
        if (size > 10 * 1024 * 1024) {
          throw Exception("Document size exceeds the 10 MB limit.");
        }
        multipartFile = await MultipartFile.fromFile(uploadFile.path, filename: file.name);
      }

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      final response = await DioClient.dio.post(
        widget.uploadEndpoint,
        data: formData,
      );

      final publicUrl = response.data['data']['url'];

      setState(() {
        _isUploading = false;
      });
      
      widget.onFileSelected(publicUrl, file.name);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _selectedFileName = widget.initialFileName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload document: $e"), backgroundColor: CRMColors.danger),
      );
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFileName = null;
    });
    if (widget.onFileRemoved != null) widget.onFileRemoved!();
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _selectedFileName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: CRMSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            border: Border.all(color: CRMColors.borderOf(context)),
          ),
          child: Row(
            children: [
              Icon(
                hasFile ? Icons.insert_drive_file_rounded : Icons.cloud_upload_outlined,
                color: hasFile ? CRMColors.primaryOf(context) : CRMColors.textSecondaryOf(context),
                size: 24,
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasFile ? _selectedFileName! : 'No document selected',
                      style: CRMTypography.body.copyWith(
                        color: hasFile ? CRMColors.textOf(context) : CRMColors.textMutedOf(context),
                        fontWeight: hasFile ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_isUploading) ...[
                      const SizedBox(height: CRMSpacing.xs),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              if (hasFile && !_isUploading)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: CRMColors.danger),
                  onPressed: _removeFile,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                )
              else if (!_isUploading)
                TextButton(
                  onPressed: _pickDocument,
                  child: const Text('Browse'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
