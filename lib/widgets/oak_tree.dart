import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// شجرة السنديانة الواقعية — تنمو نمواً متصلاً (لا قفزات بين مراحل):
/// كل إجابة صحيحة ترفع [growth] فيطول الجذع وتتمدد الأغصان وتكتنز
/// الأوراق أمام عين الطالب عبر تحريك Tween سلس، وتتوَّج ذهبياً عند القمة.
class OakTree extends StatelessWidget {
  final double growth;

  /// عطّلها في السياقات الساكنة (اختبارات ذهبية مثلاً).
  final bool animate;

  const OakTree({super.key, required this.growth, this.animate = true});

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
    final target = growth.clamp(0, 100).toDouble();
    if (!animate) {
      return CustomPaint(painter: _OakTreePainter(growth: target));
    }
    // TweenAnimationBuilder re-targets smoothly: on first build the tree
    // "grows up" from the ground, and every later growth bump (a correct
    // answer syncing through Realtime) animates from the current size.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) =>
          CustomPaint(painter: _OakTreePainter(growth: value)),
    );
  }
}

class _OakTreePainter extends CustomPainter {
  /// Continuous 0–100.
  final double growth;

  _OakTreePainter({required this.growth});

  static double _smooth(double x) {
    final v = x.clamp(0.0, 1.0);
    return v * v * (3 - 2 * v);
  }

  /// Progress of an element that starts appearing at [from] and is fully
  /// grown at [to].
  double _phase(double t, double from, double to) =>
      _smooth((t - from) / (to - from));

