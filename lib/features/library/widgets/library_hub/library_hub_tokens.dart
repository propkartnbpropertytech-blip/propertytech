import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/app_colors.dart';

/// Page-local tokens for the New_UI Library hub (library.html).
class LibTokens {
  LibTokens._();

  static const Color green = Color(0xFF047857);
  static const Color green2 = Color(0xFF10B981);
  static const Color greenBg = Color(0xFFECFDF5);
  static const Color amber = Color(0xFFB45309);
  static const Color amberBg = Color(0xFFFFFBEB);

  static Color panelBg(BuildContext context) => CRMColors.cardBgOf(context);
  static Color pageBg(BuildContext context) => CRMColors.backgroundOf(context);
  static Color ink(BuildContext context) => CRMColors.textOf(context);
  static Color ink2(BuildContext context) => CRMColors.textSecondaryOf(context);
  static Color muted(BuildContext context) => CRMColors.textMutedOf(context);
  static Color line(BuildContext context) => CRMColors.borderOf(context);
  static Color soft(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF243044) : const Color(0xFFF3F4F6);

  static Color greenBgOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF0F2E24) : greenBg;
  static Color greenTextOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF6EE7B7) : green;
}
