import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/main_bottom_nav.dart';
import '../../widgets/oak_tree.dart';

/// لوحة الطالب — على نمط DashboardPage المرجعي: شريط علوي بالاسم
/// والمستوى وعدادات (نجوم/أوراق/أيام)، شجرة سنديانة كبيرة تنمو مع تقدمه،
/// نوري يلوّح ويرحب، وبطاقة «مهمة اليوم».
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // top bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white),
                    boxShadow: [
                      BoxShadow(
                        color: OakColors.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: OakColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🧒', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.name ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: OakColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${level.$2} ${level.$1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: OakColors.leafDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatChip(
                        emoji: '⭐',
                        value: '${progress?.oakLeaves ?? 0}',
                        background: const Color(0xFFFEF9E7),
                        color: const Color(0xFFB98A00),
                      ),
                      const SizedBox(width: 6),
                      _StatChip(
                        emoji: '🍃',
                        value: '${progress?.treeGrowthStage ?? 0}',
                        background: const Color(0xFFF0FDF4),
                        color: const Color(0xFF15803D),
                      ),
                      const SizedBox(width: 6),
                      _StatChip(
                        emoji: '🏅',
                        value: '${progress?.badgesUnlocked.length ?? 0}',
                        background: const Color(0xFFFFF7ED),
                        color: const Color(0xFFC2410C),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // big tree + Nouri
                SizedBox(
                  height: 360,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(child: OakTree(growth: growth)),
                      PositionedDirectional(
                        bottom: 24,
                        start: 8,
                        child: GestureDetector(
                          onTap: () {
                            ref.read(soundServiceProvider).click();
                            context.push('/ai-assistant');
                          },
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
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
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
                                width: 90,
                                height: 90,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // daily quest
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () {
                      ref.read(soundServiceProvider).click();
                      context.push('/units');
                    },
                    borderRadius: BorderRadius.circular(20),
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
                                  color: OakColors.accentBlue.withValues(
                                    alpha: 0.12,
                                  ),
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
                const SizedBox(height: 8),
                // quick shortcuts
                Row(
                  children: [
                    Expanded(
                      child: _ShortcutCard(
                        emoji: '🌳',
                        label: 'شجرتي',
                        onTap: () => context.push('/progress-tree'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ShortcutCard(
                        emoji: '🐿️',
                        label: 'اسأل نوري',
                        onTap: () => context.push('/ai-assistant'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ShortcutCard(
                        emoji: '🏆',
                        label: 'إنجازاتي',
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
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final Color background;
  final Color color;

  const _StatChip({
    required this.emoji,
    required this.value,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$emoji $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: OakColors.secondary),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
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
