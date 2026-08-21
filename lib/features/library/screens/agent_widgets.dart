import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import '../../../core/api/api_constants.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';

// ignore_for_file: depend_on_referenced_packages

class AgentImageUploadWidget extends StatefulWidget {
  final Function(String imageUrl) onImageUploaded;
  final String? initialImageUrl;
  const AgentImageUploadWidget({super.key, required this.onImageUploaded, this.initialImageUrl});
  @override
  State<AgentImageUploadWidget> createState() => _AgentImageUploadWidgetState();
}

class _AgentImageUploadWidgetState extends State<AgentImageUploadWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _imageUrl;

  @override
  void initState() { super.initState(); _imageUrl = widget.initialImageUrl; }

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.size > 5 * 1024 * 1024) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image must be less than 5MB.'), backgroundColor: CRMColors.danger));
        return;
      }
      setState(() { _isUploading = true; _uploadProgress = 0.0; });
      final List<int>? bytes = file.bytes ?? (kIsWeb ? null : await File(file.path!).readAsBytes());
      if (bytes == null || bytes.isEmpty) { if (mounted) setState(() => _isUploading = false); return; }
      for (int i = 1; i <= 4; i++) {
        await Future.delayed(const Duration(milliseconds: 80));
        if (!mounted) return;
        setState(() => _uploadProgress = i / 10.0);
      }
      final uploadBytes = Uint8List.fromList(bytes);
      final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      const folder = 'agent_profiles';
      final toSign = 'folder=$folder&timestamp=$timestamp${ApiConstants.cloudinaryApiSecret}';
      final signature = sha1.convert(utf8.encode(toSign)).toString();
      final ext = (file.extension ?? 'jpg').toLowerCase();
      final contentType = ext == 'png' ? MediaType('image', 'png') : MediaType('image', 'jpeg');
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(uploadBytes, filename: file.name, contentType: contentType),
        'api_key': ApiConstants.cloudinaryApiKey,
        'timestamp': timestamp,
        'signature': signature,
        'folder': folder,
      });
      final response = await Dio(BaseOptions(connectTimeout: const Duration(seconds: 60), receiveTimeout: const Duration(seconds: 60), sendTimeout: const Duration(seconds: 60)))
          .post('https://api.cloudinary.com/v1_1/${ApiConstants.cloudinaryCloudName}/image/upload', data: formData);
      final uploadedUrl = (response.data?['secure_url'] ?? '').toString();
      if (uploadedUrl.isEmpty || !uploadedUrl.contains('res.cloudinary.com')) throw Exception('Invalid Cloudinary response');
      if (!mounted) return;
      setState(() { _imageUrl = uploadedUrl; _isUploading = false; _uploadProgress = 1.0; });
      widget.onImageUploaded(uploadedUrl);
    } catch (e) {
      debugPrint('[AgentImageUpload] Error: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e'), backgroundColor: CRMColors.danger));
      }
    }
  }

  Widget _defaultIcon(BuildContext context) => Icon(Icons.person_rounded, size: 52, color: CRMColors.textMutedOf(context));

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Stack(alignment: Alignment.bottomRight, children: [
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUpload,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CRMColors.cardBgOf(context),
              border: Border.all(color: CRMColors.primaryOf(context).withOpacity(0.4), width: 2.5),
              boxShadow: [BoxShadow(color: CRMColors.primaryOf(context).withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            clipBehavior: Clip.antiAlias,
            child: _isUploading
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 36, height: 36, child: CircularProgressIndicator(value: _uploadProgress > 0 ? _uploadProgress : null, strokeWidth: 2.5, color: CRMColors.primaryOf(context)))])
                : _imageUrl != null && _imageUrl!.isNotEmpty
                    ? Image.network(_imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultIcon(context))
                    : _defaultIcon(context),
          ),
        ),
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUpload,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: CRMColors.primaryOf(context), shape: BoxShape.circle, border: Border.all(color: CRMColors.surfaceElevatedOf(context), width: 2)),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Text(_imageUrl != null && _imageUrl!.isNotEmpty ? 'Tap to change photo' : 'Upload Photo',
          style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
    ]);
  }
}

class AreaMultiSelectWidget extends StatefulWidget {
  final List<String> selectedAreas;
  final Function(List<String>) onChanged;
  const AreaMultiSelectWidget({super.key, required this.selectedAreas, required this.onChanged});

