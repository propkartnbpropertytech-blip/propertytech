import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';

/// Semantic color tokens. Prefer [PropKartColors.of] when a [BuildContext] is available.
/// Static getters remain for backward compatibility and rebuild via [ThemeManager].
class CRMColors {
  static bool get isDark => ThemeManager().isDarkMode;

  // ── Core surfaces (premium white) ──────────────────────────
  static Color get background =>
      isDark ? const Color(0xFF1C1A18) : const Color(0xFFFFFFFF);
  static Color get groupedBackground =>
      isDark ? const Color(0xFF2A2623) : const Color(0xFFF4F4F3);
  static Color get cardBg =>
      isDark ? const Color(0xFF24211F) : const Color(0xFFFFFFFF);
  static Color get surface => cardBg;
  static Color get surfaceElevated =>
      isDark ? const Color(0xFF2C2825) : const Color(0xFFFFFFFF);
  static Color get sidebarBg =>
      isDark ? const Color(0xFF1E1B19) : const Color(0xFFFFFFFF);
  static Color get glassSurface =>
      isDark ? const Color(0xFF24211F) : const Color(0xFFFFFFFF);

  // ── Brand / Deep Terracotta & Clay ────────────────────────
  static bool get isRentMode => ThemeManager().isRentMode;

  static Color getPrimaryColor(bool dark, bool rent) {
    return dark ? const Color(0xFFD47A66) : const Color(0xFFC15D4A);
  }

  static Color getPrimaryHoverColor(bool dark, bool rent) {
    return dark ? const Color(0xFFE08B78) : const Color(0xFFA64C3C);
  }

  static Color getSecondaryColor(bool dark, bool rent) {
    return dark ? const Color(0xFF2A2623) : const Color(0xFFF4F4F3);
  }

  static Color getAccentColor(bool dark, bool rent) {
    return dark ? const Color(0xFF3A2824) : const Color(0xFFF6D8D0);
  }

  static List<Color> getGradientPrimaryColor(bool dark, bool rent) {
    return dark
        ? const [Color(0xFFD47A66), Color(0xFFC15D4A)]
        : const [Color(0xFFC15D4A), Color(0xFFA64C3C)];
  }

  static Color get primary => getPrimaryColor(isDark, isRentMode);
  static Color get primaryHover => getPrimaryHoverColor(isDark, isRentMode);
  static Color get secondary => getSecondaryColor(isDark, isRentMode);
  static Color get accent => getAccentColor(isDark, isRentMode);

  // ── Palette Specific Constants ─────────────────────────────
  // Terracotta / Clay
  static const Color terracotta = Color(0xFFC15D4A);
  static const Color terracottaHover = Color(0xFFA64C3C);
  static const Color terracottaPressed = Color(0xFF8E4033);
  static const Color terracottaSoft = Color(0xFFF6D8D0);
  static const Color terracottaDark = Color(0xFFD47A66);

  // Garden Sage
  static const Color sage = Color(0xFF5F8064);
  static const Color sageDark = Color(0xFF4E6B53);
  static const Color sageSoft = Color(0xFFD7E8D8);
  static const Color sageLightDark = Color(0xFF8FB392);

  // Warm Rose
  static const Color rose = Color(0xFFC97870);
  static const Color roseSoft = Color(0xFFF8DCD8);

  // Deep Plum
  static const Color plum = Color(0xFF6A454C);
  static const Color plumSoft = Color(0xFFF0E2E6);

  // Warm Sand
  static const Color sand = Color(0xFFC4924A);
  static const Color sandSoft = Color(0xFFF6E4C8);

  /// Domain specific accents
  /// Rent uses charcoal so it sits with the canvas; Re-Sale keeps terracotta.
  static Color get rentAccent =>
      isDark ? const Color(0xFFE8E4DF) : const Color(0xFF1A1A1A);

  static Color get resaleAccent =>
      isDark ? const Color(0xFFD47A66) : const Color(0xFFC15D4A);

  static Color atmosphereAccent(bool isRent) =>
      isRent ? rentAccent : resaleAccent;

  static Color onAtmosphereAccent(bool isRent) {
    if (!isRent) return const Color(0xFFFFFFFF);
    return isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
  }

  static List<Color> atmosphereGradient(bool isRent) => isDark
      ? (isRent
          ? const [Color(0xFFE8E4DF), Color(0xFFD4CFC8)]
          : const [Color(0xFFD47A66), Color(0xFFC15D4A)])
      : (isRent
          ? const [Color(0xFF1A1A1A), Color(0xFF2C2C2C)]
          : const [Color(0xFFC15D4A), Color(0xFFA64C3C)]);

