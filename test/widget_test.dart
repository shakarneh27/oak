import 'package:flutter_test/flutter_test.dart';

import 'package:digital_oak/models/adaptive_level.dart';

void main() {
  group('AdaptiveLevel', () {
    test('downgrades one step at a time and floors at weak', () {
      expect(AdaptiveLevel.advanced.downgraded, AdaptiveLevel.medium);
      expect(AdaptiveLevel.medium.downgraded, AdaptiveLevel.weak);
      expect(AdaptiveLevel.weak.downgraded, AdaptiveLevel.weak);
    });

    test('round-trips through its Supabase string representation', () {
      for (final level in AdaptiveLevel.values) {
        expect(AdaptiveLevelX.fromString(level.dbValue), level);
      }
    });
  });
}
