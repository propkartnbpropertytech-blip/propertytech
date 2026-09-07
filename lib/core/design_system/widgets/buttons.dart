import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
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
  final double? borderRadius;

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
    this.borderRadius,
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

    switch (widget.variant) {
      case CRMButtonVariant.primary:
        bgColor = widget.backgroundColor ?? CRMColors.primaryOf(context);
        fgColor = widget.foregroundColor ?? Colors.white;
        borderSide = BorderSide.none;
        break;
      case CRMButtonVariant.secondary:
        bgColor = CRMColors.groupedBackground;
        fgColor = CRMColors.textOf(context);
        borderSide = BorderSide(color: CRMColors.borderOf(context), width: 1);
        break;
      case CRMButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = CRMColors.textSecondaryOf(context);
        borderSide = BorderSide(color: CRMColors.borderOf(context), width: 1);
        break;
      case CRMButtonVariant.danger:
        bgColor = CRMColors.danger;
        fgColor = Colors.white;
        borderSide = BorderSide.none;
        break;
    }

    if (widget.onPressed == null) {
      bgColor = bgColor.withValues(alpha: 0.45);
      fgColor = fgColor.withValues(alpha: 0.55);
    }

    final h = widget.height ?? 40.0;
    final compact = h < 36;

    final labelText = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CRMTypography.button.copyWith(
        color: fgColor,
        fontSize: compact ? 12 : (h >= 48 ? 14 : 13),
        fontWeight: h >= 48 ? FontWeight.w600 : FontWeight.w500,
      ),
    );

    Widget content = Row(
      mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: CRMSpacing.xs),
        ] else if (widget.prefixIcon != null) ...[
          Icon(widget.prefixIcon, size: compact ? 14 : 16, color: fgColor),
          const SizedBox(width: CRMSpacing.xs),
        ],
        if (widget.width != null) Flexible(child: labelText) else labelText,
      ],
    );

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
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
          child: OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              disabledBackgroundColor: bgColor,
              disabledForegroundColor: fgColor,
              overlayColor: Colors.black.withValues(alpha: 0.08),
              side: borderSide,
              elevation: 0,
              padding: widget.padding ??
                  EdgeInsets.symmetric(
                    horizontal: compact ? CRMSpacing.s : CRMSpacing.m,
                  ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? CRMBorderRadius.button,
                ),
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