  static const List<String> kAllAreas = [
    'Bopal', 'Satellite', 'Maninagar', 'Vastrapur', 'Navrangpura',
    'Paldi', 'Ambawadi', 'Prahlad Nagar', 'Thaltej', 'Science City',
    'Chandkheda', 'Motera', 'Gota', 'Nikol', 'Naranpura',
    'Memnagar', 'Vejalpur', 'Jodhpur', 'Ellis Bridge', 'Sola',
    'Vastral', 'Odhav', 'Rakhial', 'Gomtipur', 'Naroda',
    'Ghatlodiya', 'Sarkhej', 'Lambha', 'Kathwada', 'Shela',
    'Bavla', 'Sanand', 'Dholka', 'Daskroi', 'Detroj',
  ];

  @override
  State<AreaMultiSelectWidget> createState() => _AreaMultiSelectWidgetState();
}

class _AreaMultiSelectWidgetState extends State<AreaMultiSelectWidget> {
  late List<String> _selected;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() { super.initState(); _selected = List.from(widget.selectedAreas); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final filtered = AreaMultiSelectWidget.kAllAreas.where((a) => a.toLowerCase().contains(_query.toLowerCase())).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Service Areas *', style: CRMTypography.label.copyWith(color: CRMColors.textSecondaryOf(context))),
      const SizedBox(height: CRMSpacing.xs),
      if (_selected.isNotEmpty) ...[
        Wrap(spacing: 6, runSpacing: 4, children: _selected.map((area) => Chip(
          label: Text(area, style: const TextStyle(fontSize: 12)),
          deleteIcon: const Icon(Icons.close_rounded, size: 14),
          onDeleted: () { setState(() => _selected.remove(area)); widget.onChanged(List.from(_selected)); },
          backgroundColor: CRMColors.primaryOf(context).withOpacity(0.12),
          labelStyle: TextStyle(color: CRMColors.primaryOf(context), fontWeight: FontWeight.w500),
          deleteIconColor: CRMColors.primaryOf(context),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
        )).toList()),
        const SizedBox(height: CRMSpacing.s),
      ],
      TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search & select areas...',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input), borderSide: BorderSide(color: CRMColors.borderOf(context))),
          suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded, size: 16), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); }) : null,
        ),
        onChanged: (val) => setState(() => _query = val),
      ),
      const SizedBox(height: CRMSpacing.xs),
      Container(
        constraints: const BoxConstraints(maxHeight: 160),
        decoration: BoxDecoration(border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)), borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
        child: filtered.isEmpty
            ? Padding(padding: const EdgeInsets.all(CRMSpacing.m), child: Text('No areas found', style: CRMTypography.caption.copyWith(color: CRMColors.textMutedOf(context))))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final area = filtered[i];
                  final isSelected = _selected.contains(area);
                  return InkWell(
                    onTap: () { setState(() { isSelected ? _selected.remove(area) : _selected.add(area); }); widget.onChanged(List.from(_selected)); },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(children: [
                        Icon(isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: isSelected ? CRMColors.primaryOf(context) : CRMColors.textMutedOf(context), size: 18),
                        const SizedBox(width: 10),
                        Text(area, style: TextStyle(fontSize: 13, color: isSelected ? CRMColors.primaryOf(context) : CRMColors.textOf(context), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                      ]),
                    ),
                  );
                },
              ),
      ),
      if (_selected.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 4), child: Text('${_selected.length} area${_selected.length > 1 ? 's' : ''} selected', style: CRMTypography.caption.copyWith(color: CRMColors.primaryOf(context), fontWeight: FontWeight.w600))),
    ]);
  }
}

String? extractDobFromOcrText(String text) {
  final patterns = [
    RegExp(r'(?:DOB|Date\s+of\s+Birth)\s*[:\-]?\s*(\d{2})[\/\-](\d{2})[\/\-](\d{4})', caseSensitive: false),
    RegExp(r'\b(\d{2})[\/\-](\d{2})[\/\-](\d{4})\b'),
    RegExp(r'\b(\d{4})[\/\-](\d{2})[\/\-](\d{2})\b'),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      try {
        final g1 = int.parse(match.group(1)!);
        final g2 = int.parse(match.group(2)!);
        final g3 = int.parse(match.group(3)!);
        if (g1 > 1900) return DateTime(g1, g2, g3).toIso8601String().split('T').first;
        return DateTime(g3, g2, g1).toIso8601String().split('T').first;
      } catch (_) {}
    }
  }
  return null;
}
