import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/main_bottom_nav.dart';

/// الصفحة الرئيسية: لوحة قيادة الطالب، إشعارات فورية وزر انطلاق سريع.
/// تقابل حدث `get_realtime_announcements`.
class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final studentId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final progressAsync = studentId == null
        ? const AsyncValue.data(null)
        : ref.watch(studentProgressProvider(studentId));
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: profileAsync.when(
          data: (user) =>
              Text(user == null ? 'مرحباً' : 'مرحباً، ${user.name} 🌳'),
          loading: () => const Text('مرحباً'),
          error: (_, _) => const Text('مرحباً'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'مساعد السنديانة الذكي',
            onPressed: () => context.push('/ai-assistant'),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(currentPath: '/dashboard'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(announcementsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            progressAsync.when(
              data: (progress) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.eco, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          progress == null
                              ? 'لنبدأ رحلتنا مع السنديانة!'
                              : 'أوراقك: ${progress.oakLeaves} 🍃  |  شاراتك: ${progress.badgesUnlocked.length} 🏅',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/units'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('انطلق الآن'),
            ),
            const SizedBox(height: 24),
            Text(
              'إشعارات اليوم',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            announcementsAsync.when(
              data: (rows) => rows.isEmpty
                  ? const Text('لا إشعارات جديدة')
                  : Column(
                      children: rows.reversed.take(10).map((row) {
                        return ListTile(
                          leading: const Icon(
                            Icons.notifications_active_outlined,
                          ),
                          title: Text(row['event_type']?.toString() ?? ''),
                          subtitle: Text(row['created_at']?.toString() ?? ''),
                        );
                      }).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('تعذر تحميل الإشعارات: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
