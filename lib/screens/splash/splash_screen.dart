import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../providers/core_providers.dart';
import '../../widgets/brand_background.dart';

/// شاشة البداية بهوية العلامة: خلفية غابة متدرجة، بطاقة الشعار البيضاء،
/// وسطر الشعار — تُعرض لثوانٍ مع دخول ناعم ثم تنتقل تلقائياً (زائر →
/// الصفحة التعريفية، مسجل → لوحته حسب دوره).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _visible = true);
    });
    _timer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      final session = ref.read(supabaseClientProvider).auth.currentSession;
      // '/login' resolves to the signed-in user's role home via the
      // router redirect; guests land on the public home page.
      context.go(session == null ? '/' : '/login');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        child: SafeArea(
          child: AnimatedSlide(
            offset: _visible ? Offset.zero : const Offset(0, 0.04),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 700),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const LogoCard(size: 210),
                  const SizedBox(height: AppSpacing.xl),
                  const BrandPill(
                    text: 'تعلّم · اكتشف · وانمُ معنا',
                    emoji: '🌿',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const LoadingDots(),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      'السنديانة الرقمية © 2026',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
