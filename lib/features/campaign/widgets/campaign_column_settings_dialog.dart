import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/app_status_snackbar.dart';
import '../../integration/services/integration_service.dart';
import '../../integration/models/integration_lead_model.dart';

/// Modal dialog to toggle column visibility and order in Campaign Leads tables.
class CampaignColumnSettingsDialog extends StatefulWidget {
  final List<String> allHeaders;
  final List<IntegrationLeadModel> leads;
  final String section;
  final IntegrationService service;
  final VoidCallback? onColumnsChanged;

  const CampaignColumnSettingsDialog({
    super.key,
    required this.allHeaders,
    required this.leads,
    required this.section,
    required this.service,
    this.onColumnsChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> allHeaders,
    required List<IntegrationLeadModel> leads,
    required String section,
    IntegrationService? service,
    VoidCallback? onColumnsChanged,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => CampaignColumnSettingsDialog(
        allHeaders: allHeaders,
        leads: leads,
        section: section,
        service: service ?? IntegrationService(),
        onColumnsChanged: onColumnsChanged,
      ),
    );
  }

  @override
  State<CampaignColumnSettingsDialog> createState() => _CampaignColumnSettingsDialogState();
}

class _CampaignColumnSettingsDialogState extends State<CampaignColumnSettingsDialog> {
  late Set<String> _visibleHeaders;

  @override
  void initState() {
    super.initState();
    _visibleHeaders = widget.service
        .getActiveVisibleHeaders(leadsSubset: widget.leads, section: widget.section)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = _visibleHeaders.length;
    final totalCount = widget.allHeaders.length;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.view_column_rounded, color: CRMColors.primaryOf(context), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Column Visibility ($visibleCount of $totalCount)',
              style: CRMTypography.headline.copyWith(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 400),
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.check_box_rounded, size: 16),
                    label: const Text('Show All', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _visibleHeaders = widget.allHeaders.toSet();
                      });
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.check_box_outline_blank_rounded, size: 16),
                    label: const Text('Hide Optional', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        // Keep minimum core headers
                        _visibleHeaders = widget.allHeaders
                            .where((h) => ['Lead Name', 'Mobile', 'Source', 'Status'].contains(h))
                            .toSet();
                      });
                    },
                  ),
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.allHeaders.length,
                  itemBuilder: (context, index) {
                    final header = widget.allHeaders[index];
                    final isVisible = _visibleHeaders.contains(header);

                    return CheckboxListTile(
                      dense: true,
                      title: Text(header, style: const TextStyle(fontSize: 13)),
                      value: isVisible,
                      activeColor: CRMColors.primaryOf(context),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _visibleHeaders.add(header);
                          } else {
                            if (_visibleHeaders.length > 1) {
                              _visibleHeaders.remove(header);
                            }
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            for (final header in widget.allHeaders) {
              await widget.service.setHeaderVisibility(
                header,
                _visibleHeaders.contains(header),
                section: widget.section,
              );
            }
            if (mounted) {
              Navigator.pop(context);
              widget.onColumnsChanged?.call();
              AppStatusSnackBar.show(
                context,
                message: 'Column preferences saved.',
                isSuccess: true,
              );
            }
          },
          child: const Text('Save Columns'),
        ),
      ],
    );
  }
}