  // Sidebar styling
  static Color get sidebarText =>
      isDark ? const Color(0xFFF4F4F3) : const Color(0xFF1A1A1A);
  static Color get sidebarTextSecondary =>
      isDark ? const Color(0xFFB9B0A7) : const Color(0xFF5C5C5C);
  static Color get sidebarBorder =>
      isDark ? const Color(0xFF3A3531) : const Color(0xFFE8E8E6);

  // ── Borders / dividers ─────────────────────────────────────
  static Color get border =>
      isDark ? const Color(0xFF3A3531) : const Color(0xFFE8E8E6);
  static Color get strongBorder =>
      isDark ? const Color(0xFF4A433E) : const Color(0xFFD8D8D6);
  static Color get inputBorder =>
      isDark ? const Color(0xFF4A433E) : const Color(0xFFE2E2E0);
  static Color get divider =>
      isDark ? const Color(0xFF322E2A) : const Color(0xFFF0F0EE);

  // ── Strong ink cards (charcoal) ────────────────────────────
  static Color get strongCard =>
      isDark ? const Color(0xFF2C2825) : const Color(0xFF1A1A1A);
  static Color get onStrong =>
      isDark ? const Color(0xFFF4F4F3) : const Color(0xFFFFFFFF);

  // ── KPI fills — white on white canvas, hairline only ───────
  static Color get kpiCream => cardBg;
  static Color get kpiSage => cardBg;
  static Color get kpiSand => cardBg;
  static Color get kpiTerracotta => cardBg;
  static Color get kpiRose => cardBg;
  static Color get kpiPlum => cardBg;
  static Color get kpiClay => cardBg;

  static Color kpiTintFor(Color accent) => cardBg;

  // ── Text — charcoal, not warm brown ────────────────────────
  static Color get text =>
      isDark ? const Color(0xFFF4F4F3) : const Color(0xFF1A1A1A);
  static Color get textSecondary =>
      isDark ? const Color(0xFFB9B0A7) : const Color(0xFF5C5C5C);
  static Color get textMuted =>
      isDark ? const Color(0xFF7D766F) : const Color(0xFF8C8C8C);

  // ── Semantic (Warm, compatible with brand) ──────────────────
  static const Color success = Color(0xFF5F8064);
  static const Color successBg = Color(0xFFD7E8D8);
  static const Color warning = Color(0xFFC4924A);
  static const Color warningBg = Color(0xFFF6E4C8);
  static const Color danger = Color(0xFFC15D4A);
  static const Color dangerBg = Color(0xFFF6D8D0);
  static const Color info = Color(0xFF647B7A);
  static const Color infoBg = Color(0xFFE9EFEE);

  static Color get disabled =>
      isDark ? const Color(0xFF423C37) : const Color(0xFFE5E5E4);
  static Color get overlay =>
      isDark ? const Color(0x99000000) : const Color(0x66000000);
  static Color get shadow =>
      isDark ? const Color(0x40000000) : const Color(0x0A000000);

  // ── Chart / graph ──────────────────────────────────────────
  static List<Color> get chartColors => isDark
      ? const [
          Color(0xFFD47A66),
          Color(0xFF8FB392),
          Color(0xFFD4A45E),
          Color(0xFFD48B84),
          Color(0xFF7A9B8A),
          Color(0xFF8A6068),
        ]
      : const [
          Color(0xFF1A1A1A),
          Color(0xFFC15D4A),
          Color(0xFF8C8C8C),
          Color(0xFFA64C3C),
          Color(0xFF5C5C5C),
          Color(0xFFD47A66),
        ];

  static List<Color> get graphColors => chartColors;

  static List<Color> get gradientPrimary => getGradientPrimaryColor(isDark, isRentMode);

  static Color get skeletonBase =>
      isDark ? const Color(0xFF282522) : const Color(0xFFF2F2F1);
  static Color get skeletonHighlight =>
      isDark ? const Color(0xFF332E2A) : const Color(0xFFFFFFFF);

