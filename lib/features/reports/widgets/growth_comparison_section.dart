import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/report_configuration.dart';
import '../models/report_data.dart';

class GrowthComparisonSection extends StatelessWidget {
  final bool isVisible;
  final GrowthComparisonPeriod activePeriod;
  final List<GrowthComparisonItem> comparisonItems;
  final ValueChanged<bool> onToggleVisibility;
  final ValueChanged<GrowthComparisonPeriod> onPeriodChanged;

  const GrowthComparisonSection({
    super.key,
    required this.isVisible,
    required this.activePeriod,
    required this.comparisonItems,
    required this.onToggleVisibility,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

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
          // Section Header with ON/OFF Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.compare_arrows_rounded, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Growth & Period Comparison',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isVisible
                          ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isVisible ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isVisible ? const Color(0xFF16A34A) : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              Switch(
                value: isVisible,
                activeThumbColor: primaryColor,
                onChanged: onToggleVisibility,
              ),
            ],
          ),

          // If Section is Enabled, Render Controls and Comparison Grid
          if (isVisible) ...[
            const SizedBox(height: 14),
            // Period Selector Dropdown
            Row(
              children: [
                Text(
                  'Compare against: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<GrowthComparisonPeriod>(
                  value: activePeriod,
                  underline: const SizedBox(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  items: GrowthComparisonPeriod.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) onPeriodChanged(val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Comparison Metrics Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;
                final isMedium = constraints.maxWidth >= 500 && !isWide;
                final cardWidth = isWide
                    ? (constraints.maxWidth - 36) / 4
                    : (isMedium ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth);

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: comparisonItems.map((item) {
                    return SizedBox(
                      width: cardWidth,
                      child: _buildComparisonCard(context, item),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context, GrowthComparisonItem item) {
    final isDark = ThemeManager().isDarkMode;
    final isPositive = item.difference >= 0;
    final trendColor = isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.metricName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(
                    item.currentCount.toString(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Previous', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(
                    item.previousCount.toString(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isPositive ? '+' : ''}${item.difference}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: trendColor,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 14,
                    color: trendColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositive ? '+' : ''}${item.growthPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
