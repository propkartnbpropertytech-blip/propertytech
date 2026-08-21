import 'package:flutter/material.dart';

import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_motion.dart';
import '../design_system/tokens/app_shadows.dart';
import '../design_system/tokens/app_spacing.dart';
import '../design_system/tokens/app_typography.dart';

/// @Deprecated — facade over CRM tokens. Prefer CRM* / PropKartTheme.
class AppSpacing {
  static const double xs = CRMSpacing.xxs; // 4
  static const double s = CRMSpacing.xs; // 8
  static const double sm = CRMSpacing.s; // 12
  static const double m = CRMSpacing.m; // 16
  static const double ml = CRMSpacing.md; // 20
  static const double l = CRMSpacing.l; // 24
  static const double xl = CRMSpacing.xl; // 32
  static const double xxl = CRMSpacing.xxl; // 40
  static const double xxxl = CRMSpacing.xxxl; // 48
  static const double max = CRMSpacing.max; // 64
}

/// @Deprecated — facade over CRMColors. Prefer CRMColors / PropKartColors.
class AppColors {
  /// Legacy name — now maps to champagne gold brand primary.
  static Color get brandGreen => CRMColors.primary;
  static Color get brandGreenHighlight => CRMColors.accent;
  static Color get darkBg => CRMColors.isDark
      ? const Color(0xFF070B14)
      : const Color(0xFF0B1220);
  static Color get darkSlate => CRMColors.isDark
      ? const Color(0xFF121A2A)
      : const Color(0xFF141B2D);
  static const Color textLight = Colors.white;
  static Color get textMuted => CRMColors.textMuted;
  static Color get textDark => CRMColors.text;
  static Color get borderLight => CRMColors.divider;
  static Color get inputBorder => CRMColors.border;
  static Color get cardBg => CRMColors.cardBg;
  static Color get inputBg => CRMColors.groupedBackground;
  static const Color success = CRMColors.success;
  static const Color warning = CRMColors.warning;
  static const Color error = CRMColors.danger;
}

/// @Deprecated — facade over CRMBorderRadius.
class AppBorderRadius {
  static const double card = CRMBorderRadius.card;
  static const double button = CRMBorderRadius.xxl;
  static const double input = CRMBorderRadius.l;
  static const double tag = CRMBorderRadius.ml;
}

/// @Deprecated — facade over CRMShadows.
class AppShadows {
  static List<BoxShadow> get premiumCard => CRMShadows.large;
  static List<BoxShadow> get premiumButton => CRMShadows.primaryGlow;
}

/// @Deprecated — facade over CRMTypography.
class AppTextStyles {
  static TextStyle get display => CRMTypography.largeDisplay;
  static TextStyle get headline => CRMTypography.pageTitle;
  static TextStyle get title => CRMTypography.sectionTitle;
  static TextStyle get body => CRMTypography.body;
  static TextStyle get caption => CRMTypography.captionBold;
}

// Reusable premium gradient button
class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double width;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: CRMMotion.press,
      curve: CRMMotion.easeOut,
      child: SizedBox(
        width: widget.width,
        height: 56,
        child: Listener(
          onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CRMBorderRadius.xxl),
              boxShadow: enabled ? CRMShadows.primaryGlow : null,
            ),
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: CRMColors.primary.withOpacity(0.5),
                padding: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CRMBorderRadius.xxl),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: enabled
                        ? [CRMColors.accent, CRMColors.primary]
                        : [CRMColors.primary.withOpacity(0.5), CRMColors.primary.withOpacity(0.5)],
                  ),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.xxl),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          widget.label,
                          style: CRMTypography.button.copyWith(
                            fontSize: 16,
                            letterSpacing: 0.3,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable premium input field
class PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.autofillHints,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: CRMTypography.label.copyWith(color: CRMColors.textMutedOf(context)),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Icon(
            prefixIcon,
            color: CRMColors.primaryOf(context),
            size: 22,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 50,
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        filled: true,
        fillColor: CRMColors.groupedBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          borderSide: BorderSide(color: CRMColors.borderOf(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          borderSide: BorderSide(color: CRMColors.borderOf(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          borderSide: const BorderSide(color: CRMColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          borderSide: const BorderSide(color: CRMColors.danger, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}