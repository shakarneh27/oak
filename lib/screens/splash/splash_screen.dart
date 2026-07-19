import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/core_providers.dart';
import '../../widgets/brand_background.dart';

/// شاشة البداية: خلفية غابة بأوراق متساقطة حية، دخول مرن لبطاقة الشعار،
/// ظهور متدرج للشعار والنقاط، ثم خروج ناعم والانتقال التلقائي
/// (زائر → الصفحة التعريفية، مسجل → لوحته حسب دوره).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  // staggered entrance curves
  late final Animation<double> _cardScale = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
  );
  late final Animation<double> _cardFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
  );
  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
  );
  late final Animation<double> _dotsFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
  );

  bool _leaving = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _intro.forward();
    _timer = Timer(const Duration(milliseconds: 3000), _leave);
  }

  Future<void> _leave() async {
    if (!mounted || _leaving) return;
    setState(() => _leaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    final session = ref.read(supabaseClientProvider).auth.currentSession;
    // '/login' resolves to the signed-in user's role home via the router
    // redirect; guests land on the public home page.
    context.go(session == null ? '/' : '/login');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // اختصار: لمسة تتخطى الانتظار
        onTap: _leave,
        child: LeafBackground(
          child: Stack(
            children: [
              const Positioned.fill(child: _FallingLeaves()),
              AnimatedOpacity(
                opacity: _leaving ? 0 : 1,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        ScaleTransition(
                          scale: _cardScale,
                          child: FadeTransition(
                            opacity: _cardFade,
                            child: const _BreathingLogoCard(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FadeTransition(
                          opacity: _taglineFade,
                          child: const BrandPill(
                            text: 'تعلّم · اكتشف · وانمُ معنا',
                            emoji: '🌿',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FadeTransition(
                          opacity: _dotsFade,
                          child: const LoadingDots(),
                        ),
                        const Spacer(flex: 3),
                        FadeTransition(
                          opacity: _dotsFade,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: Text(
                              'السنديانة الرقمية © 2026',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة الشعار مع "تنفس" خفيف (تكبير/تصغير بطيء) بعد الدخول.
class _BreathingLogoCard extends StatefulWidget {
  const _BreathingLogoCard();

  @override
  State<_BreathingLogoCard> createState() => _BreathingLogoCardState();
}

class _BreathingLogoCardState extends State<_BreathingLogoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_breath.value);
        return Transform.scale(scale: 1 + t * 0.025, child: child);
      },
      child: const LogoCard(size: 210),
    );
  }
}

/// أوراق متساقطة حية تهبط بتمايل من أعلى الشاشة — مثل المرجع.
class _FallingLeaves extends StatefulWidget {
  const _FallingLeaves();

  @override
  State<_FallingLeaves> createState() => _FallingLeavesState();
}

class _FallingLeavesState extends State<_FallingLeaves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) =>
            CustomPaint(painter: _FallingLeavesPainter(t: _controller.value)),
      ),
    );
  }
}

class _FallingLeavesPainter extends CustomPainter {
  final double t;

  _FallingLeavesPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(3);
    final paint = Paint();
    for (var i = 0; i < 14; i++) {
      final baseX = random.nextDouble();
      final speed = 0.55 + random.nextDouble() * 0.6;
      final phase = random.nextDouble();
      final swayAmp = 20 + random.nextDouble() * 30;
      final leafSize = 8.0 + random.nextDouble() * 8;
      final opacity = 0.25 + random.nextDouble() * 0.3;

      // progress for this leaf (loops independently via phase offset)
      final p = ((t * speed) + phase) % 1.0;
      final y = p * (size.height + 60) - 30;
      final sway = math.sin(p * math.pi * 4 + i) * swayAmp;
      final x = baseX * size.width + sway;
      final rotation = p * math.pi * 3 * (i.isEven ? 1 : -1);

      paint.color = OakColors.primary.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final path = Path()
        ..moveTo(0, -leafSize)
        ..quadraticBezierTo(leafSize * 0.7, 0, 0, leafSize)
        ..quadraticBezierTo(-leafSize * 0.7, 0, 0, -leafSize)
        ..close();
      canvas.drawPath(path, paint);
      // midrib
      paint.color = Colors.white.withValues(alpha: opacity * 0.4);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 1,
          height: leafSize * 1.2,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FallingLeavesPainter oldDelegate) =>
      oldDelegate.t != t;
}
