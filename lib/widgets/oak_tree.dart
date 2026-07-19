import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Growth-staged oak tree ported from the reference OakTree.tsx: the
/// canopy fills in over six stages as [growth] (0–100) increases, ending
/// with a golden crown glow at the "السنديانة العظيمة" stage.
class OakTree extends StatelessWidget {
  final double growth;

  const OakTree({super.key, required this.growth});

  /// Same thresholds as the reference component.
  static int stageFor(double growth) => growth >= 85
      ? 5
      : growth >= 68
      ? 4
      : growth >= 51
      ? 3
      : growth >= 34
      ? 2
      : growth >= 17
      ? 1
      : 0;

  /// Level label per stage (LEVEL_LABELS from the reference roster).
  static (String, String) levelLabelFor(double growth) =>
      switch (stageFor(growth)) {
        0 => ('بذرة', '🌱'),
        1 => ('شتلة', '🌿'),
        2 => ('غصين', '🌳'),
        3 => ('شجرة يافعة', '🌲'),
        4 => ('سنديانة نامية', '🌳'),
        _ => ('السنديانة العظيمة', '🏆'),
      };

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _OakTreePainter(stage: stageFor(growth)));
  }
}

class _OakTreePainter extends CustomPainter {
  final int stage;

  _OakTreePainter({required this.stage});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 400;
    final sy = size.height / 400;
    final paint = Paint();

    void circle(
      double cx,
      double cy,
      double r,
      Color color, {
      double opacity = 0.9,
    }) {
      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(cx * s, cy * sy), r * s, paint);
    }

    // ground
    paint.color = OakColors.secondary;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(200 * s, 350 * sy),
        width: 240 * s,
        height: 40 * sy,
      ),
      paint,
    );

    // trunk grows slightly with each stage
    final trunkScale = 0.8 + stage * 0.04;
    canvas.save();
    canvas.translate(200 * s, 350 * sy);
    canvas.scale(trunkScale);
    canvas.translate(-200 * s, -350 * sy);
    paint.color = const Color(0xFF8B5A2B);
    final trunk = Path()
      ..moveTo(180 * s, 350 * sy)
      ..cubicTo(180 * s, 320 * sy, 190 * s, 280 * sy, 190 * s, 200 * sy)
      ..cubicTo(190 * s, 280 * sy, 200 * s, 320 * sy, 220 * s, 350 * sy)
      ..close();
    canvas.drawPath(trunk, paint);
    canvas.restore();

    // stage 0: seedling leaves
    paint.color = OakColors.primary;
    final leaf1 = Path()
      ..moveTo(190 * s, 230 * sy)
      ..quadraticBezierTo(170 * s, 210 * sy, 160 * s, 220 * sy)
      ..quadraticBezierTo(180 * s, 240 * sy, 190 * s, 230 * sy)
      ..close();
    final leaf2 = Path()
      ..moveTo(210 * s, 225 * sy)
      ..quadraticBezierTo(230 * s, 205 * sy, 240 * s, 215 * sy)
      ..quadraticBezierTo(220 * s, 235 * sy, 210 * s, 225 * sy)
      ..close();
    canvas.drawPath(leaf1, paint);
    canvas.drawPath(leaf2, paint);

    if (stage >= 1) {
      circle(200, 170, 40, OakColors.primary);
      circle(170, 190, 30, OakColors.primary);
      circle(230, 190, 30, OakColors.primary);
    }
    if (stage >= 2) {
      circle(200, 110, 60, const Color(0xFF8DAE6A));
      circle(140, 140, 50, const Color(0xFF8DAE6A));
      circle(260, 140, 50, const Color(0xFF8DAE6A));
      circle(170, 100, 45, OakColors.primary);
      circle(230, 100, 45, OakColors.primary);
    }
    if (stage >= 3) {
      circle(200, 50, 70, const Color(0xFF7A9A5A));
      circle(120, 90, 60, const Color(0xFF7A9A5A));
      circle(280, 90, 60, const Color(0xFF7A9A5A));
      circle(150, 40, 55, const Color(0xFF8DAE6A));
      circle(250, 40, 55, const Color(0xFF8DAE6A));
    }
    if (stage >= 4) {
      circle(100, 60, 50, const Color(0xFF688749));
      circle(300, 60, 50, const Color(0xFF688749));
      circle(160, 0, 60, const Color(0xFF7A9A5A));
      circle(240, 0, 60, const Color(0xFF7A9A5A));
    }
    if (stage >= 5) {
      circle(200, -10, 70, OakColors.gold, opacity: 0.3);
      circle(200, 0, 55, const Color(0xFF688749));
    }
  }

  @override
  bool shouldRepaint(covariant _OakTreePainter oldDelegate) =>
      oldDelegate.stage != stage;
}
