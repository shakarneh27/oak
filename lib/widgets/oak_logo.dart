import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Vector recreation of the official Digital Oak logo: a person-shaped
/// oak trunk with raised arms, an oak-leaf canopy with acorns, an open
/// book at the base, a squirrel holding an acorn, framed by two thin
/// arcs. Drawn with a CustomPainter so it stays crisp at any size; if a
/// production PNG/SVG asset is added later, only this widget changes.
class OakLogo extends StatelessWidget {
  final double size;

  const OakLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _OakTreePainter()),
    );
  }
}

/// Logo + wordmark lockup used in top bars and auth screens.
class OakBrand extends StatelessWidget {
  final double logoSize;
  final bool showTagline;

  /// Overrides the wordmark color (e.g. white on the forest backdrop).
  final Color? textColor;

  const OakBrand({
    super.key,
    this.logoSize = 40,
    this.showTagline = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleColor = textColor ?? textTheme.titleMedium?.color;
    final taglineColor = (textColor ?? textTheme.bodySmall?.color)?.withValues(
      alpha: 0.7,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // white chip behind the mark so it reads on dark backgrounds too
        Container(
          padding: EdgeInsets.all(logoSize * 0.08),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(logoSize * 0.22),
          ),
          child: OakLogo(size: logoSize * 0.84),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'السنديانة الرقمية',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            if (showTagline)
              Text(
                'تعلّم · اكتشف · وانمُ',
                style: textTheme.bodySmall?.copyWith(color: taglineColor),
              ),
          ],
        ),
      ],
    );
  }
}

