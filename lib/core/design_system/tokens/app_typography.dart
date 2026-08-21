import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:ui' as ui;

/// PropKart typography — DM Sans for UI chrome, Playfair Display for brand moments.
class CRMTypography {
  static bool get _useSystemSf {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static String? get fontFamily => _useSystemSf ? null : 'DM Sans';

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    double height = 1.3,
    double letterSpacing = 0,
    Color? color,
  }) {
    if (_useSystemSf) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    }
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle _display({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    double height = 1.15,
    double letterSpacing = -0.4,
    Color? color,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// Brand wordmark / greeting name / clock display.
  static TextStyle get brandMark => _display(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      );

  static TextStyle get greetingName => _display(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle get clockDisplay => _base(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ).copyWith(
        fontFeatures: const [ui.FontFeature.tabularFigures()],
      );

  static TextStyle get largeDisplay => _base(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        height: 1.15,
        letterSpacing: -1.0,
      );

  static TextStyle get largeTitle => _base(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        height: 1.18,
        letterSpacing: -0.8,
      );

  static TextStyle get display => _base(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1.2,
        letterSpacing: -0.8,
      );

  static TextStyle get title => _base(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.2,
        letterSpacing: -0.6,
      );

  static TextStyle get pageTitle => _base(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.25,
        letterSpacing: -0.5,
      );

  static TextStyle get navigationTitle => _base(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.2,
      );

  static TextStyle get headline => _base(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.3,
      );

  static TextStyle get sectionTitle => _base(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.3,
      );

  static TextStyle get sectionHeader => _base(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.2,
      );

  static TextStyle get cardTitle => _base(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get body => _base(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        height: 1.45,
      );

  static TextStyle get bodyMedium => _base(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.45,
      );

  static TextStyle get subheadline => _base(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.4,
      );

  static TextStyle get label => _base(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.35,
      );

  static TextStyle get footnote => _base(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        height: 1.35,
      );

  static TextStyle get caption => _base(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        height: 1.4,
      );

  static TextStyle get captionBold => _base(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get button => _base(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get statistics => _base(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.15,
        letterSpacing: -0.6,
      );

  static TextStyle get benefit => _base(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
        letterSpacing: 0.1,
      );

  static TextStyle get chartLabel => _base(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  static TextStyle get tableHeader => _base(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.2,
      );
}
