import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/adaptive_level.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/main_bottom_nav.dart';

/// شجرة التقدم: خريطة تفاعلية مرئية تظهر نمو شجرة السنديانة مع كل إنجاز،
/// تُزامَن فوراً عبر `sync_tree_growth` (هنا: Supabase Realtime).
class ProgressTreeScreen extends ConsumerWidget {
  const ProgressTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    if (studentId == null) return const SizedBox.shrink();
    final progressAsync = ref.watch(studentProgressProvider(studentId));

    return Scaffold(
      appBar: AppBar(title: const Text('شجرة التقدم')),
      bottomNavigationBar: const MainBottomNav(currentPath: '/progress-tree'),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذر التحميل: $e')),
        data: (progress) {
          final stage = progress?.treeGrowthStage ?? 0;
          final leaves = progress?.oakLeaves ?? 0;
          final level = progress?.currentLevel.labelAr ?? '-';
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.park_rounded,
                  size: (80 + stage * 12).clamp(80, 220).toDouble(),
                  color: OakColors.leafDark,
                ),
                const SizedBox(height: 16),
                Text(
                  'مرحلة النمو: $stage',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('أوراق السنديانة: $leaves 🍃'),
                const SizedBox(height: 8),
                Text('المستوى الحالي: $level'),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  children: (progress?.badgesUnlocked ?? const [])
                      .map((b) => Chip(label: Text(b)))
                      .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
