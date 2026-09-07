import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';

/// Semantic color tokens. Prefer [PropKartColors.of] when a [BuildContext] is available.
/// Static getters remain for backward compatibility and rebuild via [ThemeManager].
class CRMColors {
  static bool get isDark => ThemeManager().isDarkMode;

  // ── Core surfaces (modern clean SaaS) ──────────────────────
  static Color get background =>
      isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FC);
  static Color get groupedBackground =>
      isDark ? const Color(0xFF0B1120) : const Color(0xFFF7F9FC);
  static Color get cardBg =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  static Color get surface => cardBg;
  static Color get surfaceElevated =>
      isDark ? const Color(0xFF243044) : const Color(0xFFFFFFFF);
  static Color get sidebarBg =>
      isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
  static Color get glassSurface =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);

  // ── Brand / Deep Terracotta & Clay ────────────────────────
  static bool get isRentMode => ThemeManager().isRentMode;

  static Color getPrimaryColor(bool dark, bool rent) {
    final theme = ThemeManager().currentTheme;
    return dark ? theme.primaryDark : theme.primaryLight;
  }

  static Color getPrimaryHoverColor(bool dark, bool rent) {
    final theme = ThemeManager().currentTheme;
    return dark ? theme.primaryHoverDark : theme.primaryHoverLight;
  }

  static Color getSecondaryColor(bool dark, bool rent) {
    final theme = ThemeManager().currentTheme;
    return dark ? theme.secondaryDark : theme.secondaryLight;
  }

  static Color getAccentColor(bool dark, bool rent) {
    final theme = ThemeManager().currentTheme;
    return dark ? theme.accentDark : theme.accentLight;
  }

  static List<Color> getGradientPrimaryColor(bool dark, bool rent) {
    final theme = ThemeManager().currentTheme;
    return dark
        ? [theme.primaryDark, theme.primaryHoverDark]
        : [theme.primaryLight, theme.primaryHoverLight];
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

  static Color get resaleAccent => isDark
      ? ThemeManager().currentTheme.primaryDark
      : ThemeManager().currentTheme.primaryLight;

  static Color atmosphereAccent(bool isRent) =>
      isRent ? rentAccent : resaleAccent;

  static Color onAtmosphereAccent(bool isRent) {
    if (!isRent) return const Color(0xFFFFFFFF);
    return isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
  }

  static List<Color> atmosphereGradient(bool isRent) => isDark
      ? (isRent
            ? const [Color(0xFFE8E4DF), Color(0xFFD4CFC8)]
            : [
                ThemeManager().currentTheme.primaryDark,
                ThemeManager().currentTheme.primaryHoverDark,
              ])
      : (isRent
            ? const [Color(0xFF1A1A1A), Color(0xFF2C2C2C)]
            : [
                ThemeManager().currentTheme.primaryLight,
                ThemeManager().currentTheme.primaryHoverLight,
              ]);

  // Sidebar styling
  static Color get sidebarText =>
      isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D);
  static Color get sidebarTextSecondary =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A);
  static Color get sidebarBorder =>
      isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2);

  // ── Borders / dividers ─────────────────────────────────────
  static Color get border =>
      isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2);
  static Color get strongBorder =>
      isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
  static Color get inputBorder =>
      isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2);
  static Color get divider =>
      isDark ? const Color(0xFF243044) : const Color(0xFFE8ECF2);

  // ── Strong ink cards (charcoal) ────────────────────────────
  static Color get strongCard =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFF14213D);
  static Color get onStrong => const Color(0xFFFFFFFF);

  // ── KPI fills — white on white canvas, hairline only ───────
  static Color get kpiCream => cardBg;
  static Color get kpiSage => cardBg;
  static Color get kpiSand => cardBg;
  static Color get kpiTerracotta => cardBg;
  static Color get kpiRose => cardBg;
  static Color get kpiPlum => cardBg;
  static Color get kpiClay => cardBg;

  static Color kpiTintFor(Color accent) => cardBg;

  // ── Text — modern navy/charcoal hierarchy ──────────────────
  static Color get text =>
      isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D);
  static Color get textSecondary =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A);
  static Color get textMuted =>
      isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

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

  static List<Color> get gradientPrimary =>
      getGradientPrimaryColor(isDark, isRentMode);

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
      background: const Color(0xFF0F172A),
      groupedBackground: const Color(0xFF0B1120),
      surface: const Color(0xFF1E293B),
      surfaceElevated: const Color(0xFF243044),
      sidebarBg: const Color(0xFF0F172A),
      glassSurface: const Color(0xFF1E293B),
      primary: CRMColors.getPrimaryColor(true, rent),
      primaryHover: CRMColors.getPrimaryHoverColor(true, rent),
      secondary: CRMColors.getSecondaryColor(true, rent),
      accent: CRMColors.getAccentColor(true, rent),
      rentAccent: const Color(0xFFE8E4DF),
      resaleAccent: const Color(0xFF10B981),
      border: const Color(0xFF334155),
      divider: const Color(0xFF243044),
      text: const Color(0xFFF8FAFC),
      textSecondary: const Color(0xFF94A3B8),
      textMuted: const Color(0xFF64748B),
      success: const Color(0xFF10B981),
      warning: const Color(0xFFF59E0B),
      danger: const Color(0xFFEF4444),
      info: const Color(0xFF3B82F6),
      disabled: const Color(0xFF475569),
      overlay: const Color(0x99000000),
      shadow: const Color(0x40000000),
      skeletonBase: const Color(0xFF1E293B),
      skeletonHighlight: const Color(0xFF334155),
      chartColors: const [
        Color(0xFF10B981),
        Color(0xFF3B82F6),
        Color(0xFF8B5CF6),
        Color(0xFFF59E0B),
        Color(0xFF06B6D4),
        Color(0xFFEC4899),
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
