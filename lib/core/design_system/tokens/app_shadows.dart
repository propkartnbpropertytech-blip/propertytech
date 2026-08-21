import 'package:flutter/material.dart';
import 'app_colors.dart';

class CRMShadows {
  static Color _softBlack(double alpha) =>
      Colors.black.withValues(alpha: alpha);

  static Color _primaryGlow(double alpha) =>
      CRMColors.primary.withValues(alpha: alpha);

  static List<BoxShadow> get soft => small;

  static List<BoxShadow> get small => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.4 : 0.05),
          blurRadius: CRMColors.isDark ? 14 : 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.18 : 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.45 : 0.07),
          blurRadius: CRMColors.isDark ? 22 : 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.22 : 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get large => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.5 : 0.09),
          blurRadius: 36,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.22 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.55 : 0.12),
          blurRadius: 44,
          offset: const Offset(0, 18),
        ),
      ];

  static List<BoxShadow> get glass => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.35 : 0.04),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get modal => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.6 : 0.16),
          blurRadius: 52,
          offset: const Offset(0, 24),
        ),
      ];

  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: _primaryGlow(CRMColors.isDark ? (CRMColors.isRentMode ? 0.20 : 0.18) : 0.22),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> atmosphereGlow(Color accent) => [
        BoxShadow(
          color: accent.withValues(alpha: CRMColors.isDark ? (CRMColors.isRentMode ? 0.20 : 0.18) : 0.16),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