  // ── Context-aware (ThemeExtension when available) ──────────
  static Color backgroundOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.background ?? background;
  static Color cardBgOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.surface ?? cardBg;
  static Color sidebarBgOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.sidebarBg ?? sidebarBg;
  static Color primaryOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.primary ?? primary;
  static Color primaryHoverOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.primaryHover ?? primaryHover;
  static Color borderOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.border ?? border;
  static Color textOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.text ?? text;
  static Color textSecondaryOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.textSecondary ?? textSecondary;
  static Color textMutedOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.textMuted ?? textMuted;
  static Color surfaceElevatedOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.surfaceElevated ?? surfaceElevated;
  static Color glassOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.glassSurface ?? glassSurface;
  static Color overlayOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.overlay ?? overlay;
  static Color secondaryOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.secondary ?? secondary;
  static Color accentOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.accent ?? accent;
  static Color strongCardOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2C2825)
          : const Color(0xFF1A1A1A);
  static Color onStrongOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFF4F4F3)
          : const Color(0xFFFFFFFF);
}

/// ThemeExtension carrying PropKart semantic colors for light/dark.
@immutable
class PropKartColors extends ThemeExtension<PropKartColors> {
  final Color background;
  final Color groupedBackground;
  final Color surface;
  final Color surfaceElevated;
  final Color sidebarBg;
  final Color glassSurface;
  final Color primary;
  final Color primaryHover;
  final Color secondary;
  final Color accent;
  final Color rentAccent;
  final Color resaleAccent;
  final Color border;
  final Color divider;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color disabled;
  final Color overlay;
  final Color shadow;
  final Color skeletonBase;
  final Color skeletonHighlight;
  final List<Color> chartColors;
  final List<Color> gradientPrimary;

  const PropKartColors({
    required this.background,
    required this.groupedBackground,
    required this.surface,
    required this.surfaceElevated,
    required this.sidebarBg,
    required this.glassSurface,
    required this.primary,
    required this.primaryHover,
    required this.secondary,
    required this.accent,
    required this.rentAccent,
    required this.resaleAccent,
    required this.border,
    required this.divider,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.disabled,
    required this.overlay,
    required this.shadow,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.chartColors,
    required this.gradientPrimary,
  });

  static PropKartColors light() {
    final rent = ThemeManager().isRentMode;
    return PropKartColors(
      background: const Color(0xFFFFFFFF),
      groupedBackground: const Color(0xFFF4F4F3),
      surface: const Color(0xFFFFFFFF),
      surfaceElevated: const Color(0xFFFFFFFF),
      sidebarBg: const Color(0xFFFFFFFF),
      glassSurface: const Color(0xFFFFFFFF),
      primary: CRMColors.getPrimaryColor(false, rent),
      primaryHover: CRMColors.getPrimaryHoverColor(false, rent),
      secondary: CRMColors.getSecondaryColor(false, rent),
      accent: CRMColors.getAccentColor(false, rent),
      rentAccent: const Color(0xFF1A1A1A),
      resaleAccent: const Color(0xFFC15D4A),
      border: const Color(0xFFE8E8E6),
      divider: const Color(0xFFF0F0EE),
      text: const Color(0xFF1A1A1A),
      textSecondary: const Color(0xFF5C5C5C),
      textMuted: const Color(0xFF8C8C8C),
      success: CRMColors.success,
      warning: CRMColors.warning,
      danger: CRMColors.danger,
      info: CRMColors.info,
      disabled: const Color(0xFFE5E5E4),
      overlay: const Color(0x66000000),
      shadow: const Color(0x0A000000),
      skeletonBase: const Color(0xFFF2F2F1),
      skeletonHighlight: const Color(0xFFFFFFFF),
      chartColors: const [
        Color(0xFF1A1A1A),
        Color(0xFFC15D4A),
        Color(0xFF8C8C8C),
        Color(0xFFA64C3C),
        Color(0xFF5C5C5C),
        Color(0xFFD47A66),
      ],
      gradientPrimary: CRMColors.getGradientPrimaryColor(false, rent),
    );
  }

