import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/adaptive_level.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/main_bottom_nav.dart';
import '../../widgets/oak_tree.dart';

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
          final growth = (stage * 5).clamp(0, 100).toDouble();
          final leaves = progress?.oakLeaves ?? 0;
          final level = progress?.currentLevel.labelAr ?? '-';
          final stageLabel = OakTree.levelLabelFor(growth);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFDDF0FF), Color(0xFFF6FBEF)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: OakColors.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 380,
                      child: OakTree(growth: growth),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${stageLabel.$2} ${stageLabel.$1}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'نمو الشجرة: ${growth.round()}% · أوراق: $leaves 🍃 · '
                    'المستوى: $level',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.7),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: (progress?.badgesUnlocked ?? const [])
                        .map((b) => Chip(label: Text(b)))
                        .toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
