import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/app_colors.dart';

/// Page-local tokens for the New_UI Employees list (employees.html).
class EmTokens {
  EmTokens._();

  static const Color green = Color(0xFF047857);
  static const Color greenBright = Color(0xFF10B981);
  static const Color greenSoft = Color(0xFFF0FDF9);
  static const Color violet = Color(0xFF7C3AED);
  static const Color violetBg = Color(0xFFF5F3FF);
  static const Color red = Color(0xFFEF4444);
  static const Color redText = Color(0xFFDC2626);
  static const Color amber = Color(0xFFD97706);
  static const Color amberBg = Color(0xFFFFFBEB);
  static const Color amberLine = Color(0xFFFDE68A);
  static const Color amberInk = Color(0xFF92400E);
  static const Color amberDeep = Color(0xFF78350F);
  static const Color gray = Color(0xFF6B7280);

  static Color panelBg(BuildContext context) => CRMColors.cardBgOf(context);
  static Color pageBg(BuildContext context) => CRMColors.backgroundOf(context);
  static Color ink(BuildContext context) => CRMColors.textOf(context);
  static Color ink2(BuildContext context) => CRMColors.textSecondaryOf(context);
  static Color muted(BuildContext context) => CRMColors.textMutedOf(context);
  static Color line(BuildContext context) => CRMColors.borderOf(context);
  static Color soft(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF243044) : const Color(0xFFF3F4F6);

  static Color roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'sales':
        return green;
      case 'telecaller':
        return violet;
      case 'admin':
      case 'super admin':
        return red;
      default:
        return gray;
    }
  }

  static Color roleBg(String role) {
    switch (role.toLowerCase()) {
      case 'sales':
        return const Color(0xFFECFDF5);
      case 'telecaller':
        return violetBg;
      case 'admin':
      case 'super admin':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }
}
