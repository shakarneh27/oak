import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/adaptive_level.dart';
import '../../models/student_progress.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';

/// صفحة ولي الأمر: متابعة تقارير الأداء والشارات وتوصيات الخطة العلاجية
/// (`parent_sync_report`).
class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(linkedStudentsProvider);
    final remedialAsync = ref.watch(parentRemedialEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة ولي الأمر'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => ref.read(authServiceProvider).signOut()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('أبناؤك', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          childrenAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('تعذر التحميل: $e'),
            data: (children) => children.isEmpty
                ? const Text('لا يوجد أبناء مرتبطون بحسابك بعد.')
                : Column(
                    children: children.map((entry) {
                      final profile = entry['profile'] as Map<String, dynamic>;
                      final progressMap = entry['progress'] as Map<String, dynamic>?;
                      final progress = progressMap == null ? null : StudentProgress.fromMap(progressMap);
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.face_outlined),
                          title: Text(profile['name']?.toString() ?? ''),
                          subtitle: Text(
                            progress == null
                                ? 'لا يوجد تقدم مسجل بعد'
                                : 'المستوى: ${progress.currentLevel.labelAr} | أوراق: ${progress.oakLeaves} | شارات: ${progress.badgesUnlocked.length}',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 24),
          Text('توصيات الخطة العلاجية', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          remedialAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('تعذر التحميل: $e'),
            data: (rows) => rows.isEmpty
                ? const Text('لا توصيات حالياً')
                : Column(
                    children: rows.reversed.take(15).map((row) {
                      return ListTile(
                        leading: const Icon(Icons.lightbulb_outline),
                        title: Text(row['action_taken']?.toString() ?? ''),
                        subtitle: Text(row['trigger_condition']?.toString() ?? ''),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
