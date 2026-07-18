enum AdaptiveLevel { weak, medium, advanced }

extension AdaptiveLevelX on AdaptiveLevel {
  static AdaptiveLevel fromString(String value) {
    switch (value) {
      case 'Weak':
        return AdaptiveLevel.weak;
      case 'Advanced':
        return AdaptiveLevel.advanced;
      case 'Medium':
      default:
        return AdaptiveLevel.medium;
    }
  }

  String get dbValue => switch (this) {
    AdaptiveLevel.weak => 'Weak',
    AdaptiveLevel.medium => 'Medium',
    AdaptiveLevel.advanced => 'Advanced',
  };

  String get labelAr => switch (this) {
    AdaptiveLevel.weak => 'ضعيف',
    AdaptiveLevel.medium => 'متوسط',
    AdaptiveLevel.advanced => 'متقدم',
  };

  /// One step down, floored at [weak].
  AdaptiveLevel get downgraded => switch (this) {
    AdaptiveLevel.weak => AdaptiveLevel.weak,
    AdaptiveLevel.medium => AdaptiveLevel.weak,
    AdaptiveLevel.advanced => AdaptiveLevel.medium,
  };
}
