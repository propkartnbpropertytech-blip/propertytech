import 'package:flutter/material.dart';
import 'app_colors.dart';

class CRMShadows {
  static Color _softBlack(double alpha) =>
      Colors.black.withValues(alpha: alpha);

  static List<BoxShadow> get soft => small;

  static List<BoxShadow> get small => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.25 : 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.30 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get large => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.35 : 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.40 : 0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get glass => small;

  static List<BoxShadow> get modal => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.50 : 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get primaryGlow => small;

  static List<BoxShadow> atmosphereGlow(Color accent) => small;
}
