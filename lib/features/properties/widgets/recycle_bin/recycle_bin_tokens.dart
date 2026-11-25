import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/app_colors.dart';

/// Page-local tokens for the New_UI Recycle Bin (emerald system from HTML prototype).
class RbTokens {
  RbTokens._();

  static const Color green = Color(0xFF047857);
  static const Color greenDeep = Color(0xFF065F46);
  static const Color greenLine = Color(0xFFA7F3D0);
  static const Color greenBg = Color(0xFFECFDF5);
  static const Color greenSoft = Color(0xFFF0FDF9);

  static const Color red = Color(0xFFDC2626);
  static const Color redDeep = Color(0xFF991B1B);
  static const Color redText = Color(0xFFB91C1C);
  static const Color redLine = Color(0xFFFECACA);
  static const Color redBg = Color(0xFFFEF2F2);

  static const Color amber = Color(0xFFD97706);
  static const Color amberBg = Color(0xFFFFFBEB);
  static const Color violet = Color(0xFF7C3AED);
  static const Color violetBg = Color(0xFFF5F3FF);

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
  static Color greenLineOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF1F6B4F) : greenLine;
  static Color greenTextOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF6EE7B7) : green;
  static Color greenDeepOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFFA7F3D0) : greenDeep;

  static Color redBgOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF3A1D1D) : redBg;
  static Color redLineOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF7F1D1D) : redLine;
}
