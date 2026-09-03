import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/dashboard_summary.dart';

class AnalyticsSection extends StatelessWidget {
  final DashboardData? data;
  final bool isRent;

  const AnalyticsSection({super.key, this.data, this.isRent = false});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InventoryOverviewChartCard(
              summary: data?.summary,
              isRent: isRent,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: TopLocationsChartCard(
              properties: data?.recentProperties ?? const [],
              topArea: data?.summary.topArea,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        InventoryOverviewChartCard(
          summary: data?.summary,
          isRent: isRent,
        ),
        const SizedBox(height: 20),
        TopLocationsChartCard(
          properties: data?.recentProperties ?? const [],
          topArea: data?.summary.topArea,
        ),
      ],
    );
  }
}

// ── Inventory Overview Line Chart ───────────────────────────
class InventoryOverviewChartCard extends StatefulWidget {
  final DashboardSummary? summary;
  final bool isRent;

  const InventoryOverviewChartCard({
    super.key,
    this.summary,
    this.isRent = false,
  });

  @override
  State<InventoryOverviewChartCard> createState() =>
      _InventoryOverviewChartCardState();
}

class _InventoryOverviewChartCardState
    extends State<InventoryOverviewChartCard> {
  String _selectedRange = 'This Month';

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final isRent = widget.isRent;
    final availableVal = (isRent
            ? widget.summary?.rentalAvailable
            : widget.summary?.resaleAvailable) ??
        0;
    final reqsVal = (isRent
            ? widget.summary?.rentalRequirements
            : widget.summary?.resaleRequirements) ??
        0;
    final closedVal = (isRent
            ? widget.summary?.rentalRented
            : widget.summary?.resaleSold) ??
        0;
    final wonVal = (isRent
            ? widget.summary?.rentalWonRequirements
            : widget.summary?.resaleWonRequirements) ??
        0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRent ? 'Rental Inventory' : 'Re-Sale Inventory',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF14213D),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Property volume and turnover',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF68738A),
                    ),
                  ),
                ],
              ),
              _buildDropdown(
                value: _selectedRange,
                items: const [
                  'This Week',
                  'This Month',
                  'This Quarter',
                  'This Year',
                ],
                isDark: isDark,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRange = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _ModernLineChartPainter(
                lineColor: ThemeManager().primaryColor,
                isDark: isDark,
                fillGradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ThemeManager().primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    ThemeManager().primaryColor.withValues(alpha: 0.0),
                  ],
                ),
                dataPoints: [
                  availableVal.toDouble(),
                  reqsVal.toDouble(),
                  closedVal.toDouble(),
                  wonVal.toDouble(),
                  (widget.summary?.available ?? 0).toDouble(),
                  (widget.summary?.totalProperties ?? 0).toDouble(),
                ],
                xLabels: const [
                  'Avail',
                  'Leads',
                  'Closed',
                  'Won',
                  'Total Avail',
                  'Inventory',
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF243044) : const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor:
              isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF68738A),
          ),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? const Color(0xFFF8FAFC)
                : const Color(0xFF14213D),
          ),
          onChanged: onChanged,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }
}

class _ModernLineChartPainter extends CustomPainter {
  final Color lineColor;
  final Gradient fillGradient;
  final List<double> dataPoints;
  final List<String> xLabels;
  final bool isDark;

  _ModernLineChartPainter({
    required this.lineColor,
    required this.fillGradient,
    required this.dataPoints,
    required this.xLabels,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final double bottomPadding = 24.0;
    final double chartHeight = size.height - bottomPadding;
    final double chartWidth = size.width;

    // Grid lines
    final gridPaint = Paint()
      ..color = isDark
          ? const Color(0xFF334155).withValues(alpha: 0.5)
          : const Color(0xFFF1F4F9)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = chartHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final double maxVal = dataPoints.reduce(math.max) > 0
        ? dataPoints.reduce(math.max) * 1.15
        : 10.0;
    final double minVal = 0.0;
    final double range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);

    final List<Offset> points = [];
    final double stepX = chartWidth / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final y = chartHeight - ((dataPoints[i] - minVal) / range) * chartHeight;
      points.add(Offset(x, y));
    }

