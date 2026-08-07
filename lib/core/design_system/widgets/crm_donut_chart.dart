import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class ChartSector {
  final String label;
  final double value;
  final Color color;

  ChartSector({
    required this.label,
    required this.value,
    required this.color,
  });
}

class DonutChart3DPainter extends CustomPainter {
  final List<ChartSector> sectors;
  final Color backgroundColor;
  final double animationValue;
  final bool isDark;

  DonutChart3DPainter({
    required this.sectors,
    required this.backgroundColor,
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double total = sectors.fold(0, (sum, s) => sum + s.value);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width / 2 : size.height / 2) - 2;
    final strokeWidth = radius * 0.38;
    final outerRadius = radius;
    final innerRadius = radius - strokeWidth;

    for (int i = 3; i >= 1; i--) {
      final shadowPaint = Paint()
        ..color = (isDark ? Colors.black : const Color(0xFF94A3B8))
            .withOpacity(0.06 * i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + (i * 1.5)
        ..isAntiAlias = true;
      final shadowOffset = Offset(0, i * 0.8);
      canvas.drawCircle(
        center + shadowOffset,
        outerRadius - strokeWidth / 2,
        shadowPaint,
      );
    }

    final animatedSweepTotal = 2 * math.pi * animationValue;
    double startAngle = -math.pi / 2;

    for (final sector in sectors) {
      final sweepAngle = (sector.value / total) * animatedSweepTotal;
      final midAngle = startAngle + sweepAngle / 2;

      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..isAntiAlias = true;

      final darkerColor = Color.lerp(sector.color, Colors.black, 0.25)!;
      final lighterColor = Color.lerp(sector.color, Colors.white, 0.2)!;
      arcPaint.shader = ui.Gradient.sweep(
        center,
        [lighterColor, sector.color, darkerColor, sector.color],
        [0.0, 0.3, 0.7, 1.0],
        TileMode.clamp,
        startAngle,
        startAngle + sweepAngle,
      );

      final arcRect =
          Rect.fromCircle(center: center, radius: outerRadius - strokeWidth / 2);
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);

      if (sweepAngle > 0.4 && animationValue > 0.5) {
        final textOpacity = ((animationValue - 0.5) * 2).clamp(0.0, 1.0);
        final textRadius = outerRadius - strokeWidth / 2;
        final textX = center.dx + textRadius * math.cos(midAngle);
        final textY = center.dy + textRadius * math.sin(midAngle);
        final percentage = (sector.value / total * 100).toStringAsFixed(0);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '$percentage%',
            style: TextStyle(
              color: Colors.white.withOpacity(textOpacity),
              fontSize: (strokeWidth * 0.38).clamp(7.0, 11.0),
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    }

    final innerGradient = ui.Gradient.radial(
      Offset(center.dx - innerRadius * 0.2, center.dy - innerRadius * 0.2),
      innerRadius,
      isDark
          ? [const Color(0xFF1A2438), const Color(0xFF070B14)]
          : [Colors.white, const Color(0xFFF1F5F9)],
      [0.0, 1.0],
    );
    final innerPaint = Paint()
      ..shader = innerGradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, innerRadius - 1, innerPaint);

    final innerRingPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF94A3B8)).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..isAntiAlias = true;
    canvas.drawCircle(center, innerRadius - 1, innerRingPaint);

    final highlightRect =
        Rect.fromCircle(center: center, radius: outerRadius - strokeWidth / 2);
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.4
      ..isAntiAlias = true
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - outerRadius),
        center,
        [
          Colors.white.withOpacity(isDark ? 0.08 : 0.18),
          Colors.white.withOpacity(0.0),
        ],
      );
    canvas.drawArc(highlightRect, -math.pi, math.pi, false, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant DonutChart3DPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.sectors != sectors ||
        oldDelegate.isDark != isDark;
  }
}

/// Animated 3D donut used on the dashboard KPI hero.
class CRMDonutChartCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<ChartSector> sectors;
  final Color? accent;
  final ValueChanged<ChartSector>? onSectorTap;
  /// When false, entrance animation plays once on mount only (no replay on data updates).
  final bool replayOnUpdate;

  const CRMDonutChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sectors,
    this.accent,
    this.onSectorTap,
    this.replayOnUpdate = false,
  });

  @override
  State<CRMDonutChartCard> createState() => _CRMDonutChartCardState();
}

class _CRMDonutChartCardState extends State<CRMDonutChartCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant CRMDonutChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replayOnUpdate && oldWidget.sectors != widget.sectors) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent ?? CRMColors.primaryOf(context);
    final total = widget.sectors.fold<double>(0, (s, e) => s + e.value);

    return AnimatedContainer(
      duration: CRMMotion.atmosphere,
      curve: CRMMotion.emphasized,
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: accent.withValues(alpha: 0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.12 : 0.06),
            CRMColors.cardBgOf(context),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: CRMTypography.cardTitle.copyWith(
              color: CRMColors.textOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: CRMTypography.benefit.copyWith(
              color: CRMColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: DonutChart3DPainter(
                        sectors: widget.sectors,
                        backgroundColor: CRMColors.cardBgOf(context),
                        animationValue:
                            Curves.easeOutCubic.transform(_controller.value),
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.sectors.map((s) {
                    final pct = total == 0 ? 0 : (s.value / total * 100);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: widget.onSectorTap == null
                            ? null
                            : () => widget.onSectorTap!(s),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: s.color,
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: s.color.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.label,
                                style: CRMTypography.captionBold.copyWith(
                                  color: CRMColors.textOf(context),
                                ),
                              ),
                            ),
                            Text(
                              '${s.value.toInt()} · ${pct.toStringAsFixed(0)}%',
                              style: CRMTypography.caption.copyWith(
                                color: CRMColors.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
