import 'package:flutter/material.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/report_data.dart';
import '../models/report_kpi_type.dart';
import 'lead_drilldown_dialog.dart';

class CallPerformanceSection extends StatelessWidget {
  final ReportOverallData data;

  const CallPerformanceSection({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final attempted = data.kpiValues[ReportKpiType.callAttempted];
    final pickedUp = data.kpiValues[ReportKpiType.callPickedUp];
    final open = data.kpiValues[ReportKpiType.callOpen];
    final attemptedCount = attempted?.count ?? 0;
    final pickedCount = pickedUp?.count ?? 0;
    final openCount = open?.count ?? 0;
    final pickedPct = attemptedCount == 0 ? 0.0 : pickedCount / attemptedCount * 100;
    final openPct = attemptedCount == 0 ? 0.0 : openCount / attemptedCount * 100;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.phone_in_talk_outlined, size: 18),
              SizedBox(width: 8),
              Text(
                'Call Performance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CallNode(
            label: 'Call Attempted',
            count: attemptedCount,
            percentage: attempted?.percentage ?? 0,
            color: const Color(0xFFD97706),
            isDark: isDark,
            onTap: () => _openLeads(context, 'Call Attempted', data.filteredLeads),
          ),
          Center(
            child: Icon(
              Icons.arrow_downward_rounded,
              size: 18,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
            LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 520;
              final picked = _CallNode(
                label: 'Picked Up',
                count: pickedCount,
                percentage: pickedPct,
                color: const Color(0xFF059669),
                isDark: isDark,
                onTap: () => _openLeads(
                  context,
                  'Call Picked Up',
                  data.filteredLeads.where((l) {
                    final s = l.status.toLowerCase();
                    return s.contains('picked up') || s.contains('pickedup');
                  }).toList(),
                ),
              );
              final openNode = _CallNode(
                label: 'Open',
                count: openCount,
                percentage: openPct,
                color: const Color(0xFFE11D48),
                isDark: isDark,
                onTap: () => _openLeads(
                  context,
                  'Call Open',
                  data.filteredLeads.where((l) {
                    final s = l.status.toLowerCase();
                    return s.contains('open') || s.contains('not answering');
                  }).toList(),
                ),
              );
              if (stacked) {
                return Column(children: [picked, const SizedBox(height: 10), openNode]);
              }
              return Row(
                children: [
                  Expanded(child: picked),
                  const SizedBox(width: 12),
                  Expanded(child: openNode),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _openLeads(BuildContext context, String title, List leads) {
    showDialog(
      context: context,
      builder: (_) => LeadDrilldownDialog(
        title: title,
        subtitle: 'Telecaller call outcomes for the selected period',
        leads: List.from(leads),
      ),
    );
  }
}

class _CallNode extends StatelessWidget {
  final String label;
  final int count;
  final double percentage;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _CallNode({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 32,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count.toString(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
