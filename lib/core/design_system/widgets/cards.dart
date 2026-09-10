import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'buttons.dart';

class CRMCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? headerAction;
  final Widget child;
  final Widget? footer;
  final EdgeInsetsGeometry padding;
  final bool elevated;
  final Color? accentBorder;
  final Color? backgroundColor;
  final Color? borderColor;

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
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: CRMMotion.medium,
      curve: CRMMotion.easeOut,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (elevated
                ? CRMColors.surfaceElevatedOf(context)
                : CRMColors.cardBgOf(context)),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: borderColor ?? accentBorder ?? CRMColors.borderOf(context),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CRMTypography.caption.copyWith(
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
              thickness: 1.0,
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
              thickness: 1.0,
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
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;

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
    this.backgroundColor,
    this.borderColor,
    this.textColor,
  });

  @override
  State<CRMKPICard> createState() => _CRMKPICardState();
}

class _CRMKPICardState extends State<CRMKPICard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final trend = widget.growthPercent;
    final showGrowth = trend != null && trend.abs() >= 0.05 && trend.abs() < 99.5;
    final isPositive = (trend ?? 0.0) >= 0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final lift = _pressed ? 0.98 : 1.0;
    final accent = widget.iconColor ?? CRMColors.terracotta;
    final fill = widget.backgroundColor ?? CRMColors.cardBgOf(context);
    final onFill = ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? CRMColors.onStrong
        : CRMColors.textOf(context);

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
          child: CRMCard(
            elevated: false,
            backgroundColor: fill,
            borderColor: widget.borderColor ?? CRMColors.borderOf(context),
            accentBorder: _hovered ? accent : null,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? CRMSpacing.s : CRMSpacing.m,
              vertical: isMobile ? 12 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CRMTypography.captionBold.copyWith(
                          color: widget.textColor != null
                              ? widget.textColor!.withValues(alpha: 0.8)
                              : (ThemeData.estimateBrightnessForColor(fill) ==
                                      Brightness.dark
                                  ? CRMColors.onStrong.withValues(alpha: 0.7)
                                  : CRMColors.textSecondaryOf(context)),
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: CRMSpacing.xxs),
                    Container(
                      padding: EdgeInsets.all(isMobile ? 6 : 8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.textColor ?? accent,
                        size: isMobile ? 16 : 18,
                      ),
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
                                .copyWith(color: widget.textColor ?? onFill),
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
                              color: widget.iconColor ?? CRMColors.primaryOf(context),
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

class CRMHeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? accentColor;
  final VoidCallback? onTap;

  const CRMHeroMetric({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.backgroundColor,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final bg = backgroundColor ?? CRMColors.strongCard;
    final inverted = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark;
    final onColor = inverted ? CRMColors.onStrong : CRMColors.textOf(context);
    final accent = accentColor ?? CRMColors.terracotta;
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? CRMSpacing.m : CRMSpacing.l),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(CRMBorderRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CRMTypography.captionBold.copyWith(
                        color: inverted
                            ? onColor.withValues(alpha: 0.72)
                            : accent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: CRMSpacing.s),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (inverted ? onColor : accent).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: inverted ? onColor : accent,
                        size: isMobile ? 16 : 18,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: CRMSpacing.s),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: CRMTypography.heroStatistic.copyWith(
                    color: onColor,
                    fontSize: isMobile ? 36 : 44,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CRMTintedMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color? accentColor;
  final VoidCallback? onTap;

  const CRMTintedMetric({
    super.key,
    required this.label,
    required this.value,
    required this.backgroundColor,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 140;
        return MouseRegion(
          cursor: onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? CRMSpacing.s : CRMSpacing.m,
                vertical: compact ? 12 : 14,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                border: Border.all(color: CRMColors.borderOf(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CRMTypography.captionBold.copyWith(
                      color: accentColor ?? CRMColors.textMutedOf(context),
                      fontSize: compact ? 10 : 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: CRMTypography.statistics.copyWith(
                        color: CRMColors.textOf(context),
                        fontSize: compact ? 22 : 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CRMResponsiveKpiRow extends StatelessWidget {
  final List<Widget> children;
  final double minCardWidth;
  final int? maxColumns;

  const CRMResponsiveKpiRow({
    super.key,
    required this.children,
    this.minCardWidth = 160,
    this.maxColumns,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = CRMSpacing.s;
        final maxW = constraints.maxWidth;
        var cols = children.length;
        if (maxW < minCardWidth) {
          cols = 1;
        } else {
          cols = (maxW / (minCardWidth + gap)).floor().clamp(1, children.length);
        }
        if (maxColumns != null) {
          cols = cols.clamp(1, maxColumns!);
        }
        final cardW = cols == 1
            ? maxW
            : (maxW - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: cardW, child: child),
          ],
        );
      },
    );
  }
}

class CRMPriorityActionCard extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final String actionLabel;
  final VoidCallback onAction;
  final Color backgroundColor;
  final Color accentColor;

  const CRMPriorityActionCard({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    required this.actionLabel,
    required this.onAction,
    required this.backgroundColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final inverted =
        ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark;
    final onColor = inverted ? CRMColors.onStrong : CRMColors.textOf(context);
    final muted = inverted
        ? CRMColors.onStrong.withValues(alpha: 0.7)
        : CRMColors.textSecondaryOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CRMSpacing.l),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CRMTypography.captionBold.copyWith(
              color: muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: CRMSpacing.s),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: CRMTypography.heroStatistic.copyWith(
                color: onColor,
                fontSize: 36,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: CRMTypography.body.copyWith(color: muted),
          ),
          const SizedBox(height: CRMSpacing.l),
          CRMButton(
            label: actionLabel,
            onPressed: onAction,
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}

class CRMInventoryBar {
  final String label;
  final int value;
  final Color color;

  const CRMInventoryBar({
    required this.label,
    required this.value,
    required this.color,
  });
}

class CRMInventoryOverview extends StatelessWidget {
  final String title;
  final List<CRMInventoryBar> bars;

  const CRMInventoryOverview({
    super.key,
    required this.title,
    required this.bars,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = bars.fold<int>(0, (m, b) => b.value > m ? b.value : m);
    final safeMax = maxValue == 0 ? 1 : maxValue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CRMSpacing.l),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: CRMTypography.sectionTitle.copyWith(
              color: CRMColors.textOf(context),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: CRMSpacing.l),
          ...bars.map((bar) {
            final fraction = bar.value / safeMax;
            return Padding(
              padding: const EdgeInsets.only(bottom: CRMSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bar.label,
                          style: CRMTypography.captionBold.copyWith(
                            color: CRMColors.textSecondaryOf(context),
                          ),
                        ),
                      ),
                      Text(
                        '${bar.value}',
                        style: CRMTypography.captionBold.copyWith(
                          color: CRMColors.textOf(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(
                              height: 14,
                              width: constraints.maxWidth,
                              color: CRMColors.groupedBackground,
                            ),
                            AnimatedContainer(
                              duration: CRMMotion.medium,
                              height: 14,
                              width: constraints.maxWidth * fraction.clamp(0.04, 1.0),
                              color: bar.color,
                            ),
                          ],
                        );
                      },
                    ),
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
