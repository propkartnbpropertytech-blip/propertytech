import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class CRMStatusChip extends StatelessWidget {
  final String status;

  const CRMStatusChip({
    super.key,
    required this.status,
  });

  Color _getBgColor(BuildContext context) {
    switch (status.trim().toLowerCase()) {
      case 'active':
      case 'live':
        return CRMColors.primaryOf(context).withOpacity(0.12);
      case 'won':
      case 'resolved':
      case 'closed':
      case 'verified':
        return CRMColors.success.withOpacity(0.12);
      case 'pending':
        return CRMColors.warning.withOpacity(0.12);
      case 'dead':
      case 'suspended':
      case 'rejected':
      case 'expired':
        return CRMColors.danger.withOpacity(0.12);
      default:
        return CRMColors.textSecondaryOf(context).withOpacity(0.12);
    }
  }

  Color _getTextColor(BuildContext context) {
    switch (status.trim().toLowerCase()) {
      case 'active':
      case 'live':
        return CRMColors.primaryOf(context);
      case 'won':
      case 'resolved':
      case 'closed':
      case 'verified':
        return CRMColors.success;
      case 'pending':
        return CRMColors.warning;
      case 'dead':
      case 'suspended':
      case 'rejected':
      case 'expired':
        return CRMColors.danger;
      default:
        return CRMColors.textSecondaryOf(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CRMSpacing.s,
        vertical: CRMSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: _getBgColor(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.round),
        border: Border.all(
          color: _getTextColor(context).withOpacity(
            (CRMColors.isDark &&
                    CRMColors.isRentMode &&
                    _getTextColor(context) == CRMColors.primaryOf(context))
                ? 0.45
                : 0.12,
          ),
          width: 0.5,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: CRMTypography.captionBold.copyWith(
          color: _getTextColor(context),
          fontSize: 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
