import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';

/// صفحة المعلم: لوحة تحكم لاستقبال نتائج الأنشطة وحلول الطلاب ومساراتهم
/// التكيفية لحظياً (`teacher_update` صادر ووارد).
class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(teacherGameSessionsProvider);
    final remedialAsync = ref.watch(teacherRemedialEventsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم المعلم'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authServiceProvider).signOut(),
            ),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'الجلسات الحية'),
            Tab(text: 'تنبيهات الخطة العلاجية'),
          ]),
        ),
        body: TabBarView(
          children: [
            sessionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('تعذر التحميل: $e')),
              data: (rows) => rows.isEmpty
                  ? const Center(child: Text('لا نشاط حالياً'))
                  : ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[rows.length - 1 - index];
                        return ListTile(
                          leading: const Icon(Icons.videogame_asset_outlined),
                          title: Text('${row['game_key']} — ${row['level']}'),
                          subtitle: Text('محاولات: ${row['attempts_count']} | الحالة: ${row['status']}'),
                        );
                      },
                    ),
            ),
            remedialAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('تعذر التحميل: $e')),
              data: (rows) => rows.isEmpty
                  ? const Center(child: Text('لا تنبيهات حالياً'))
                  : ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[rows.length - 1 - index];
                        return ListTile(
                          leading: const Icon(Icons.priority_high, color: Colors.orange),
                          title: Text(row['action_taken']?.toString() ?? ''),
                          subtitle: Text(row['trigger_condition']?.toString() ?? ''),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
