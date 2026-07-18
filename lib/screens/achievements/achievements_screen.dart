import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/main_bottom_nav.dart';

/// صفحة الإنجازات: خزنة الشارات والمكافآت (`unlock_badge_trigger`).
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    if (studentId == null) return const SizedBox.shrink();
    final progressAsync = ref.watch(studentProgressProvider(studentId));

    return Scaffold(
      appBar: AppBar(title: const Text('الإنجازات')),
      bottomNavigationBar: const MainBottomNav(currentPath: '/achievements'),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذر التحميل: $e')),
        data: (progress) {
          final badges = progress?.badgesUnlocked ?? const [];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatChip(icon: Icons.eco, label: 'أوراق سنديانة', value: '${progress?.oakLeaves ?? 0}'),
                    _StatChip(icon: Icons.emoji_events, label: 'شارات', value: '${badges.length}'),
                  ],
                ),
              ),
              Expanded(
                child: badges.isEmpty
                    ? const Center(child: Text('لا شارات بعد — انطلق والعب لتحصل عليها!'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: badges.length,
                        itemBuilder: (context, index) => Card(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.military_tech, size: 32),
                                  const SizedBox(height: 8),
                                  Text(badges[index], textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
