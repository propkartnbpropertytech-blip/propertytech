import 'package:flutter/material.dart';

/// Configuration definition for an application UI theme preset.
class AppThemePreset {
  final String id;
  final String name;
  final String description;
  final bool isDefault;

  // Primary brand colors
  final Color primaryLight;
  final Color primaryDark;
  final Color primaryHoverLight;
  final Color primaryHoverDark;

  // Accent colors
  final Color accentLight;
  final Color accentDark;

  // Secondary surface/fill colors
  final Color secondaryLight;
  final Color secondaryDark;

  // Visual preview color swatches for theme cards in Settings
  final List<Color> previewColors;

  const AppThemePreset({
    required this.id,
    required this.name,
    required this.description,
    this.isDefault = false,
    required this.primaryLight,
    required this.primaryDark,
    required this.primaryHoverLight,
    required this.primaryHoverDark,
    required this.accentLight,
    required this.accentDark,
    required this.secondaryLight,
    required this.secondaryDark,
    required this.previewColors,
  });
}

/// Registry of available theme presets in PropKart.
class AppThemePresets {
  /// The modern green/teal SaaS theme.
  static const modernTeal = AppThemePreset(
    id: 'modern_teal',
    name: 'Modern PropKart (Teal)',
    description:
        'Modern green/teal SaaS theme with crisp white cards, light canvas, and clean accents.',
    isDefault: true,
    primaryLight: Color(0xFF159B73),
    primaryDark: Color(0xFF10B981),
    primaryHoverLight: Color(0xFF128764),
    primaryHoverDark: Color(0xFF34D399),
    accentLight: Color(0xFFE8F5F1),
    accentDark: Color(0xFF0D3D31),
    secondaryLight: Color(0xFFF7F9FC),
    secondaryDark: Color(0xFF1E293B),
    previewColors: [
      Color(0xFF159B73), // Primary Teal
      Color(0xFFE8F5F1), // Soft Tint
      Color(0xFF14213D), // Primary Text
      Color(0xFF3B82F6), // Accent Blue
      Color(0xFF8B5CF6), // Accent Purple
      Color(0xFFF97316), // Accent Orange
    ],
  );

  /// The original PropKart theme (Terracotta & warm clay with natural surfaces).
  static const classic = AppThemePreset(
    id: 'classic',
    name: 'PropKart Classic',
    description:
        'Original warm terracotta and clay palette with natural charcoal surfaces and DM Sans typography.',
    isDefault: false,
    primaryLight: Color(0xFFC15D4A), // Terracotta
    primaryDark: Color(0xFFD47A66), // Terracotta dark mode
    primaryHoverLight: Color(0xFFA64C3C),
    primaryHoverDark: Color(0xFFE08B78),
    accentLight: Color(0xFFF6D8D0), // Soft terracotta tint
    accentDark: Color(0xFF3A2824),
    secondaryLight: Color(0xFFF4F4F3),
    secondaryDark: Color(0xFF2A2623),
    previewColors: [
      Color(0xFFC15D4A), // Primary Terracotta
      Color(0xFFF6D8D0), // Soft Accent
      Color(0xFF1A1A1A), // Charcoal Ink
      Color(0xFF5F8064), // Sage Success
      Color(0xFFC4924A), // Sand Warning
    ],
  );

  /// Default active theme
  static const defaultTheme = modernTeal;

  /// List of all available themes registered in the app.
  static const List<AppThemePreset> all = [modernTeal, classic];

  /// Look up a preset by its unique ID, falling back to [defaultTheme].
  static AppThemePreset getById(String? id) {
    if (id == null || id.isEmpty) return defaultTheme;
    return all.firstWhere(
      (theme) => theme.id == id,
      orElse: () => defaultTheme,
    );
  }
}
