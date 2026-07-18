import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Placeholder brand logo: a stylized oak tree drawn with a CustomPainter
/// so it scales crisply at any size. Swap the painter for a real asset
/// later without touching any call site.
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

  const OakBrand({super.key, this.logoSize = 40, this.showTagline = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OakLogo(size: logoSize),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'السنديانة الرقمية',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (showTagline)
              Text(
                'نتعلم العلوم باللعب',
                style: textTheme.bodySmall?.copyWith(
                  color: textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
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
    final paint = Paint()..style = PaintingStyle.fill;

    // rounded badge background
    paint.color = OakColors.leafDark.withValues(alpha: 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(w * 0.24)),
      paint,
    );

    // trunk
    paint.color = OakColors.trunk;
    final trunk = Path()
      ..moveTo(w * 0.46, h * 0.86)
      ..lineTo(w * 0.46, h * 0.58)
      ..quadraticBezierTo(w * 0.46, h * 0.5, w * 0.38, h * 0.44)
      ..lineTo(w * 0.42, h * 0.4)
      ..quadraticBezierTo(w * 0.5, h * 0.46, w * 0.5, h * 0.46)
      ..quadraticBezierTo(w * 0.5, h * 0.46, w * 0.58, h * 0.38)
      ..lineTo(w * 0.62, h * 0.42)
      ..quadraticBezierTo(w * 0.54, h * 0.5, w * 0.54, h * 0.58)
      ..lineTo(w * 0.54, h * 0.86)
      ..close();
    canvas.drawPath(trunk, paint);

    // canopy: three overlapping circles, two greens for depth
    paint.color = OakColors.leafDark;
    canvas.drawCircle(Offset(w * 0.34, h * 0.36), w * 0.18, paint);
    canvas.drawCircle(Offset(w * 0.66, h * 0.36), w * 0.18, paint);
    paint.color = OakColors.leafLight;
    canvas.drawCircle(Offset(w * 0.5, h * 0.26), w * 0.2, paint);

    // acorn accent
    paint.color = OakColors.acorn;
    canvas.drawCircle(Offset(w * 0.66, h * 0.52), w * 0.06, paint);

    // ground line
    paint.color = OakColors.leafDark.withValues(alpha: 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.86, w * 0.44, h * 0.05),
        Radius.circular(w * 0.03),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
