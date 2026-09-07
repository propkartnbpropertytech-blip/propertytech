import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/app_blur.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';



/// Builds full light/dark [ThemeData] with PropKart tokens.
class PropKartTheme {
  static String? get _fontFamily {
    if (kIsWeb) return 'DM Sans';
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return null;
    }
    return 'DM Sans';
  }

  static TextTheme _textTheme(PropKartColors c) {
    TextStyle style(TextStyle s) => s.copyWith(color: c.text);
    final base = TextTheme(
      displayLarge: style(CRMTypography.largeDisplay),
      displayMedium: style(CRMTypography.largeTitle),
      displaySmall: style(CRMTypography.display),
      headlineLarge: style(CRMTypography.title),
      headlineMedium: style(CRMTypography.pageTitle),
      headlineSmall: style(CRMTypography.headline),
      titleLarge: style(CRMTypography.sectionTitle),
      titleMedium: style(CRMTypography.cardTitle),
      titleSmall: style(CRMTypography.navigationTitle),
      bodyLarge: style(CRMTypography.body),
      bodyMedium: style(CRMTypography.subheadline),
      bodySmall: style(CRMTypography.caption),
      labelLarge: style(CRMTypography.button),
      labelMedium: style(CRMTypography.label),
      labelSmall: style(CRMTypography.footnote),
    );
    if (_fontFamily == 'DM Sans') {
      return GoogleFonts.dmSansTextTheme(base);
    }
    return base;
  }

  static ThemeData light() => _build(Brightness.light, PropKartColors.light());
  static ThemeData dark() => _build(Brightness.dark, PropKartColors.dark());

  static ThemeData _build(Brightness brightness, PropKartColors colors) {
    // fromSeed fills every Material 3 role (avoids null.withOpacity crashes on web).
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
    ).copyWith(
      primary: colors.primary,
      onPrimary: Colors.white,
      secondary: colors.secondary,
      onSecondary: colors.text,
      error: colors.danger,
      onError: Colors.white,
      surface: colors.surface,
      onSurface: colors.text,
      onSurfaceVariant: colors.textSecondary,
      surfaceContainerHighest: colors.surfaceElevated,
      surfaceContainerHigh: colors.surfaceElevated,
      surfaceContainer: colors.surface,
      surfaceContainerLow: colors.groupedBackground,
      surfaceContainerLowest: colors.background,
      outline: colors.border,
      outlineVariant: colors.divider,
      shadow: colors.shadow,
      scrim: colors.overlay,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: _fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.divider,
      extensions: [colors],
      textTheme: _textTheme(colors),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        titleTextStyle: CRMTypography.navigationTitle.copyWith(color: colors.text),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
          side: BorderSide(color: colors.border, width: 1.0),
        ),
        shadowColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
          side: BorderSide(color: colors.border, width: 1.0),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(CRMBorderRadius.sheet)),
        ),
        showDragHandle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CRMSpacing.s,
          vertical: CRMSpacing.s,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          borderSide: BorderSide(color: CRMColors.inputBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          borderSide: BorderSide(color: CRMColors.inputBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          borderSide: BorderSide(color: colors.danger, width: 1.0),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceElevated,
        contentTextStyle: CRMTypography.body.copyWith(color: colors.text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.button),
          side: BorderSide(color: colors.border, width: 1.0),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          border: Border.all(color: colors.border, width: 1.0),
        ),
        textStyle: CRMTypography.caption.copyWith(color: colors.text),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.button),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1.0,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.textSecondary,
        textColor: colors.text,
        contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
      ),
    );
  }

  // Re-export motion/blur for convenience
  static const blur = CRMBlur;
  static const motion = CRMMotion;
}
