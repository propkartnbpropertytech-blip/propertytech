import 'package:flutter/material.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/report_data.dart';
import '../models/report_kpi_type.dart';

class ConversionRateItem {
  final String label;
  final double percentage;
  final String detail;
  final Color color;

  const ConversionRateItem({
    required this.label,
    required this.percentage,
    required this.detail,
    required this.color,
  });
}

class ConversionAnalysisSection extends StatelessWidget {
  final ReportOverallData data;

  const ConversionAnalysisSection({
    super.key,
    required this.data,
  });

  static List<ConversionRateItem> ratesFrom(ReportOverallData data) {
    double pct(ReportKpiType type) => data.kpiValues[type]?.percentage ?? 0;
    int count(ReportKpiType type) => data.kpiValues[type]?.count ?? 0;
    String denom(ReportKpiType type) => data.kpiValues[type]?.denominatorLabel ?? '';

    return [
      ConversionRateItem(
        label: 'Contact Rate',
        percentage: pct(ReportKpiType.leadsContacted),
        detail: '${count(ReportKpiType.leadsContacted)} contacted · ${denom(ReportKpiType.leadsContacted)}',
        color: const Color(0xFF0284C7),
      ),
      ConversionRateItem(
        label: 'Call Pickup Rate',
        percentage: pct(ReportKpiType.callPickedUp),
        detail: '${count(ReportKpiType.callPickedUp)} picked up · ${denom(ReportKpiType.callPickedUp)}',
        color: const Color(0xFF059669),
      ),
      ConversionRateItem(
        label: 'Qualification Rate',
        percentage: pct(ReportKpiType.leadQualificationRate),
        detail: '${count(ReportKpiType.leadQualificationRate)} qualified · ${denom(ReportKpiType.leadQualificationRate)}',
        color: const Color(0xFF0D9488),
      ),
      ConversionRateItem(
        label: 'Site Visit Scheduled Rate',
        percentage: pct(ReportKpiType.siteVisitsScheduled),
        detail: '${count(ReportKpiType.siteVisitsScheduled)} scheduled · ${denom(ReportKpiType.siteVisitsScheduled)}',
        color: const Color(0xFF7C3AED),
      ),
      ConversionRateItem(
        label: 'Site Visit Completion Rate',
        percentage: pct(ReportKpiType.siteVisitsDone),
        detail: '${count(ReportKpiType.siteVisitsDone)} done · ${denom(ReportKpiType.siteVisitsDone)}',
        color: const Color(0xFF9333EA),
      ),
      ConversionRateItem(
        label: 'Won Conversion Rate',
        percentage: pct(ReportKpiType.convertedToWon),
        detail: '${count(ReportKpiType.convertedToWon)} won · ${denom(ReportKpiType.convertedToWon)}',
        color: const Color(0xFF16A34A),
      ),
      ConversionRateItem(
        label: 'Lost Rate',
        percentage: pct(ReportKpiType.lostUnsuccessful),
        detail: '${count(ReportKpiType.lostUnsuccessful)} lost · ${denom(ReportKpiType.lostUnsuccessful)}',
        color: const Color(0xFFDC2626),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final rates = ratesFrom(data);

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
              Icon(Icons.percent_rounded, size: 18),
              SizedBox(width: 8),
              Text(
                'Conversion Analysis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...rates.map((rate) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rate.label,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${rate.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: rate.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rate.detail,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = (constraints.maxWidth * (rate.percentage / 100)).clamp(0.0, constraints.maxWidth);
                      return Stack(
                        children: [
                          Container(
                            height: 7,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            height: 7,
                            width: width,
                            decoration: BoxDecoration(
                              color: rate.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