    // Smooth Bezier Curve Path
    final path = Path();
    final fillPath = Path();

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, chartHeight);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      fillPath.cubicTo(
        controlX1,
        controlY1,
        controlX2,
        controlY2,
        p1.dx,
        p1.dy,
      );
    }

    fillPath.lineTo(points.last.dx, chartHeight);
    fillPath.close();

    // Draw Fill
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(0, 0, chartWidth, chartHeight),
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(path, linePaint);

    // Draw Dots and Labels
    final dotPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dotStrokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 4.5, dotPaint);
      canvas.drawCircle(pt, 4.5, dotStrokePaint);

      // X label
      if (i < xLabels.length) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: xLabels[i],
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final x = (pt.dx - textPainter.width / 2).clamp(
          0.0,
          chartWidth - textPainter.width,
        );
        textPainter.paint(canvas, Offset(x, chartHeight + 8));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Top Locations Donut Chart ───────────────────────────────
class TopLocationsChartCard extends StatefulWidget {
  final List<RecentProperty> properties;
  final String? topArea;

  const TopLocationsChartCard({
    super.key,
    this.properties = const [],
    this.topArea,
  });

  @override
  State<TopLocationsChartCard> createState() => _TopLocationsChartCardState();
}

class _TopLocationsChartCardState extends State<TopLocationsChartCard> {
  String _selectedRange = 'This Month';

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final Map<String, int> areaCounts = {};
    for (final p in widget.properties) {
      final area = p.areaName.trim();
      if (area.isNotEmpty && area != 'N/A') {
        areaCounts[area] = (areaCounts[area] ?? 0) + 1;
      }
    }

    final colors = [
      ThemeManager().primaryColor,
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFF97316),
      const Color(0xFF06B6D4),
    ];

    final List<_LocationData> locations = [];
    if (areaCounts.isNotEmpty) {
      final sortedEntries = areaCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topEntries = sortedEntries.take(5).toList();
      for (int i = 0; i < topEntries.length; i++) {
        locations.add(
          _LocationData(
            name: topEntries[i].key,
            count: topEntries[i].value,
            color: colors[i % colors.length],
          ),
        );
      }
    } else if (widget.topArea != null &&
        widget.topArea!.isNotEmpty &&
        widget.topArea != 'N/A') {
      locations.add(
        _LocationData(name: widget.topArea!, count: 1, color: colors[0]),
      );
    }

    final int total = locations.fold(0, (sum, item) => sum + item.count);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Locations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF14213D),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Active listings by micro-market',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF68738A),
                    ),
                  ),
                ],
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF243044)
                      : const Color(0xFFF1F4F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRange,
                    dropdownColor:
                        isDark ? const Color(0xFF1E293B) : Colors.white,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF68738A),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF14213D),
                    ),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRange = val);
                    },
                    items:
                        const [
                              'This Week',
                              'This Month',
                              'This Quarter',
                              'This Year',
                            ]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (locations.isNotEmpty)
            LayoutBuilder(
              builder: (context, cardConstraints) {
                final isNarrow = cardConstraints.maxWidth < 360;
                final chart = SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(130, 130),
                        painter: _DonutChartPainter(
                          locations: locations,
                          total: total,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF14213D),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Units',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF68738A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                final legend = Column(
                  children: locations.map((loc) {
                    final percent = ((loc.count / total) * 100).toStringAsFixed(0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: loc.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFF8FAFC)
                                    : const Color(0xFF14213D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${loc.count} ($percent%)',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF68738A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      chart,
                      const SizedBox(height: 16),
                      legend,
                    ],
                  );
                }

                return Row(
                  children: [
                    chart,
                    const SizedBox(width: 20),
                    Expanded(child: legend),
                  ],
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'No location data available yet',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF68738A),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationData {
  final String name;
  final int count;
  final Color color;

  const _LocationData({
    required this.name,
    required this.count,
    required this.color,
  });
}

class _DonutChartPainter extends CustomPainter {
  final List<_LocationData> locations;
  final int total;

  _DonutChartPainter({required this.locations, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;

    double startAngle = -math.pi / 2;

    for (final loc in locations) {
      final sweepAngle = (loc.count / total) * 2 * math.pi;
      final paint = Paint()
        ..color = loc.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      // Inset to prevent clipping
      final rect = Rect.fromCircle(
        center: center,
        radius: radius - strokeWidth / 2,
      );
      canvas.drawArc(rect, startAngle, sweepAngle - 0.08, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
