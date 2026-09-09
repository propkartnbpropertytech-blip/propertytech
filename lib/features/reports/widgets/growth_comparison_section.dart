import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/report_configuration.dart';
import '../models/report_data.dart';

class GrowthComparisonSection extends StatelessWidget {
  final bool isVisible;
  final GrowthComparisonPeriod activePeriod;
  final DateTime? customStart;
  final DateTime? customEnd;
  final List<GrowthComparisonItem> comparisonItems;
  final ValueChanged<bool> onToggleVisibility;
  final ValueChanged<GrowthComparisonPeriod> onPeriodChanged;
  final void Function(DateTime start, DateTime end)? onCustomDatesChanged;

  const GrowthComparisonSection({
    super.key,
    required this.isVisible,
    required this.activePeriod,
    this.customStart,
    this.customEnd,
    required this.comparisonItems,
    required this.onToggleVisibility,
    required this.onPeriodChanged,
    this.onCustomDatesChanged,
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
          // Section Header with Master ON/OFF Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.compare_arrows_rounded, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Growth & Comparison',
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
            // Comparison Selector (5 Modes)
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Compare against: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButton<GrowthComparisonPeriod>(
                        value: activePeriod,
                        underline: const SizedBox(),
                        isDense: true,
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
                    ),
                  ],
                ),

                // Custom Date Range Picker when Custom Period is selected
                if (activePeriod == GrowthComparisonPeriod.customPeriod)
                  InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: (customStart != null && customEnd != null)
                            ? DateTimeRange(start: customStart!, end: customEnd!)
                            : null,
                      );
                      if (picked != null && onCustomDatesChanged != null) {
                        onCustomDatesChanged!(picked.start, picked.end);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.date_range_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            (customStart != null && customEnd != null)
                                ? '${DateFormat('dd MMM yyyy').format(customStart!)}  →  ${DateFormat('dd MMM yyyy').format(customEnd!)}'
                                : 'Choose Custom Comparison Dates',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Comparison Metrics Cards Grid
            if (comparisonItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No comparison data available for the selected comparison period.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final isMedium = constraints.maxWidth >= 600 && !isWide;
                  final columns = isWide ? 4 : (isMedium ? 2 : 1);
                  final spacing = 12.0;
                  final cardWidth = (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: CRMColors.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Period',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    NumberFormat('#,##0').format(item.currentCount),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Previous Period',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    NumberFormat('#,##0').format(item.previousCount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Difference', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    '${isPositive ? '+' : ''}${NumberFormat('#,##0').format(item.difference)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Growth', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 14,
                        color: trendColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${isPositive ? '+' : ''}${item.growthPercentage.toStringAsFixed(2)}%',
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
        ],
      ),
    );
  }
}
