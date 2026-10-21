import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../models/requirement_model.dart';
import '../../auth/models/user_model.dart';

/// Renders the summary count pills and quick metrics for the Requirements pipeline.
class RequirementSummaryBar extends StatelessWidget {
  final List<RequirementModel> requirements;
  final String activeListingTab;
  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;
  final UserModel? currentUser;
  final bool isSilentRefreshing;

  const RequirementSummaryBar({
    super.key,
    required this.requirements,
    required this.activeListingTab,
    required this.selectedStatus,
    required this.onStatusSelected,
    this.currentUser,
    this.isSilentRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    // Filter by active listing tab (Rent / Re-Sale / All)
    final scopedReqs = activeListingTab == 'All'
        ? requirements
        : requirements.where((r) {
            final lt = (r.listingTypeName ?? '').toLowerCase();
            if (activeListingTab.toLowerCase() == 'rent') {
              return lt.contains('rent');
            }
            if (activeListingTab.toLowerCase() == 're-sale' || activeListingTab.toLowerCase() == 'resale') {
              return lt.contains('sale') || lt.contains('buy');
            }
            return true;
          }).toList();

    int totalCount = scopedReqs.length;
    int pendingCount = 0;
    int contactedCount = 0;
    int siteVisitCount = 0;
    int wonCount = 0;
    int lostCount = 0;

    for (final r in scopedReqs) {
      final s = r.status.trim().toLowerCase();
      if (s == 'deal won' || s == 'won' || s == 'closed') {
        wonCount++;
      } else if (s.contains('site visit')) {
        siteVisitCount++;
      } else if (s == 'contacted' || s == 'follow up' || s == 'follow-up' || s == 'in progress') {
        contactedCount++;
      } else if (s == 'lost' || s == 'rejected' || s == 'deal lost') {
        lostCount++;
      } else {
        pendingCount++;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 700;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMetricChip(
                context,
                label: 'All Leads',
                count: totalCount,
                statusValue: 'All',
                color: CRMColors.primaryOf(context),
                isCompact: isCompact,
              ),
              const SizedBox(width: CRMSpacing.xs),
              _buildMetricChip(
                context,
                label: 'Pending',
                count: pendingCount,
                statusValue: 'Pending',
                color: const Color(0xFFF59E0B),
                isCompact: isCompact,
              ),
              const SizedBox(width: CRMSpacing.xs),
              _buildMetricChip(
                context,
                label: 'Contacted',
                count: contactedCount,
                statusValue: 'Contacted',
                color: const Color(0xFF3B82F6),
                isCompact: isCompact,
              ),
              const SizedBox(width: CRMSpacing.xs),
              _buildMetricChip(
                context,
                label: 'Site Visit',
                count: siteVisitCount,
                statusValue: 'Site Visit',
                color: const Color(0xFF8B5CF6),
                isCompact: isCompact,
              ),
              const SizedBox(width: CRMSpacing.xs),
              _buildMetricChip(
                context,
                label: 'Won',
                count: wonCount,
                statusValue: 'Deal Won',
                color: const Color(0xFF10B981),
                isCompact: isCompact,
              ),
              const SizedBox(width: CRMSpacing.xs),
              _buildMetricChip(
                context,
                label: 'Lost',
                count: lostCount,
                statusValue: 'Lost',
                color: const Color(0xFFEF4444),
                isCompact: isCompact,
              ),
              if (isSilentRefreshing) ...[
                const SizedBox(width: CRMSpacing.s),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricChip(
    BuildContext context, {
    required String label,
    required int count,
    required String statusValue,
    required Color color,
    required bool isCompact,
  }) {
    final bool isSelected = selectedStatus.toLowerCase() == statusValue.toLowerCase() ||
        (statusValue == 'All' && (selectedStatus == 'All' || selectedStatus.isEmpty));

    return InkWell(
      onTap: () => onStatusSelected(statusValue),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 14,
          vertical: isCompact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : CRMColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : CRMColors.borderOf(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : CRMColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
