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
      case 'for sale':
      case 'sale':
      case 'resale':
      case 're-sale':
        return CRMColors.isDark ? const Color(0xFF3A2824) : CRMColors.terracottaSoft;
      case 'for rent':
      case 'rent':
        return CRMColors.isDark ? const Color(0xFF243228) : CRMColors.sageSoft;
      case 'active':
      case 'live':
      case 'available':
      case 'verified':
      case 'won':
      case 'resolved':
        return CRMColors.isDark ? const Color(0xFF222E24) : CRMColors.successBg;
      case 'pending':
      case 'follow-up':
      case 're-followup':
      case 'under discussion':
      case 'fresh':
        return CRMColors.isDark ? const Color(0xFF3A2F20) : CRMColors.sandSoft;
      case 'site visit':
      case 'site visit scheduled':
      case 'scheduled':
        return CRMColors.isDark ? const Color(0xFF3A2726) : CRMColors.roseSoft;
      case 'closed':
      case 'booked':
      case 'sold':
        return CRMColors.isDark ? const Color(0xFF322226) : CRMColors.plumSoft;
      case 'dead':
      case 'suspended':
      case 'rejected':
      case 'expired':
      case 'lost':
        return CRMColors.isDark ? const Color(0xFF332221) : CRMColors.dangerBg;
      default:
        return CRMColors.isDark ? const Color(0xFF2A2623) : CRMColors.groupedBackground;
    }
  }

  Color _getTextColor(BuildContext context) {
    switch (status.trim().toLowerCase()) {
      case 'for sale':
      case 'sale':
      case 'resale':
      case 're-sale':
        return CRMColors.isDark ? const Color(0xFFD47A66) : CRMColors.terracotta;
      case 'for rent':
      case 'rent':
        return CRMColors.isDark ? const Color(0xFF8FB392) : CRMColors.sage;
      case 'active':
      case 'live':
      case 'available':
      case 'verified':
      case 'won':
      case 'resolved':
        return CRMColors.isDark ? const Color(0xFF86A58C) : CRMColors.success;
      case 'pending':
      case 'follow-up':
      case 're-followup':
      case 'under discussion':
      case 'fresh':
        return CRMColors.isDark ? const Color(0xFFC99E6E) : CRMColors.warning;
      case 'site visit':
      case 'site visit scheduled':
      case 'scheduled':
        return CRMColors.isDark ? const Color(0xFFC98D85) : CRMColors.rose;
      case 'closed':
      case 'booked':
      case 'sold':
        return CRMColors.isDark ? const Color(0xFFA6858A) : CRMColors.plum;
      case 'dead':
      case 'suspended':
      case 'rejected':
      case 'expired':
      case 'lost':
        return CRMColors.isDark ? const Color(0xFFC47C78) : CRMColors.danger;
      default:
        return CRMColors.textSecondaryOf(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CRMSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _getBgColor(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _getTextColor(context).withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Text(
        status,
        style: CRMTypography.captionBold.copyWith(
          color: _getTextColor(context),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
