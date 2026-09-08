import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/report_configuration.dart';
import '../models/report_data.dart';
import '../models/report_kpi_type.dart';

class TrendAnalysisSection extends StatelessWidget {
  final bool isVisible;
  final ReportKpiType selectedMetric;
  final TrendGranularity selectedGranularity;
  final List<TrendDataPoint> trendPoints;
  final ValueChanged<bool> onToggleVisibility;
  final ValueChanged<ReportKpiType> onMetricChanged;
  final ValueChanged<TrendGranularity> onGranularityChanged;

  const TrendAnalysisSection({
    super.key,
    required this.isVisible,
    required this.selectedMetric,
    required this.selectedGranularity,
    required this.trendPoints,
    required this.onToggleVisibility,
    required this.onMetricChanged,
    required this.onGranularityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    const availableMetrics = [
      ReportKpiType.totalLeads,
      ReportKpiType.leadsContacted,
      ReportKpiType.leadQualificationRate,
      ReportKpiType.siteVisitsScheduled,
      ReportKpiType.siteVisitsDone,
      ReportKpiType.convertedToWon,
      ReportKpiType.callAttempted,
      ReportKpiType.callPickedUp,
      ReportKpiType.lostUnsuccessful,
    ];

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
          // Header with ON/OFF Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart_rounded, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Trend Analysis',
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

          // If enabled, render controls and chart
          if (isVisible) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Metric Selector
                Row(
                  children: [
                    Text(
                      'Metric: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    DropdownButton<ReportKpiType>(
                      value: availableMetrics.contains(selectedMetric) ? selectedMetric : ReportKpiType.totalLeads,
                      underline: const SizedBox(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      items: availableMetrics.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(m.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) onMetricChanged(val);
                      },
                    ),
                  ],
                ),

                // Granularity Selector
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    children: TrendGranularity.values.map((g) {
                      final isSel = g == selectedGranularity;
                      return InkWell(
                        onTap: () => onGranularityChanged(g),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSel ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            g.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Line Chart View
            SizedBox(
              height: 200,
              width: double.infinity,
              child: trendPoints.isEmpty
                  ? Center(
                      child: Text(
                        'No trend points available for this selection.',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : CustomPaint(
                      painter: _TrendLineChartPainter(
                        points: trendPoints,
                        lineColor: primaryColor,
                        isDark: isDark,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendLineChartPainter extends CustomPainter {
  final List<TrendDataPoint> points;
  final Color lineColor;
  final bool isDark;

  _TrendLineChartPainter({
    required this.points,
    required this.lineColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final num maxVal = points.map((p) => p.value).fold(1, (max, v) => v > max ? v : max);
    final double paddingLeft = 32.0;
    final double paddingBottom = 26.0;
    final double paddingTop = 12.0;
    final double paddingRight = 16.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    // Draw horizontal grid lines and Y-axis labels
    final gridPaint = Paint()
      ..color = (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)).withValues(alpha: 0.7)
      ..strokeWidth = 0.8;

    const gridSteps = 4;
    for (int i = 0; i <= gridSteps; i++) {
      final y = paddingTop + (chartHeight * i / gridSteps);
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      final val = ((gridSteps - i) * maxVal / gridSteps).round();
      final textSpan = TextSpan(
        text: val.toString(),
        style: TextStyle(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          fontSize: 10,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(4, y - tp.height / 2));
    }

    // Compute pixel points
    final List<Offset> offsets = [];
    final dxStep = points.length > 1 ? chartWidth / (points.length - 1) : chartWidth / 2;

    for (int i = 0; i < points.length; i++) {
      final x = paddingLeft + (i * dxStep);
      final normalizedY = maxVal > 0 ? (points[i].value / maxVal) : 0.0;
      final y = paddingTop + chartHeight - (normalizedY * chartHeight);
      offsets.add(Offset(x, y));

      // Draw X-axis label every few points
      if (points.length <= 10 || i % (points.length ~/ 6) == 0 || i == points.length - 1) {
        final tp = TextPainter(
          text: TextSpan(
            text: points[i].label,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 9,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, size.height - paddingBottom + 6));
      }
    }

    // Draw Gradient Area fill under the line
    final path = Path();
    path.moveTo(offsets.first.dx, paddingTop + chartHeight);
    for (final o in offsets) {
      path.lineTo(o.dx, o.dy);
    }
    path.lineTo(offsets.last.dx, paddingTop + chartHeight);
    path.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: isDark ? 0.35 : 0.2),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight));
    canvas.drawPath(path, fillPaint);

    // Draw Line stroke
    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final linePath = Path();
    linePath.moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      linePath.lineTo(offsets[i].dx, offsets[i].dy);
    }
    canvas.drawPath(linePath, strokePaint);

    // Draw Data Point Circles
    final dotPaint = Paint()..color = lineColor;
    final dotInnerPaint = Paint()..color = isDark ? const Color(0xFF1E293B) : Colors.white;

    for (final o in offsets) {
      canvas.drawCircle(o, 4, dotPaint);
      canvas.drawCircle(o, 2, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor || oldDelegate.isDark != isDark;
  }
}
