import 'package:flutter/material.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/report_data.dart';
import 'lead_drilldown_dialog.dart';

class LeadStatusPipelineSection extends StatelessWidget {
  final List<PipelineStageData> stages;

  const LeadStatusPipelineSection({
    super.key,
    required this.stages,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;

    if (stages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_tree_outlined, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Lead Status Pipeline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Text(
                '${stages.length} Dynamic Stages',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dynamic Pipeline Stages List
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < stages.length; i++) ...[
                  _buildPipelineNode(context, stages[i]),
                  if (i < stages.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineNode(BuildContext context, PipelineStageData stage) {
    final isDark = ThemeManager().isDarkMode;

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (dCtx) => LeadDrilldownDialog(
            title: 'Pipeline Stage: ${stage.displayName}',
            subtitle: '${stage.count} leads in this stage (${stage.percentage.toStringAsFixed(1)}% of total pipeline)',
            leads: stage.leads,
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: stage.color.withValues(alpha: isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: stage.color.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: stage.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stage.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              stage.count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: stage.color,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${stage.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: stage.color,
                  ),
                ),
                const Icon(Icons.open_in_new_rounded, size: 12, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
