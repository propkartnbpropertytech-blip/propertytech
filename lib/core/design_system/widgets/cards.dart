import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class CRMCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? headerAction;
  final Widget child;
  final Widget? footer;
  final EdgeInsetsGeometry padding;
  final bool elevated;
  final Color? accentBorder;

  const CRMCard({
    super.key,
    this.title,
    this.subtitle,
    this.headerAction,
    required this.child,
    this.footer,
    this.padding = const EdgeInsets.all(CRMSpacing.m),
    this.elevated = false,
    this.accentBorder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: CRMMotion.medium,
      curve: CRMMotion.easeOut,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: elevated
            ? CRMColors.surfaceElevatedOf(context)
            : CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: accentBorder ??
              CRMColors.borderOf(context).withValues(alpha: 0.55),
          width: accentBorder != null ? 1.0 : 0.5,
        ),
        boxShadow: elevated ? CRMShadows.medium : CRMShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || subtitle != null || headerAction != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: CRMSpacing.m,
                right: CRMSpacing.m,
                top: CRMSpacing.m,
                bottom: CRMSpacing.s,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CRMTypography.cardTitle
                                .copyWith(color: CRMColors.textOf(context)),
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: CRMSpacing.xxs),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: CRMTypography.benefit.copyWith(
                              color: CRMColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (headerAction != null) headerAction!,
                ],
              ),
            ),
            Divider(
              color: CRMColors.divider,
              height: 1,
              thickness: 0.5,
            ),
          ],
          Padding(
            padding: padding,
            child: child,
          ),
          if (footer != null) ...[
            Divider(
              color: CRMColors.divider,
              height: 1,
              thickness: 0.5,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CRMSpacing.m,
                vertical: CRMSpacing.s,
              ),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}

class CRMKPICard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final double? growthPercent;
  final String? lastUpdated;
  final String? benefit;
  final VoidCallback? onTap;
  final List<double>? sparkline;

  const CRMKPICard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.growthPercent,
    this.lastUpdated,
    this.benefit,
    this.onTap,
    this.sparkline,
  });

  @override
  State<CRMKPICard> createState() => _CRMKPICardState();
}

class _CRMKPICardState extends State<CRMKPICard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final showGrowth = widget.growthPercent != null;
    final isPositive = (widget.growthPercent ?? 0.0) >= 0;
    final activeIconColor = widget.iconColor ?? CRMColors.primaryOf(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final lift = _pressed ? 0.97 : (_hovered ? 1.02 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: lift,
          duration: CRMMotion.press,
          curve: CRMMotion.emphasized,
          child: AnimatedContainer(
            duration: CRMMotion.medium,
            curve: CRMMotion.easeOut,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
              boxShadow: _hovered
                  ? [
                      ...CRMShadows.medium,
                      BoxShadow(
                        color: activeIconColor.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : CRMShadows.soft,
            ),
            child: CRMCard(
              elevated: true,
              accentBorder: _hovered
                  ? activeIconColor.withValues(alpha: 0.45)
                  : null,
              padding: EdgeInsets.all(isMobile ? CRMSpacing.s : CRMSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: (isMobile
                                  ? CRMTypography.captionBold
                                      .copyWith(fontSize: 11)
                                  : CRMTypography.captionBold)
                              .copyWith(
                                  color: CRMColors.textSecondaryOf(context)),
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.xxs),
                      AnimatedContainer(
                        duration: CRMMotion.fast,
                        padding: EdgeInsets.all(
                            isMobile ? CRMSpacing.xxs : CRMSpacing.xs),
                        decoration: BoxDecoration(
                          color: activeIconColor
                              .withValues(alpha: _hovered ? 0.18 : 0.1),
                          borderRadius:
                              BorderRadius.circular(CRMBorderRadius.s),
                        ),
                        child: Icon(widget.icon,
                            color: activeIconColor, size: isMobile ? 15 : 18),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? CRMSpacing.xxs : CRMSpacing.s),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.value,
                            style: (isMobile
                                    ? CRMTypography.statistics
                                        .copyWith(fontSize: 22)
                                    : CRMTypography.statistics)
                                .copyWith(color: CRMColors.textOf(context)),
                          ),
                        ),
                      ),
                      if (widget.sparkline != null &&
                          widget.sparkline!.length >= 2)
                        SizedBox(
                          width: 48,
                          height: 22,
                          child: CustomPaint(
                            painter: _SparklinePainter(
                              values: widget.sparkline!,
                              color: activeIconColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.benefit != null) ...[
                    SizedBox(height: isMobile ? 2 : 4),
                    Text(
                      widget.benefit!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CRMTypography.benefit.copyWith(
                        color: CRMColors.textMutedOf(context),
                        fontSize: isMobile ? 10 : 11,
                      ),
                    ),
                  ],
                  if (showGrowth || widget.lastUpdated != null) ...[
                    SizedBox(height: isMobile ? CRMSpacing.xxs : CRMSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (showGrowth)
                          Row(
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                color: isPositive
                                    ? CRMColors.success
                                    : CRMColors.danger,
                                size: isMobile ? 12 : 14,
                              ),
                              const SizedBox(width: CRMSpacing.xxs),
                              Text(
                                '${isPositive ? "+" : ""}${widget.growthPercent!.toStringAsFixed(1)}%',
                                style: (isMobile
                                        ? CRMTypography.captionBold
                                            .copyWith(fontSize: 10)
                                        : CRMTypography.captionBold)
                                    .copyWith(
                                  color: isPositive
                                      ? CRMColors.success
                                      : CRMColors.danger,
                                ),
                              ),
                            ],
                          ),
                        if (widget.lastUpdated != null)
                          Text(
                            widget.lastUpdated!,
                            style: (isMobile
                                    ? CRMTypography.caption
                                        .copyWith(fontSize: 10)
                                    : CRMTypography.caption)
                                .copyWith(
                                    color: CRMColors.textMutedOf(context)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
