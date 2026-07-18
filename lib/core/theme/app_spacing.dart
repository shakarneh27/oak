/// Central spacing scale so paddings/gaps stay consistent app-wide
/// instead of magic numbers scattered through screens.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double section = 72;

  /// Max content width for centered page sections on wide screens.
  static const double contentMaxWidth = 1040;
}
