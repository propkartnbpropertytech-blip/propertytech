import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/app_typography.dart';

export '../employees_ui/employees_tokens.dart';

/// Colour tones used across the New_UI Employee detail page (employee.html).
enum EvTone { green, red, amber, violet, blue, cyan, gray }

/// Page-local extras for the New_UI Employee detail screen. Base palette and
/// surface helpers come from [EmTokens] (re-exported above).
class EvTokens {
  EvTokens._();

  static const Color blue = Color(0xFF2563EB);
  static const Color cyan = Color(0xFF0891B2);
  static const Color greenHover = Color(0xFF065F46);

  /// Hover / transition duration shared by every interactive surface (150ms).
  static const Duration hover = Duration(milliseconds: 150);

  static const double radiusCard = 14;

  static Color tone(EvTone tone) {
    switch (tone) {
      case EvTone.green:
        return const Color(0xFF047857);
      case EvTone.red:
        return const Color(0xFFDC2626);
      case EvTone.amber:
        return const Color(0xFFD97706);
      case EvTone.violet:
        return const Color(0xFF7C3AED);
      case EvTone.blue:
        return blue;
      case EvTone.cyan:
        return cyan;
      case EvTone.gray:
        return const Color(0xFF6B7280);
    }
  }

  /// Soft tinted background for a tone (works in light and dark themes).
  static Color toneBg(EvTone tone, {double alpha = 0.12}) =>
      EvTokens.tone(tone).withValues(alpha: alpha);

  static EvTone roleTone(String role) {
    switch (role.toLowerCase()) {
      case 'sales':
      case 'salesperson':
        return EvTone.green;
      case 'telecaller':
        return EvTone.violet;
      case 'admin':
      case 'super admin':
        return EvTone.red;
      default:
        return EvTone.gray;
    }
  }

  /// Typography helper that matches the HTML sizes while keeping the app font.
  static TextStyle text({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0,
    double? height,
  }) {
    return CRMTypography.body.copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height ?? 1.3,
    );
  }
}
