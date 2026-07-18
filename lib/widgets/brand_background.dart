import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import 'oak_logo.dart';

/// Forest-gradient backdrop with glowing color orbs and softly scattered
/// leaves — the brand canvas behind splash, hero, and auth screens,
/// ported from the reference SplashPage.
class LeafBackground extends StatelessWidget {
  final Widget child;

  const LeafBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // The Stack sizes itself to [child] (works inside scroll slivers where
    // height is unbounded); the painted layer then fills whatever that is.
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: OakGradients.forest),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _BackdropPainter()),
          ),
          child,
        ],
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // glowing orbs (sage / sky blue / gold), like the reference's radial
    // gradient blobs in the corners
    void orb(Offset center, double radius, Color color, double opacity) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    orb(
      Offset(size.width * -0.05, size.height * -0.1),
      size.width * 0.35,
      OakColors.primary,
      0.20,
    );
    orb(
      Offset(size.width * 1.05, size.height * 1.05),
      size.width * 0.30,
      OakColors.accentBlue,
      0.15,
    );
    orb(
      Offset(size.width * 1.0, size.height * 0.45),
      size.width * 0.22,
      OakColors.gold,
      0.10,
    );

    // scattered leaves — deterministic layout so the backdrop is stable
    final random = math.Random(7);
    final paint = Paint();
    for (var i = 0; i < 26; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final len = 8 + random.nextDouble() * 10;
      final angle = random.nextDouble() * math.pi * 2;
      paint.color = OakColors.primary.withValues(
        alpha: 0.12 + random.nextDouble() * 0.15,
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

/// The white rounded card holding the official logo, with sage border,
/// glow, and sparkle accents — per the reference splash.
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
          padding: EdgeInsets.all(size * 0.05),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(size * 0.22),
            border: Border.all(
              color: OakColors.primary.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: OakColors.primary.withValues(alpha: 0.35),
                blurRadius: 50,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 60,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: OakLogo(size: size * 0.9),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: _Sparkle(size: size * 0.09, color: OakColors.gold),
        ),
        Positioned(
          bottom: -4,
          left: -10,
          child: _Sparkle(size: size * 0.06, color: OakColors.leafLight),
        ),
      ],
    );
  }
}

class _Sparkle extends StatelessWidget {
  final double size;
  final Color color;

  const _Sparkle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome, color: color, size: size);
  }
}

/// Translucent pill on the forest backdrop. [gold] switches from the sage
/// tagline style to the gold badge style (reference: tagline vs
/// competition badge).
class BrandPill extends StatelessWidget {
  final String text;
  final String? emoji;
  final bool gold;

  const BrandPill({
    super.key,
    required this.text,
    this.emoji,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = gold ? OakColors.gold : OakColors.primary;
    final textColor = gold
        ? OakColors.gold.withValues(alpha: 0.9)
        : OakColors.leafLight.withValues(alpha: 0.92);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: tint.withValues(alpha: gold ? 0.30 : 0.25)),
      ),
      child: Text(
        emoji == null ? text : '$emoji $text',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: gold ? 14 : 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Three softly pulsing sage dots — the brand loading indicator.
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
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
                                    (_controller.value - i * 0.2) * math.pi * 2,
                                  ) +
                                  1) /
                              2),
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: OakColors.primary,
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
