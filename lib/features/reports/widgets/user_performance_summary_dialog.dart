import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/storage/isar_collections.dart';
import '../../../core/theme/theme_manager.dart';
import '../../requirements/models/requirement_model.dart';
import '../models/report_configuration.dart';
import '../models/report_data.dart';
import '../services/report_data_engine.dart';

class UserPerformanceSummaryDialog extends StatelessWidget {
  final UserPerformanceSummary summary;

  const UserPerformanceSummaryDialog({
    super.key,
    required this.summary,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String userName,
    required String role,
    required ReportConfiguration config,
    required List<RequirementModel> allLeads,
    required List<FollowupLocal> allFollowups,
  }) {
    final summary = ReportDataEngine.computeUserPerformanceSummary(
      userId: userId,
      userName: userName,
      role: role,
      config: config,
      allLeads: allLeads,
      allFollowups: allFollowups,
    );

    return showDialog(
      context: context,
      builder: (ctx) => UserPerformanceSummaryDialog(summary: summary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;
    final isTelecaller = summary.role.toLowerCase().contains('telecaller');
    final roleColor = isTelecaller ? const Color(0xFF0284C7) : const Color(0xFF16A34A);

    final initials = summary.userName.trim().isNotEmpty
        ? summary.userName.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Avatar, User Details, Role Pill, and Close
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: roleColor.withValues(alpha: 0.15),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                summary.userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: roleColor.withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                summary.role,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: roleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              size: 13,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              summary.dateRangeLabel,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Filter Scope Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Filtered by active dashboard Date Range and Global Attributes.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 13 Metrics Cards Grid
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Key Funnel Metrics
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context: context,
                              isDark: isDark,
                              label: isTelecaller ? 'Leads Handled' : 'Leads Assigned',
                              value: summary.leadsHandled.toString(),
                              icon: Icons.people_outline_rounded,
                              color: const Color(0xFF14213D),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              context: context,
                              isDark: isDark,
                              label: 'Contacted',
                              value: summary.leadsContacted.toString(),
                              icon: Icons.contact_phone_outlined,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              context: context,
                              isDark: isDark,
                              label: 'Qualified',
                              value: summary.qualifiedLeads.toString(),
                              icon: Icons.check_circle_outline_rounded,
                              color: const Color(0xFF0D9488),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Conversion & Visits
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context: context,
                              isDark: isDark,
                              label: 'Site Visits',
                              value: summary.siteVisits.toString(),
                              icon: Icons.location_city_outlined,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              context: context,
                              isDark: isDark,
                              label: 'Won Leads',
                              value: summary.wonLeads.toString(),
                              icon: Icons.military_tech_outlined,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              context: context,
                              isDark: isDark,
                              label: 'Conversion Rate',
                              value: '${summary.conversionPercentage.toStringAsFixed(1)}%',
                              icon: Icons.trending_up_rounded,
                              color: primaryColor,
                              isHighlighted: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Call Activity & Pending
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context: context,
                              isDark: isDark,
                              label: 'Calls Attempted',
                              value: summary.callAttempted.toString(),
                              icon: Icons.phone_forwarded_outlined,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              context: context,
                              isDark: isDark,
                              label: 'Calls Picked Up',
                              value: summary.callPickedUp.toString(),
                              icon: Icons.phone_in_talk_outlined,
                              color: const Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              context: context,
                              isDark: isDark,
                              label: 'Calls Open',
                              value: summary.callOpen.toString(),
                              icon: Icons.phone_paused_outlined,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Pending Followups & Lost
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context: context,
                              isDark: isDark,
                              label: 'Pending Follow-ups',
                              value: summary.pendingFollowups.toString(),
                              icon: Icons.pending_actions_rounded,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              context: context,
                              isDark: isDark,
                              label: 'Lost / Closed Unsuccessful',
                              value: summary.lostLeads.toString(),
                              icon: Icons.cancel_outlined,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Bottom Actions: Navigation Bridge to Stage 2 Placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      final targetRoute = isTelecaller
                          ? '/reports/leads/telecaller'
                          : '/reports/leads/sales';
                      context.go(targetRoute);
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text(
                      isTelecaller
                          ? 'View Full Telecaller Report →'
                          : 'View Full Sales Report →',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? color : (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
