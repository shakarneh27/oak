import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/adaptive_level.dart';
import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/main_bottom_nav.dart';
import '../../widgets/oak_tree.dart';

/// لوحة الطالب الفاخرة: ترويسة غابية متدرجة بحلقة ذهبية حول الصورة،
/// مشهد سماء حي تنمو فيه السنديانة الواقعية مع كل إجابة صحيحة، شريط
/// نمو متدرج يبين المسافة للمرحلة التالية، ثم بطاقة المستوى ومهمة اليوم.
class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final studentId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final progress = studentId == null
        ? null
        : ref.watch(studentProgressProvider(studentId)).valueOrNull;

    final growth = ((progress?.treeGrowthStage ?? 0) * 5)
        .clamp(0, 100)
        .toDouble();
    final level = OakTree.levelLabelFor(growth);
    final firstName = (profile?.name ?? 'صديقي').split(' ').first;

    return Scaffold(
      bottomNavigationBar: const MainBottomNav(currentPath: '/dashboard'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF7E6), OakColors.cream, Color(0xFFF6FBF0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeroHeader(
                    name: profile?.name ?? '',
                    avatar: profile?.displayAvatar ?? '🧒',
                    levelLabel: '${level.$2} ${level.$1}',
                    stars: progress?.oakLeaves ?? 0,
                    leaves: progress?.treeGrowthStage ?? 0,
                    badges: progress?.badgesUnlocked.length ?? 0,
                  ),
                  const SizedBox(height: 12),
                  _TreeScene(
                    growth: growth,
                    firstName: firstName,
                    onNouriTap: () {
                      ref.read(soundServiceProvider).click();
                      context.push('/ai-assistant');
                    },
                  ),
                  const SizedBox(height: 12),
                  _LevelCard(
                    level: progress?.currentLevel ?? AdaptiveLevel.weak,
                    placementDone: progress?.placementDone ?? false,
                    onRetake: () {
                      ref.read(soundServiceProvider).click();
                      context.push('/diagnostic');
                    },
                  ),
                  const SizedBox(height: 12),
                  _DailyQuestCard(
                    onTap: () {
                      ref.read(soundServiceProvider).click();
                      context.push('/units');
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ShortcutCard(
                          emoji: '🌳',
                          label: 'شجرتي',
                          gradient: const [Color(0xFFD9EEC6), Color(0xFFC3E2A6)],
                          onTap: () => context.push('/progress-tree'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ShortcutCard(
                          emoji: '🐿️',
                          label: 'اسأل نوري',
                          gradient: const [Color(0xFFFFE9C7), Color(0xFFFFD9A0)],
                          onTap: () => context.push('/ai-assistant'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ShortcutCard(
                          emoji: '🏆',
                          label: 'إنجازاتي',
                          gradient: const [Color(0xFFDCEBFF), Color(0xFFBFDBFE)],
                          onTap: () => context.push('/achievements'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── الترويسة الغابية ───────────────────────

class _HeroHeader extends StatelessWidget {
  final String name;
  final String avatar;
  final String levelLabel;
  final int stars;
  final int leaves;
  final int badges;

  const _HeroHeader({
    required this.name,
    required this.avatar,
    required this.levelLabel,
    required this.stars,
    required this.leaves,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF2D4A2D), Color(0xFF3A5C3A), Color(0xFF486E42)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D4A2D).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // gold-ring avatar
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [OakColors.gold, Color(0xFFF6B93B)],
                  ),
                ),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(avatar, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: OakColors.gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        levelLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF35524A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _GlassStat(emoji: '⭐', label: 'نجمة', value: '$stars'),
              const SizedBox(width: 8),
              _GlassStat(emoji: '🍃', label: 'ورقة', value: '$leaves'),
              const SizedBox(width: 8),
              _GlassStat(emoji: '🏅', label: 'شارة', value: '$badges'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _GlassStat({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$emoji $value',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                )),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── مشهد الشجرة الحي ───────────────────────

class _TreeScene extends StatelessWidget {
  final double growth;
  final String firstName;
  final VoidCallback onNouriTap;

  const _TreeScene({
    required this.growth,
    required this.firstName,
    required this.onNouriTap,
  });

  static const _thresholds = [17.0, 34.0, 51.0, 68.0, 85.0];

  @override
  Widget build(BuildContext context) {
    final next = _thresholds.where((th) => th > growth).firstOrNull;
    final nextLabel = next == null ? null : OakTree.levelLabelFor(next);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDDF0FF), Color(0xFFEAF6F0), Color(0xFFF6FBEF)],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: OakColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            SizedBox(
              height: 340,
              child: Stack(
                children: [
                  // drifting clouds
                  const Positioned(top: 26, left: 24, child: _Cloud(width: 64)),
                  const Positioned(top: 58, right: 40, child: _Cloud(width: 46)),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OakTree(growth: growth),
                    ),
                  ),
                  // growth badge
                  PositionedDirectional(
                    top: 14,
                    end: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${growth.round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: OakColors.leafDark,
                            ),
                          ),
                          Text(
                            'نمو الشجرة',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Nouri with welcome bubble
                  PositionedDirectional(
                    bottom: 12,
                    start: 10,
                    child: GestureDetector(
                      onTap: onNouriTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              'مرحباً يا $firstName! 👋',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SvgPicture.asset(
                            'assets/images/nouri.svg',
                            width: 84,
                            height: 84,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // growth meter + next milestone
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              color: Colors.white.withValues(alpha: 0.75),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '🌱 كل إجابة صحيحة تكبّر شجرتك',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: OakColors.ink,
                        ),
                      ),
                      const Spacer(),
                      if (nextLabel != null)
                        Text(
                          'بقي ${(next! - growth).round()}% لـ${nextLabel.$1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                          ),
                        )
                      else
                        const Text(
                          '🏆 اكتمل النمو!',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFB98A00),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _GradientMeter(value: growth / 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cloud extends StatelessWidget {
  final double width;

  const _Cloud({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 0.36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}

/// شريط نمو متدرج اللون يتحرك بسلاسة مع كل زيادة.
class _GradientMeter extends StatelessWidget {
  final double value;

  const _GradientMeter({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 12,
        color: const Color(0xFFE8EFDF),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            widthFactor: value.clamp(0.02, 1.0),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8DAE6A), OakColors.leafDark],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── بطاقة المستوى ───────────────────────

/// بطاقة «مستواي» — تعرض المستوى التكيفي الناتج عن امتحان تحديد المستوى
/// مع زر إعادة الامتحان، أو دعوة بارزة لأدائه إن لم يُنجَز بعد.
class _LevelCard extends StatelessWidget {
  final AdaptiveLevel level;
  final bool placementDone;
  final VoidCallback onRetake;

  const _LevelCard({
    required this.level,
    required this.placementDone,
    required this.onRetake,
  });

  (Color, String, String) get _style => switch (level) {
    AdaptiveLevel.weak => (
      OakColors.coral,
      '🌱',
      'سنتدرب معاً على أنشطة سهلة حتى تقوى!',
    ),
    AdaptiveLevel.medium => (
      const Color(0xFFB98A00),
      '🌿',
      'أنت في الطريق الصحيح، واصل التقدم!',
    ),
    AdaptiveLevel.advanced => (
      OakColors.leafDark,
      '🌳',
      'رائع! ستحصل على تحديات متقدمة تناسبك.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    if (!placementDone) {
      return Material(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onRetake,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [OakColors.coral, Color(0xFFF6A6A4)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: OakColors.coral.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              children: [
                Text('🎯', style: TextStyle(fontSize: 30)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'قِس مستواك أولاً!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'أجب عن أسئلة قصيرة ليصمّم نوري رحلة تناسبك',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      );
    }

    final (color, emoji, hint) = _style;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مستواك: ${level.labelAr}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                Text(
                  hint,
                  style: const TextStyle(fontSize: 11.5, height: 1.4),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onRetake,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text(
              'أعد الاختبار',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── مهمة اليوم ───────────────────────

class _DailyQuestCard extends StatelessWidget {
  final VoidCallback onTap;

  const _DailyQuestCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: OakColors.accentBlue.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [OakColors.accentBlue, Color(0xFF60A5FA)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.gps_fixed,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'مهمة اليوم',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '+10 ⭐',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'أكمل نشاطين اليوم لتنمو شجرتك 🌱',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: OakColors.accentBlue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '▶️',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── الاختصارات ───────────────────────

class _ShortcutCard extends StatelessWidget {
  final String emoji;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: gradient,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