  @override
  void paint(Canvas canvas, Size size) {
    final t = (growth / 100).clamp(0.0, 1.0);
    final sx = size.width / 400;
    final sy = size.height / 400;
    final paint = Paint()..isAntiAlias = true;

    Offset p(double x, double y) => Offset(x * sx, y * sy);

    // ── sun with a soft halo ─────────────────────────────────────────
    for (final (r, a) in const [(58.0, 0.10), (42.0, 0.16), (26.0, 0.85)]) {
      paint.color = OakColors.gold.withValues(alpha: a);
      canvas.drawCircle(p(332, 56), r * sx, paint);
    }

    // ── ground: two soft mounds + roots ──────────────────────────────
    const groundY = 342.0;
    paint.color = const Color(0xFF9DBB7C);
    canvas.drawOval(
      Rect.fromCenter(center: p(200, groundY + 12), width: 300 * sx, height: 52 * sy),
      paint,
    );
    paint.color = OakColors.secondary;
    canvas.drawOval(
      Rect.fromCenter(center: p(200, groundY + 18), width: 340 * sx, height: 44 * sy),
      paint,
    );

    // roots flare out once the tree is established
    final rootT = _phase(t, 0.18, 0.5);
    if (rootT > 0) {
      paint.color = const Color(0xFF6E4318);
      for (final dir in const [-1.0, 1.0]) {
        final root = Path()
          ..moveTo(p(200 + dir * 6, groundY).dx, p(0, groundY).dy)
          ..quadraticBezierTo(
            p(200 + dir * (14 + 14 * rootT), groundY + 2).dx,
            p(0, groundY + 4).dy,
            p(200 + dir * (24 + 20 * rootT), groundY + 12).dx,
            p(0, groundY + 12).dy,
          )
          ..quadraticBezierTo(
            p(200 + dir * 14, groundY + 10).dx,
            p(0, groundY + 10).dy,
            p(200 + dir * 4, groundY).dx,
            p(0, groundY).dy,
          )
          ..close();
        canvas.drawPath(root, paint);
      }
    }

    // ── trunk: tapers and leans slightly, grows continuously ─────────
    final trunkT = _phase(t, 0.0, 0.9);
    final trunkH = 26 + 210 * trunkT; // top of trunk above ground
    final topY = groundY - trunkH;
    final baseW = 7 + 34 * trunkT;
    final topW = baseW * 0.32;

    final trunk = Path()
      ..moveTo(p(200 - baseW / 2, groundY).dx, p(0, groundY).dy)
      ..cubicTo(
        p(200 - baseW * 0.42, groundY - trunkH * 0.38).dx,
        p(0, groundY - trunkH * 0.38).dy,
        p(196 - topW / 2, topY + trunkH * 0.28).dx,
        p(0, topY + trunkH * 0.28).dy,
        p(198 - topW / 2, topY).dx,
        p(0, topY).dy,
      )
      ..lineTo(p(198 + topW / 2, topY).dx, p(0, topY).dy)
      ..cubicTo(
        p(202 + topW / 2, topY + trunkH * 0.3).dx,
        p(0, topY + trunkH * 0.3).dy,
        p(200 + baseW * 0.46, groundY - trunkH * 0.34).dx,
        p(0, groundY - trunkH * 0.34).dy,
        p(200 + baseW / 2, groundY).dx,
        p(0, groundY).dy,
      )
      ..close();
    paint.color = const Color(0xFF7C4E22);
    canvas.drawPath(trunk, paint);

    // sunlit edge of the bark
    paint.color = const Color(0xFF9A6A35).withValues(alpha: 0.85);
    final barkLight = Path()
      ..moveTo(p(200 - baseW / 2 + baseW * 0.18, groundY).dx, p(0, groundY).dy)
      ..cubicTo(
        p(200 - baseW * 0.24, groundY - trunkH * 0.4).dx,
        p(0, groundY - trunkH * 0.4).dy,
        p(197 - topW * 0.1, topY + trunkH * 0.25).dx,
        p(0, topY + trunkH * 0.25).dy,
        p(198, topY).dx,
        p(0, topY).dy,
      )
      ..lineTo(p(198 - topW / 2, topY).dx, p(0, topY).dy)
      ..cubicTo(
        p(196 - topW / 2, topY + trunkH * 0.28).dx,
        p(0, topY + trunkH * 0.28).dy,
        p(200 - baseW * 0.42, groundY - trunkH * 0.38).dx,
        p(0, groundY - trunkH * 0.38).dy,
        p(200 - baseW / 2, groundY).dx,
        p(0, groundY).dy,
      )
      ..close();
    canvas.drawPath(barkLight, paint);

    // ── branches: tapered limbs reaching for the canopy ──────────────
    // (startFrac along trunk, direction, reach, appears at)
    const branches = [
      (0.94, -1.0, 78.0, 0.30),
      (0.94, 1.0, 78.0, 0.34),
      (0.72, -1.0, 62.0, 0.46),
      (0.72, 1.0, 62.0, 0.50),
      (0.52, 1.0, 46.0, 0.62),
      (0.52, -1.0, 46.0, 0.66),
    ];
    paint.color = const Color(0xFF7C4E22);
    for (final (frac, dir, reach, appear) in branches) {
      final bt = _phase(t, appear, appear + 0.18);
      if (bt <= 0) continue;
      final sy0 = groundY - trunkH * frac;
      final len = reach * bt;
      final tipX = 200 + dir * len;
      final tipY = sy0 - len * 0.62;
      final w = (baseW * 0.24 * bt).clamp(1.5, 9.0);
      final branch = Path()
        ..moveTo(p(200, sy0 - w).dx, p(0, sy0 - w).dy)
        ..quadraticBezierTo(
          p(200 + dir * len * 0.5, sy0 - len * 0.5).dx,
          p(0, sy0 - len * 0.5).dy,
          p(tipX, tipY).dx,
          p(0, tipY).dy,
        )
        ..quadraticBezierTo(
          p(200 + dir * len * 0.48, sy0 - len * 0.34).dx,
          p(0, sy0 - len * 0.34).dy,
          p(200, sy0 + w).dx,
          p(0, sy0 + w).dy,
        )
        ..close();
      canvas.drawPath(branch, paint);
    }

    // ── seedling leaves while the tree is still a sprout ─────────────
    final sproutT = 1 - _phase(t, 0.12, 0.3);
    if (sproutT > 0) {
      paint.color = OakColors.primary.withValues(alpha: sproutT);
      for (final dir in const [-1.0, 1.0]) {
        final leaf = Path()
          ..moveTo(p(200, topY + 6).dx, p(0, topY + 6).dy)
          ..quadraticBezierTo(
            p(200 + dir * 26, topY - 10).dx,
            p(0, topY - 10).dy,
            p(200 + dir * 38, topY + 2).dx,
            p(0, topY + 2).dy,
          )
          ..quadraticBezierTo(
            p(200 + dir * 18, topY + 12).dx,
            p(0, topY + 12).dy,
            p(200, topY + 6).dx,
            p(0, topY + 6).dy,
          )
          ..close();
        canvas.drawPath(leaf, paint);
      }
    }

    // ── canopy: layered leaf clusters that swell as growth rises ─────
    // (dx, dy from trunk top at full size, radius, appears at, color)
    final clusters = <(double, double, double, double, Color)>[
      // deep shadow layer
      (-58, 26, 54, 0.22, const Color(0xFF5E7C42)),
      (58, 26, 54, 0.26, const Color(0xFF5E7C42)),
      (0, 44, 62, 0.20, const Color(0xFF5E7C42)),
      // mid greens
      (-84, -4, 52, 0.38, const Color(0xFF7A9A5A)),
      (84, -4, 52, 0.42, const Color(0xFF7A9A5A)),
      (-38, -34, 56, 0.34, const Color(0xFF7A9A5A)),
      (38, -34, 56, 0.36, const Color(0xFF7A9A5A)),
      (0, 6, 64, 0.28, const Color(0xFF6E8C4E)),
      // bright crown
      (-56, -52, 46, 0.52, const Color(0xFF8DAE6A)),
      (56, -52, 46, 0.56, const Color(0xFF8DAE6A)),
      (0, -68, 54, 0.60, const Color(0xFF8DAE6A)),
      (-20, -18, 48, 0.48, OakColors.primary),
      (20, -14, 48, 0.50, OakColors.primary),
      // sunlit highlights
      (-34, -60, 26, 0.70, const Color(0xFFB9D394)),
      (30, -70, 24, 0.76, const Color(0xFFB9D394)),
      (2, -34, 30, 0.72, const Color(0xFFA8C686)),
    ];
    final spread = 0.42 + 0.58 * _phase(t, 0.15, 0.95);
    for (final (dx, dy, r, appear, color) in clusters) {
      final ct = _phase(t, appear, appear + 0.22);
      if (ct <= 0) continue;
      paint.color = color.withValues(alpha: 0.55 + 0.45 * ct);
      canvas.drawCircle(
        Offset(
          p(200 + dx * spread, 0).dx,
          p(0, topY + 8 + dy * spread).dy,
        ),
        r * ct * sx,
        paint,
      );
    }

    // ── grass blades and flowers fill in with progress ───────────────
    final grassT = _phase(t, 0.08, 0.6);
    if (grassT > 0) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.4 * sx
        ..color = const Color(0xFF6E8C4E).withValues(alpha: grassT);
      for (final (gx, gh) in const [
        (86.0, 14.0),
        (120.0, 18.0),
        (158.0, 12.0),
        (248.0, 16.0),
        (286.0, 13.0),
        (318.0, 17.0),
      ]) {
        canvas.drawLine(
          p(gx, groundY + 14),
          p(gx + 3, groundY + 14 - gh * grassT),
          paint,
        );
      }
      paint.style = PaintingStyle.fill;
      final flowerT = _phase(t, 0.45, 0.8);
      if (flowerT > 0) {
        for (final (fx, color) in const [
          (104.0, OakColors.coral),
          (270.0, OakColors.gold),
          (330.0, Color(0xFF7CC6FE)),
        ]) {
          paint.color = color.withValues(alpha: flowerT);
          canvas.drawCircle(p(fx, groundY + 6), 3.6 * sx * flowerT, paint);
        }
      }
    }

