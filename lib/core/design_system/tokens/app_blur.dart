/// Blur sigma tokens for glass / translucent surfaces.
/// Dark mode uses richer blur; light mode uses lighter frost.
class CRMBlur {
  static const double navigationLight = 16.0;
  static const double navigationDark = 28.0;
  static const double navigation = 22.0;
  static const double dialog = 24.0;
  static const double bottomSheet = 28.0;
  static const double search = 24.0;
  static const double floatingPanel = 32.0;
  static const double notificationPanel = 36.0;

  /// Reduced blur when animations are disabled or for performance.
  static const double reduced = 8.0;

  static double navigationFor(bool isDark) =>
      isDark ? navigationDark : navigationLight;
}
