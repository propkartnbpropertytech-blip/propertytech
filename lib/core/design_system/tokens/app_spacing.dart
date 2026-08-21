/// Spacing scale (4–64). Never use random spacing outside this scale.
class CRMSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double s = 12.0;
  static const double m = 16.0;
  static const double md = 20.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double xxxl = 48.0;
  static const double max = 64.0;
}

/// Corner radius tokens (4, 8, 12, 16, 20, 24, 28, 32, 40).
class CRMBorderRadius {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  /// 20 — new mid radius
  static const double ml = 20.0;
  /// 24 — preserved as `xl` for existing call sites
  static const double xl = 24.0;
  static const double xxl = 28.0;
  static const double huge = 32.0;
  static const double mega = 40.0;
  static const double round = 999.0;

  /// Standard card radius.
  static const double card = xl; // 24
  static const double kpi = xxl; // 28
  static const double liquidBar = 28.0;
  static const double button = ml; // 20
  static const double input = l; // 16
  static const double dialog = xxl;
  static const double sheet = mega;
}
