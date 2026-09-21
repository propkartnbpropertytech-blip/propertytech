import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/telemetry/audit_telemetry_service.dart';
import '../../../core/utils/file_downloader.dart';
import '../../properties/models/property_model.dart';
import '../utils/property_share_pdf.dart';

class PdfOptionSelectionDialog extends StatefulWidget {
  final List<PropertyModel> properties;
  final String? recipientPhone;
  final String? customMessage;

  const PdfOptionSelectionDialog({
    super.key,
    required this.properties,
    this.recipientPhone,
    this.customMessage,
  });

  static Future<bool?> show(
    BuildContext context, {
    required List<PropertyModel> properties,
    String? recipientPhone,
    String? customMessage,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => PdfOptionSelectionDialog(
        properties: properties,
        recipientPhone: recipientPhone,
        customMessage: customMessage,
      ),
    );
  }

  @override
  State<PdfOptionSelectionDialog> createState() => _PdfOptionSelectionDialogState();
}

class _PdfOptionSelectionDialogState extends State<PdfOptionSelectionDialog> {
  PdfTemplateStyle? _generatingStyle;

  @override
  void initState() {
    super.initState();
    PropertySharePdf.preloadImages(widget.properties);
  }

  Future<void> _handleOptionSelect(PdfTemplateStyle style) async {
    if (_generatingStyle != null) return;

    setState(() {
      _generatingStyle = style;
    });

    try {
      final bytes = await PropertySharePdf.build(
        widget.properties,
        templateStyle: style,
      );

      final fileName = widget.properties.length == 1
          ? PropertySharePdf.fileName(widget.properties.first)
          : 'Selected_Properties_Details.pdf';

      await FileDownloader.download(bytes, fileName);

      if (widget.properties.length == 1) {
        AuditTelemetryService.instance.trackPropertyShare(
          propertyId: widget.properties.first.id,
          channel: 'PDF Download (${style.name})',
          extra: {
            'property_code': widget.properties.first.propertyCode,
            'title': widget.properties.first.title,
            'filename': fileName,
            'template': style.name,
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.properties.length == 1
                  ? 'Property PDF generated & downloaded.'
                  : 'Selected properties PDF generated & downloaded.',
            ),
          ),
        );
      }

      // Automatically open WhatsApp non-fatally
      try {
        await _openWhatsApp();
      } catch (waError) {
        debugPrint('WhatsApp launch error (non-fatal): $waError');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Failed to generate PDF ($style): $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate PDF. Please try again.'),
            backgroundColor: CRMColors.danger,
          ),
        );
        setState(() {
          _generatingStyle = null;
        });
      }
    }
  }

  Future<void> _openWhatsApp() async {
    final phone = widget.recipientPhone ?? (widget.properties.length == 1 ? widget.properties.first.ownerMobile : null);
    final cleanPhone = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    String formattedPhone = cleanPhone;
    if (cleanPhone.length == 10) {
      formattedPhone = '91$cleanPhone';
    }

    final messageText = widget.customMessage ??
        (widget.properties.length == 1
            ? "Hello, please find property details for ${widget.properties.first.title} (${widget.properties.first.propertyCode})."
            : "Hello, please find property details for selected properties.");

    final text = Uri.encodeComponent(messageText);

    if (widget.properties.isNotEmpty) {
      AuditTelemetryService.instance.trackPropertyShare(
        propertyId: widget.properties.first.id,
        channel: 'WhatsApp PDF Share',
        recipientInfo: formattedPhone.isNotEmpty ? formattedPhone : null,
      );
    }

    final String waUrl = formattedPhone.isNotEmpty
        ? "https://wa.me/$formattedPhone?text=$text"
        : "https://wa.me/?text=$text";
    final waUri = Uri.parse(waUrl);

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('WhatsApp launch attempt failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CRMColors.primaryOf(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            color: CRMColors.primaryOf(context),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Select PDF Design",
                          style: CRMTypography.title.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CRMColors.textOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _generatingStyle != null ? null : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Choose a modern PDF layout style. The PDF will be downloaded and WhatsApp will open automatically.",
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: CRMSpacing.m),

              // Option 1
              _buildOptionCard(
                style: PdfTemplateStyle.option1,
                title: "Option 1",
                subtitle: "Modern & Clean PDF Layout",
                description: "Clean layout with top photo grid, teal accents & clear card sections.",
                badgeColor: const Color(0xFF0D9488),
                badgeIcon: Icons.auto_awesome,
              ),
              const SizedBox(height: 12),

              // Option 2
              _buildOptionCard(
                style: PdfTemplateStyle.option2,
                title: "Option 2",
                subtitle: "Executive Elegant PDF Layout",
                description: "Executive dual-column dossier with hero photo spread & navy accents.",
                badgeColor: const Color(0xFF1E3A8A),
                badgeIcon: Icons.business_center_rounded,
              ),

              const SizedBox(height: CRMSpacing.l),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _generatingStyle != null ? null : () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required PdfTemplateStyle style,
    required String title,
    required String subtitle,
    required String description,
    required Color badgeColor,
    required IconData badgeIcon,
  }) {
    final isGenerating = _generatingStyle == style;
    final isAnyGenerating = _generatingStyle != null;

    return InkWell(
      onTap: isAnyGenerating ? null : () => _handleOptionSelect(style),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isGenerating ? badgeColor : Colors.grey.shade300,
            width: isGenerating ? 2 : 1,
          ),
          color: isGenerating ? badgeColor.withOpacity(0.04) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(badgeIcon, color: badgeColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: CRMTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: CRMColors.textOf(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isGenerating)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: CRMColors.textSecondaryOf(context),
              ),
          ],
        ),
      ),
    );
  }
}
