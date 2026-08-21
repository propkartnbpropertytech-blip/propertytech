import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum CRMButtonVariant { primary, secondary, outline, danger }

class CRMButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final CRMButtonVariant variant;
  final bool isLoading;
  final IconData? prefixIcon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  final Color? backgroundColor;
  final Color? foregroundColor;

  const CRMButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = CRMButtonVariant.primary,
    this.isLoading = false,
    this.prefixIcon,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<CRMButton> createState() => _CRMButtonState();
}

class _CRMButtonState extends State<CRMButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;
    List<BoxShadow>? shadows;

    switch (widget.variant) {
      case CRMButtonVariant.primary:
        bgColor = widget.backgroundColor ?? CRMColors.primaryOf(context);
        fgColor = widget.foregroundColor ??
            ((CRMColors.isDark && !CRMColors.isRentMode)
                ? const Color(0xFF111827)
                : Colors.white);
        shadows = widget.onPressed != null && !widget.isLoading
            ? (widget.backgroundColor != null
                ? [
                    BoxShadow(
                      color: widget.backgroundColor!.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : CRMShadows.primaryGlow)
            : null;
        break;
      case CRMButtonVariant.secondary:
        bgColor = CRMColors.groupedBackground;
        fgColor = CRMColors.textOf(context);
        break;
      case CRMButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = CRMColors.textSecondaryOf(context);
        borderSide = BorderSide(color: CRMColors.borderOf(context), width: 1);
        break;
      case CRMButtonVariant.danger:
        bgColor = CRMColors.danger;
        fgColor = Colors.white;
        break;
    }

    if (widget.onPressed == null) {
      bgColor = bgColor.withValues(alpha: 0.45);
      fgColor = fgColor.withValues(alpha: 0.55);
      shadows = null;
    }

    final h = widget.height ?? 48.0;
    final compact = h < 36;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: CRMSpacing.xs),
        ] else if (widget.prefixIcon != null) ...[
          Icon(widget.prefixIcon, size: compact ? 14 : 18, color: fgColor),
          const SizedBox(width: CRMSpacing.xs),
        ],
        Text(
          widget.label,
          style: CRMTypography.button.copyWith(
            color: fgColor,
            fontSize: compact ? 12 : 15,
          ),
        ),
      ],
    );

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: CRMMotion.press,
      curve: CRMMotion.easeOut,
      child: SizedBox(
        width: widget.width,
        height: h,
        child: Listener(
          onPointerDown: widget.onPressed == null || widget.isLoading
              ? null
              : (_) => setState(() => _pressed = true),
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              boxShadow: shadows,
            ),
            child: OutlinedButton(
              onPressed: widget.isLoading ? null : widget.onPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: fgColor,
                side: borderSide,
                elevation: 0,
                padding: widget.padding ??
                    const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