  static PropKartColors dark() {
    final rent = ThemeManager().isRentMode;
    return PropKartColors(
      background: const Color(0xFF1C1A18),
      groupedBackground: const Color(0xFF2A2623),
      surface: const Color(0xFF24211F),
      surfaceElevated: const Color(0xFF2C2825),
      sidebarBg: const Color(0xFF1E1B19),
      glassSurface: const Color(0xFF24211F),
      primary: CRMColors.getPrimaryColor(true, rent),
      primaryHover: CRMColors.getPrimaryHoverColor(true, rent),
      secondary: CRMColors.getSecondaryColor(true, rent),
      accent: CRMColors.getAccentColor(true, rent),
      rentAccent: const Color(0xFFE8E4DF),
      resaleAccent: const Color(0xFFD47A66),
      border: const Color(0xFF3A3531),
      divider: const Color(0xFF322E2A),
      text: const Color(0xFFF3EEE7),
      textSecondary: const Color(0xFFB9B0A7),
      textMuted: const Color(0xFF7D766F),
      success: const Color(0xFF86A58C),
      warning: const Color(0xFFC99E6E),
      danger: const Color(0xFFC47C78),
      info: const Color(0xFF839B9A),
      disabled: const Color(0xFF423C37),
      overlay: const Color(0x99000000),
      shadow: const Color(0x40000000),
      skeletonBase: const Color(0xFF282522),
      skeletonHighlight: const Color(0xFF332E2A),
      chartColors: const [
        Color(0xFFD47A66),
        Color(0xFF8FB392),
        Color(0xFFD4A45E),
        Color(0xFFD48B84),
        Color(0xFF7A9B8A),
        Color(0xFF8A6068),
      ],
      gradientPrimary: CRMColors.getGradientPrimaryColor(true, rent),
    );
  }

  static PropKartColors of(BuildContext context) {
    final ext = Theme.of(context).extension<PropKartColors>();
    assert(ext != null, 'PropKartColors not found in Theme');
    return ext ??
        (Theme.of(context).brightness == Brightness.dark ? dark() : light());
  }

  static PropKartColors? maybeOf(BuildContext context) =>
      Theme.of(context).extension<PropKartColors>();

  @override
  PropKartColors copyWith({
    Color? background,
    Color? groupedBackground,
    Color? surface,
    Color? surfaceElevated,
    Color? sidebarBg,
    Color? glassSurface,
    Color? primary,
    Color? primaryHover,
    Color? secondary,
    Color? accent,
    Color? rentAccent,
    Color? resaleAccent,
    Color? border,
    Color? divider,
    Color? text,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? disabled,
    Color? overlay,
    Color? shadow,
    Color? skeletonBase,
    Color? skeletonHighlight,
    List<Color>? chartColors,
    List<Color>? gradientPrimary,
  }) {
    return PropKartColors(
      background: background ?? this.background,
      groupedBackground: groupedBackground ?? this.groupedBackground,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      sidebarBg: sidebarBg ?? this.sidebarBg,
      glassSurface: glassSurface ?? this.glassSurface,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      rentAccent: rentAccent ?? this.rentAccent,
      resaleAccent: resaleAccent ?? this.resaleAccent,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      disabled: disabled ?? this.disabled,
      overlay: overlay ?? this.overlay,
      shadow: shadow ?? this.shadow,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      chartColors: chartColors ?? this.chartColors,
      gradientPrimary: gradientPrimary ?? this.gradientPrimary,
    );
  }

  @override
  PropKartColors lerp(ThemeExtension<PropKartColors>? other, double t) {
    if (other is! PropKartColors) return this;
    Color lerpC(Color a, Color b) => Color.lerp(a, b, t)!;
    return PropKartColors(
      background: lerpC(background, other.background),
      groupedBackground: lerpC(groupedBackground, other.groupedBackground),
      surface: lerpC(surface, other.surface),
      surfaceElevated: lerpC(surfaceElevated, other.surfaceElevated),
      sidebarBg: lerpC(sidebarBg, other.sidebarBg),
      glassSurface: lerpC(glassSurface, other.glassSurface),
      primary: lerpC(primary, other.primary),
      primaryHover: lerpC(primaryHover, other.primaryHover),
      secondary: lerpC(secondary, other.secondary),
      accent: lerpC(accent, other.accent),
      rentAccent: lerpC(rentAccent, other.rentAccent),
      resaleAccent: lerpC(resaleAccent, other.resaleAccent),
      border: lerpC(border, other.border),
      divider: lerpC(divider, other.divider),
      text: lerpC(text, other.text),
      textSecondary: lerpC(textSecondary, other.textSecondary),
      textMuted: lerpC(textMuted, other.textMuted),
      success: lerpC(success, other.success),
      warning: lerpC(warning, other.warning),
      danger: lerpC(danger, other.danger),
      info: lerpC(info, other.info),
      disabled: lerpC(disabled, other.disabled),
      overlay: lerpC(overlay, other.overlay),
      shadow: lerpC(shadow, other.shadow),
      skeletonBase: lerpC(skeletonBase, other.skeletonBase),
      skeletonHighlight: lerpC(skeletonHighlight, other.skeletonHighlight),
      chartColors: t < 0.5 ? chartColors : other.chartColors,
      gradientPrimary: t < 0.5 ? gradientPrimary : other.gradientPrimary,
    );
  }
}
