import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/app_colors.dart';

/// New_UI Support page tokens (emerald system from HTML prototype).
class SuTokens {
  SuTokens._();

  static const Color green = Color(0xFF047857);
  static const Color green2 = Color(0xFF10B981);
  static const Color greenBg = Color(0xFFECFDF5);
  static const Color greenLine = Color(0xFFA7F3D0);
  static const Color blue = Color(0xFF1D4ED8);
  static const Color blueBg = Color(0xFFEFF6FF);
  static const Color amber = Color(0xFFD97706);
  static const Color amberBg = Color(0xFFFFFBEB);
  static const Color red = Color(0xFFDC2626);
  static const Color whatsappBg = Color(0xFFDCFCE7);
  static const Color whatsappFg = Color(0xFF15803D);
  static const Color callBg = Color(0xFFEFF6FF);
  static const Color callFg = Color(0xFF1D4ED8);
  static const Color emailBg = Color(0xFFFEF3C7);
  static const Color emailFg = Color(0xFFB45309);

  static Color panel(BuildContext context) => CRMColors.cardBgOf(context);
  static Color ink(BuildContext context) => CRMColors.textOf(context);
  static Color ink2(BuildContext context) => CRMColors.textSecondaryOf(context);
  static Color muted(BuildContext context) => CRMColors.textMutedOf(context);
  static Color line(BuildContext context) => CRMColors.borderOf(context);
  static Color soft(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF243044) : const Color(0xFFF3F4F6);
  static Color pageBg(BuildContext context) => CRMColors.backgroundOf(context);

  static Color greenBgOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF0F2E24) : greenBg;
  static Color greenLineOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF1F6B4F) : greenLine;
  static Color greenTextOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF6EE7B7) : green;
}
