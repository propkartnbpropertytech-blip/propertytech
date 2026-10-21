import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/app_status_snackbar.dart';
import '../../integration/models/integration_lead_model.dart';
import '../domain/usecases/reclassify_campaign_lead_usecase.dart';

/// Modal dialog to prompt and execute Campaign Lead reclassification
/// between "Property Listing" (Seller/Owner) and "Requirement Lead" (Buyer/Tenant).
class LeadReclassifyDialog extends StatefulWidget {
  final IntegrationLeadModel lead;
  final ReclassifyCampaignLeadUseCase useCase;
  final VoidCallback? onReclassified;

  const LeadReclassifyDialog({
    super.key,
    required this.lead,
    required this.useCase,
    this.onReclassified,
  });

  static Future<bool?> show(
    BuildContext context, {
    required IntegrationLeadModel lead,
    ReclassifyCampaignLeadUseCase? useCase,
    VoidCallback? onReclassified,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => LeadReclassifyDialog(
        lead: lead,
        useCase: useCase ?? ReclassifyCampaignLeadUseCase(),
        onReclassified: onReclassified,
      ),
    );
  }

  @override
  State<LeadReclassifyDialog> createState() => _LeadReclassifyDialogState();
}

class _LeadReclassifyDialogState extends State<LeadReclassifyDialog> {
  late String _selectedType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Default to the other type
    _selectedType = widget.lead.leadType == 'Property Listing' ? 'Requirement' : 'Property Listing';
  }

  @override
  Widget build(BuildContext context) {
    final clientName = widget.lead.customerName.isNotEmpty ? widget.lead.customerName : 'Unknown Client';
    final currentType = widget.lead.leadType;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.swap_horiz_rounded, color: CRMColors.primaryOf(context), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reclassify Lead: $clientName',
              style: CRMTypography.headline.copyWith(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Classification: $currentType',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CRMColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select new lead classification destination:',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              dense: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: const Text('Property Listing (Seller / Owner / Builder)'),
              subtitle: const Text('Move to Property Listing section and inventory matches', style: TextStyle(fontSize: 11)),
              value: 'Property Listing',
              groupValue: _selectedType,
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            RadioListTile<String>(
              dense: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: const Text('Requirement Lead (Buyer / Tenant)'),
              subtitle: const Text('Move to Buyer Requirements section and run match engine', style: TextStyle(fontSize: 11)),
              value: 'Requirement',
              groupValue: _selectedType,
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  setState(() => _isSaving = true);
                  // 1. Optimistic update
                  widget.useCase.executeOptimistic(widget.lead.id, _selectedType);
                  // 2. Remote update
                  final ok = await widget.useCase.execute(widget.lead.id, _selectedType);
                  if (mounted) {
                    Navigator.pop(context, ok);
                    AppStatusSnackBar.show(
                      context,
                      message: ok
                          ? 'Lead reclassified to $_selectedType successfully.'
                          : 'Reclassified locally (sync pending).',
                      isSuccess: ok,
                    );
                    widget.onReclassified?.call();
                  }
                },
          child: _isSaving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirm Reclassify'),
        ),
      ],
    );
  }
}
