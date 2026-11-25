import 'package:flutter/material.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../library_hub/library_hub_tokens.dart';

export '../library_hub/library_hub_tokens.dart';

/// Page-local tokens for the New_UI Library vault screens (library-vault.html).
///
/// Extends [LibTokens] (emerald palette shared with the hub) with the red /
/// blue / amber tones used by status pills and file badges.
class LvTokens {
  LvTokens._();

  static const Color green = LibTokens.green;
  static const Color green2 = LibTokens.green2;

  static const Color red = Color(0xFFDC2626);
  static const Color redBg = Color(0xFFFEF2F2);
  static const Color blue = Color(0xFF1D4ED8);
  static const Color blueBg = Color(0xFFEFF6FF);
  static const Color amber = LibTokens.amber;
  static const Color amberBg = LibTokens.amberBg;

  static Color redBgOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF3A1A1A) : redBg;
  static Color redTextOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFFFCA5A5) : red;
  static Color blueBgOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF14233F) : blueBg;
  static Color blueTextOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF93C5FD) : blue;
  static Color amberBgOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF3A2A0F) : amberBg;
  static Color amberTextOf(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFFFCD34D) : amber;

  /// Selected vault tab background (HTML `.vtabs a.on` → var(--ink)).
  static Color tabOnBg(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF111827);
  static Color tabOnFg(BuildContext context) =>
      CRMColors.isDark ? const Color(0xFF111827) : Colors.white;

  /// Table header / hovered row background (HTML var(--bg)).
  static Color rowHover(BuildContext context) => LibTokens.pageBg(context);

  static const Duration motion = Duration(milliseconds: 150);
}
