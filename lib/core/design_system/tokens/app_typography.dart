import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:ui' as ui;

/// PropKart typography — Single unified DM Sans font across entire UI chrome.
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
    double height = 1.35,
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

  /// Brand wordmark / greeting name
  static TextStyle get brandMark => _base(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      );

  static TextStyle get greetingName => _base(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      );

  static TextStyle get clockDisplay => _base(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ).copyWith(
        fontFeatures: const [ui.FontFeature.tabularFigures()],
      );

  static TextStyle get largeDisplay => _base(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get largeTitle => _base(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get display => _base(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.4,
      );

  static TextStyle get title => _base(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.3,
      );

  static TextStyle get pageTitle => _base(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get navigationTitle => _base(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.2,
      );

  static TextStyle get headline => _base(
        fontSize: 18,
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
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.2,
      );

  static TextStyle get cardTitle => _base(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get body => _base(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.45,
      );

  static TextStyle get bodyMedium => _base(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
      );

  static TextStyle get subheadline => _base(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        height: 1.4,
      );

  static TextStyle get label => _base(
        fontSize: 12,
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
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );

  static TextStyle get statistics => _base(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.6,
      );

  static TextStyle get heroStatistic => _base(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.8,
      );

  static TextStyle get benefit => _base(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
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

  static TextStyle get tableCell => _base(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        height: 1.35,
      );
}
