import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../widgets/brand_background.dart';

/// شاشة البداية بهوية العلامة: خلفية غابة متدرجة بأوراق متناثرة، بطاقة
/// الشعار البيضاء، سطر الشعار الذهبي، وشارة المادة — التوجيه الفعلي يتم في
/// GoRouter (فحص الجلسة المحفوظة).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              const LogoCard(size: 210),
              const SizedBox(height: AppSpacing.xl),
              const BrandPill(text: 'تعلّم · اكتشف · وانمُ معنا', emoji: '🌿'),
              const SizedBox(height: AppSpacing.md),
              const BrandPill(
                text: 'علوم الصف الرابع — الفصل الثاني',
                emoji: '🏆',
              ),
              const SizedBox(height: AppSpacing.xl),
              const LoadingDots(),
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'السنديانة الرقمية © 2026',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