    // ── the golden crown of the great oak ────────────────────────────
    final goldT = _phase(t, 0.85, 1.0);
    if (goldT > 0) {
      paint.color = OakColors.gold.withValues(alpha: 0.13 * goldT);
      canvas.drawCircle(p(200, topY - 44 * spread), 92 * goldT * sx, paint);

      // acorns tucked into the canopy
      for (final (ax, ay) in const [(-52.0, 10.0), (46.0, -6.0), (-6.0, -50.0)]) {
        final c = Offset(
          p(200 + ax * spread, 0).dx,
          p(0, topY + 8 + ay * spread).dy,
        );
        paint.color = const Color(0xFF8B5A2B).withValues(alpha: goldT);
        canvas.drawOval(
          Rect.fromCenter(center: c, width: 9 * sx, height: 12 * sy),
          paint,
        );
        paint.color = const Color(0xFF6E4318).withValues(alpha: goldT);
        canvas.drawArc(
          Rect.fromCenter(center: c.translate(0, -3 * sy), width: 10 * sx, height: 7 * sy),
          math.pi,
          math.pi,
          true,
          paint,
        );
      }

      // sparkles
      paint.color = OakColors.gold.withValues(alpha: goldT);
      for (final (sxp, syp, r) in const [
        (128.0, 70.0, 5.0),
        (282.0, 46.0, 4.0),
        (206.0, 8.0, 6.0),
      ]) {
        final c = p(sxp, syp);
        final star = Path()
          ..moveTo(c.dx, c.dy - r * sx * 1.6)
          ..quadraticBezierTo(c.dx, c.dy, c.dx + r * sx * 1.6, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r * sx * 1.6)
          ..quadraticBezierTo(c.dx, c.dy, c.dx - r * sx * 1.6, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r * sx * 1.6)
          ..close();
        canvas.drawPath(star, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OakTreePainter oldDelegate) =>
      oldDelegate.growth != growth;
}
