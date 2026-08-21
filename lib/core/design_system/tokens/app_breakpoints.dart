import 'package:flutter/widgets.dart';

/// Responsive breakpoints — phone → phablet → tablet → desktop → ultrawide.
class CRMBreakpoints {
  static const double phone = 360;
  static const double phablet = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double wide = 1280;
  static const double ultrawide = 1536;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isPhone(BuildContext context) => widthOf(context) < tablet;
  static bool isTablet(BuildContext context) {
    final w = widthOf(context);
    return w >= tablet && w < desktop;
  }

  static bool isDesktop(BuildContext context) => widthOf(context) >= desktop;

  /// Cross-axis count for KPI grids. Mobile always keeps 2-up.
  static int kpiColumns(BuildContext context, {int desktop = 4}) {
    final w = widthOf(context);
    if (w < tablet) return 2;
    if (w < desktop) return 3;
    return desktop;
  }

  /// Width/height for KPI cells — tuned for 2-up mobile without overflow.
  static double kpiAspectRatio(BuildContext context) {
    final w = widthOf(context);
    if (w < 600) return 1.35;
    if (w < tablet) return 1.6;
    if (w < desktop) return 1.9;
    return 2.2;
  }

  /// Horizontal page padding that scales with viewport.
  static double pagePadding(BuildContext context) {
    final w = widthOf(context);
    if (w < phablet) return 12;
    if (w < tablet) return 16;
    if (w < desktop) return 20;
    if (w < wide) return 24;
    return 32;
  }

  /// Max content width for ultrawide centering.
  static double get maxContentWidth => 1440;
}
