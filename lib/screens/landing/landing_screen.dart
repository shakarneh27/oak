import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/oak_logo.dart';
import '../../widgets/section_shell.dart';
import 'landing_content.dart';

/// الصفحة التعريفية العامة للمشروع: تشرح المنصة لغير المسجلين، مع أزرار
/// تسجيل الدخول وإنشاء الحساب في زاوية الشريط العلوي.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(const [
              _HeroSection(),
              _FeaturesSection(),
              _StepsSection(),
              _CallToActionSection(),
              _Footer(),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Top navigation bar overlaying the forest hero: brand on one side,
/// auth buttons in the corner.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 560;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.contentMaxWidth,
            ),
            child: Row(
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: OakBrand(
                      showTagline: !isNarrow,
                      textColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (!isNarrow) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    onPressed: () => context.go('/login?mode=signup'),
                    child: const Text('حساب جديد'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                isNarrow
                    ? FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: OakColors.forest,
                        ),
                        onPressed: () => context.go('/login'),
                        child: const Text('دخول'),
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: OakColors.forest,
                        ),
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('تسجيل الدخول'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LeafBackground(
      child: Column(
        children: [
          const _TopBar(),
          SectionShell(
            child: Column(
              children: [
                const LogoCard(size: 190),
                const SizedBox(height: AppSpacing.xl),
                const BrandPill(
                  text: 'تعلّم · اكتشف · وانمُ معنا',
                  emoji: '🌿',
                ),
                const SizedBox(height: AppSpacing.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Text(
                    LandingContent.heroSubtitle,
                    style: textTheme.titleMedium?.copyWith(
                      height: 1.8,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: OakColors.accentBlue,
                        foregroundColor: OakColors.ink,
                      ),
                      onPressed: () => context.go('/login?mode=signup'),
                      icon: const Icon(Icons.rocket_launch_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('ابدأ رحلة التعلم'),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.login),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('لدي حساب'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.section),
                const _StatsRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xl,
      runSpacing: AppSpacing.lg,
      alignment: WrapAlignment.center,
      children: [
        for (final stat in LandingContent.stats) _StatBadge(stat: stat),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final StatInfo stat;

  const _StatBadge({required this.stat});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stat.value,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: OakColors.gold,
          ),
        ),
        Text(
          stat.label,
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    return SectionShell(
      background: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          const SectionHeading(
            title: 'لماذا السنديانة الرقمية؟',
            subtitle:
                'نظام تعليمي متكامل يربط الطالب والمعلم وولي الأمر في حلقة واحدة',
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 560
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * AppSpacing.md) /
                  columns;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final feature in LandingContent.features)
                    SizedBox(
                      width: width,
                      child: _FeatureCard(feature: feature),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final FeatureInfo feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(feature.icon, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              feature.title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              feature.description,
              style: textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepsSection extends StatelessWidget {
  const _StepsSection();

  @override
  Widget build(BuildContext context) {
    return SectionShell(
      background: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          const SectionHeading(title: 'كيف تعمل المنصة؟'),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 720;
              final steps = [
                for (final (index, step) in LandingContent.steps.indexed)
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: _StepTile(index: index + 1, step: step),
                  ),
              ];
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: steps,
                    )
                  : Column(
                      children: [
                        for (final (index, step)
                            in LandingContent.steps.indexed)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.lg,
                            ),
                            child: _StepTile(index: index + 1, step: step),
                          ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int index;
  final StepInfo step;

  const _StepTile({required this.index, required this.step});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: OakColors.leafDark,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            step.title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            step.description,
            style: textTheme.bodyMedium?.copyWith(height: 1.7),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CallToActionSection extends StatelessWidget {
  const _CallToActionSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SectionShell(
      child: Card(
        margin: EdgeInsets.zero,
        color: OakColors.leafDark,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Text(
                'جاهزون لزراعة أول سنديانة؟',
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'أنشئ حساباً كطالب أو معلم أو ولي أمر وابدأ خلال دقيقة.',
                style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: OakColors.leafDark,
                ),
                onPressed: () => context.go('/login?mode=signup'),
                child: const Text('إنشاء حساب مجاني'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return SectionShell(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          const OakBrand(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            LandingContent.footerNote,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