class _OakTreePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // ---- framing arcs (thin, like the original mark) -------------------
    stroke
      ..color = OakColors.leafDark.withValues(alpha: 0.75)
      ..strokeWidth = w * 0.022;
    final arcRect = Rect.fromCircle(
      center: Offset(w * 0.5, h * 0.48),
      radius: w * 0.44,
    );
    canvas.drawArc(arcRect, math.pi * 0.75, math.pi * 0.42, false, stroke);
    canvas.drawArc(arcRect, math.pi * 2.25, math.pi * 0.42, false, stroke);

    // ---- open book at the base ----------------------------------------
    _drawBook(canvas, w, h, fill);

    // ---- person-shaped trunk with raised arms and a head ---------------
    fill.color = OakColors.leafDark;
    final trunk = Path()
      ..moveTo(w * 0.455, h * 0.72)
      ..quadraticBezierTo(w * 0.47, h * 0.52, w * 0.42, h * 0.40)
      ..quadraticBezierTo(w * 0.36, h * 0.32, w * 0.30, h * 0.28) // left arm
      ..lineTo(w * 0.325, h * 0.245)
      ..quadraticBezierTo(w * 0.42, h * 0.30, w * 0.475, h * 0.345)
      ..quadraticBezierTo(w * 0.5, h * 0.36, w * 0.525, h * 0.345)
      ..quadraticBezierTo(w * 0.58, h * 0.30, w * 0.675, h * 0.245) // right arm
      ..lineTo(w * 0.70, h * 0.28)
      ..quadraticBezierTo(w * 0.64, h * 0.32, w * 0.58, h * 0.40)
      ..quadraticBezierTo(w * 0.53, h * 0.52, w * 0.545, h * 0.72)
      ..close();
    canvas.drawPath(trunk, fill);
    // head
    canvas.drawCircle(Offset(w * 0.5, h * 0.245), w * 0.055, fill);

    // ---- oak-leaf canopy with acorns ----------------------------------
    final rng = [
      // (dx, dy, scale, angle, light?)
      (0.20, 0.16, 1.00, -0.5, false),
      (0.34, 0.09, 1.10, -0.2, true),
      (0.50, 0.06, 1.05, 0.0, false),
      (0.66, 0.09, 1.10, 0.25, true),
      (0.80, 0.16, 1.00, 0.5, false),
      (0.14, 0.30, 0.90, -0.9, true),
      (0.86, 0.30, 0.90, 0.9, true),
      (0.28, 0.22, 0.85, -0.4, false),
      (0.72, 0.22, 0.85, 0.4, false),
      (0.42, 0.15, 0.80, -0.1, true),
      (0.58, 0.15, 0.80, 0.1, true),
    ];
    for (final (dx, dy, s, angle, light) in rng) {
      _drawLeaf(
        canvas,
        Offset(w * dx, h * dy),
        w * 0.11 * s,
        angle,
        light ? OakColors.leaf : OakColors.leafLight,
      );
    }
    // acorns sprinkled in the canopy
    fill.color = OakColors.acorn;
    for (final (dx, dy) in [
      (0.24, 0.10),
      (0.60, 0.04),
      (0.88, 0.22),
      (0.12, 0.22),
    ]) {
      canvas.drawCircle(Offset(w * dx, h * dy), w * 0.028, fill);
    }

    // ---- squirrel with acorn ------------------------------------------
    _drawSquirrel(canvas, w, h);
  }

  void _drawBook(Canvas canvas, double w, double h, Paint fill) {
    // right page
    fill.color = OakColors.leaf;
    final right = Path()
      ..moveTo(w * 0.5, h * 0.72)
      ..quadraticBezierTo(w * 0.70, h * 0.66, w * 0.92, h * 0.70)
      ..lineTo(w * 0.92, h * 0.78)
      ..quadraticBezierTo(w * 0.70, h * 0.74, w * 0.5, h * 0.80)
      ..close();
    canvas.drawPath(right, fill);
    // left page
    final left = Path()
      ..moveTo(w * 0.5, h * 0.72)
      ..quadraticBezierTo(w * 0.30, h * 0.66, w * 0.08, h * 0.70)
      ..lineTo(w * 0.08, h * 0.78)
      ..quadraticBezierTo(w * 0.30, h * 0.74, w * 0.5, h * 0.80)
      ..close();
    canvas.drawPath(left, fill);
    // under-cover
    fill.color = OakColors.leafDark;
    final cover = Path()
      ..moveTo(w * 0.5, h * 0.80)
      ..quadraticBezierTo(w * 0.70, h * 0.74, w * 0.92, h * 0.78)
      ..lineTo(w * 0.92, h * 0.83)
      ..quadraticBezierTo(w * 0.70, h * 0.79, w * 0.5, h * 0.85)
      ..quadraticBezierTo(w * 0.30, h * 0.79, w * 0.08, h * 0.83)
      ..lineTo(w * 0.08, h * 0.78)
      ..quadraticBezierTo(w * 0.30, h * 0.74, w * 0.5, h * 0.80)
      ..close();
    canvas.drawPath(cover, fill);
  }

  void _drawLeaf(
    Canvas canvas,
    Offset center,
    double len,
    double angle,
    Color color,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final paint = Paint()..color = color;
    // stylized oak leaf: pointed ellipse with lobed edges
    final path = Path()
      ..moveTo(0, -len)
      ..quadraticBezierTo(len * 0.55, -len * 0.55, len * 0.42, 0)
      ..quadraticBezierTo(len * 0.60, len * 0.45, 0, len)
      ..quadraticBezierTo(-len * 0.60, len * 0.45, -len * 0.42, 0)
      ..quadraticBezierTo(-len * 0.55, -len * 0.55, 0, -len)
      ..close();
    canvas.drawPath(path, paint);
    // midrib
    final rib = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = len * 0.08;
    canvas.drawLine(Offset(0, -len * 0.75), Offset(0, len * 0.75), rib);
    canvas.restore();
  }

  void _drawSquirrel(Canvas canvas, double w, double h) {
    final paint = Paint()..color = OakColors.squirrel;
    // bushy tail: fat crescent
    final tail = Path()
      ..moveTo(w * 0.80, h * 0.70)
      ..quadraticBezierTo(w * 0.88, h * 0.52, w * 0.78, h * 0.47)
      ..quadraticBezierTo(w * 0.70, h * 0.44, w * 0.70, h * 0.52)
      ..quadraticBezierTo(w * 0.76, h * 0.54, w * 0.75, h * 0.62)
      ..quadraticBezierTo(w * 0.74, h * 0.68, w * 0.78, h * 0.71)
      ..close();
    canvas.drawPath(tail, paint);
    // body
    final body = Path()
      ..moveTo(w * 0.66, h * 0.71)
      ..quadraticBezierTo(w * 0.62, h * 0.60, w * 0.68, h * 0.56)
      ..quadraticBezierTo(w * 0.74, h * 0.53, w * 0.77, h * 0.62)
      ..quadraticBezierTo(w * 0.79, h * 0.68, w * 0.76, h * 0.71)
      ..close();
    canvas.drawPath(body, paint);
    // head + ear
    canvas.drawCircle(Offset(w * 0.665, h * 0.555), w * 0.038, paint);
    final ear = Path()
      ..moveTo(w * 0.655, h * 0.525)
      ..lineTo(w * 0.645, h * 0.495)
      ..lineTo(w * 0.675, h * 0.515)
      ..close();
    canvas.drawPath(ear, paint);
    // acorn in paws
    paint.color = OakColors.acorn;
    canvas.drawCircle(Offset(w * 0.63, h * 0.60), w * 0.022, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
