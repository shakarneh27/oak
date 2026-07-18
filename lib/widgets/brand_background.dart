import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import 'oak_logo.dart';

/// Forest-gradient backdrop with softly scattered oak leaves — the brand
/// canvas behind the splash, hero, and auth screens (per the reference
/// design). Wraps [child] in a Stack above the painted background.
class LeafBackground extends StatelessWidget {
  final Widget child;

  const LeafBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // The Stack sizes itself to [child] (works inside scroll slivers where
    // height is unbounded); the leaf layer then fills whatever that is.
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: OakGradients.forest),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _ScatteredLeavesPainter()),
          ),
          child,
        ],
      ),
    );
  }
}

class _ScatteredLeavesPainter extends CustomPainter {
  const _ScatteredLeavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // deterministic pseudo-random layout so the backdrop is stable
    final random = math.Random(7);
    final paint = Paint();
    for (var i = 0; i < 26; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final len = 8 + random.nextDouble() * 10;
      final angle = random.nextDouble() * math.pi * 2;
      paint.color = OakColors.leafLight.withValues(
        alpha: 0.10 + random.nextDouble() * 0.15,
      );
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, -len)
        ..quadraticBezierTo(len * 0.6, 0, 0, len)
        ..quadraticBezierTo(-len * 0.6, 0, 0, -len)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The white rounded card holding the logo, with a soft glow and sparkle
/// accents — matches the reference splash design.
class LogoCard extends StatelessWidget {
  final double size;

  const LogoCard({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 0.16),
            boxShadow: [
              BoxShadow(
                color: OakColors.leafLight.withValues(alpha: 0.35),
                blurRadius: 40,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: OakLogo(size: size * 0.62)),
              Text(
                'السنديانة الرقمية',
                style: TextStyle(
                  color: OakColors.wordmark,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.085,
                ),
              ),
              Text(
                'DIGITAL OAK',
                style: TextStyle(
                  color: OakColors.wordmark.withValues(alpha: 0.8),
                  fontSize: size * 0.05,
                  letterSpacing: size * 0.02,
                ),
              ),
              SizedBox(height: size * 0.02),
            ],
          ),
        ),
        Positioned(top: -8, right: -8, child: _Sparkle(size: size * 0.09)),
        Positioned(bottom: -4, left: -10, child: _Sparkle(size: size * 0.06)),
      ],
    );
  }
}

class _Sparkle extends StatelessWidget {
  final double size;

  const _Sparkle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome, color: OakColors.gold, size: size);
  }
}

/// Dark translucent pill with gold text — used for the tagline and the
/// subject badge on brand screens.
class BrandPill extends StatelessWidget {
  final String text;
  final String? emoji;

  const BrandPill({super.key, required this.text, this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: OakColors.forestDeep.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: OakColors.gold.withValues(alpha: 0.35)),
      ),
      child: Text(
        emoji == null ? text : '$emoji $text',
        style: const TextStyle(
          color: OakColors.gold,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Three softly pulsing dots — the brand loading indicator.
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Opacity(
                  opacity:
                      0.35 +
                      0.65 *
                          ((math.sin(
                                    (_controller.value - i / 3) * math.pi * 2,
                                  ) +
                                  1) /
                              2),
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: OakColors.leafLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
