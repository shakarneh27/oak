import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/parent_providers.dart';
import '../../providers/teacher_providers.dart';
import '../../services/message_service.dart';
import '../../widgets/oak_tree.dart';

/// لوحة المعلم — على نمط TeacherDashboardPage المرجعي: نظرة عامة على
/// الصف، قائمة الطلاب مع بطاقة تفصيلية وإرسال نجوم، تنبيهات الخطة
/// العلاجية، ورسائل أولياء الأمور.
class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final students =
        ref.watch(teacherStudentsProvider).valueOrNull ??
        const <TeacherStudent>[];
    final messages =
        ref.watch(myMessagesProvider).valueOrNull ?? const <OakMessage>[];
    final myId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final unread = messages
        .where((m) => m.recipientId == myId && !m.read)
        .length;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: OakColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text('🧑‍🏫', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile?.name ?? 'المعلم',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      (profile?.managedClassrooms.isNotEmpty ?? false)
                          ? 'صفوف: ${profile!.managedClassrooms.join('، ')}'
                          : 'لوحة المعلم',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
              onPressed: () => ref.read(authServiceProvider).signOut(),
            ),
          ],
          bottom: TabBar(
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              fontFamily: 'Cairo',
            ),
            tabs: [
              const Tab(
                icon: Icon(Icons.insights, size: 18),
                text: 'نظرة عامة',
              ),
              const Tab(
                icon: Icon(Icons.groups_outlined, size: 18),
                text: 'الطلاب',
              ),
              const Tab(
                icon: Icon(Icons.notifications_active_outlined, size: 18),
                text: 'تنبيهات',
              ),
              Tab(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.chat_bubble_outline, size: 18),
                ),
                text: 'الرسائل',
              ),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: TabBarView(
              children: [
                _OverviewTab(students: students),
                _StudentsTab(students: students),
                const _AlertsTab(),
                _MessagesTab(messages: messages, myId: myId),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── نظرة عامة ───────────────────────────

class _OverviewTab extends StatelessWidget {
  final List<TeacherStudent> students;

  const _OverviewTab({required this.students});

  @override
  Widget build(BuildContext context) {
    final avgGrowth = students.isEmpty
        ? 0
        : students.map((s) => s.growthPercent).reduce((a, b) => a + b) ~/
              students.length;
    final totalStars = students.fold<int>(
      0,
      (sum, s) => sum + s.progress.oakLeaves,
    );
    final needsHelp = students.where((s) => s.growthPercent < 30).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _StatCard(
              emoji: '👥',
              label: 'عدد الطلاب',
              value: '${students.length}',
              background: const Color(0xFFEFF6FF),
            ),
            const SizedBox(width: 10),
            _StatCard(
              emoji: '🌱',
              label: 'متوسط النمو',
              value: '$avgGrowth%',
              background: const Color(0xFFF0FDF4),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatCard(
              emoji: '⭐',
              label: 'مجموع النجوم',
              value: '$totalStars',
              background: const Color(0xFFFEF9E7),
            ),
            const SizedBox(width: 10),
            _StatCard(
              emoji: '⚠️',
              label: 'يحتاجون دعماً',
              value: '$needsHelp',
              background: const Color(0xFFFEF2F2),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'نمو طلابك',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (students.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'لا يوجد طلاب مرتبطون بصفوفك بعد. عند تسجيل الطلاب بنفس اسم صفك ستظهر بياناتهم هنا فوراً.',
                style: TextStyle(color: Colors.grey.shade600, height: 1.7),
              ),
            ),
          )
        else
          for (final student in [
            ...students,
          ]..sort((a, b) => b.growthPercent.compareTo(a.growthPercent)))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      student.profile.name.split(' ').first,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: student.growthPercent / 100,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation(
                          student.growthPercent < 30
                              ? OakColors.coral
                              : OakColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${student.growthPercent.round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color background;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── الطلاب ───────────────────────────

class _StudentsTab extends ConsumerWidget {
  final List<TeacherStudent> students;

  const _StudentsTab({required this.students});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (students.isEmpty) {
      return Center(
        child: Text(
          'لا يوجد طلاب بعد',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final level = OakTree.levelLabelFor(student.growthPercent);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _openStudent(context, ref, student),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: OakColors.secondary),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: OakColors.secondary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🧒', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.profile.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${level.$2} ${level.$1} · ⭐ ${student.progress.oakLeaves}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${student.growthPercent.round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: OakColors.leafDark,
                            ),
                          ),
                          Text(
                            'النمو',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openStudent(
    BuildContext context,
    WidgetRef ref,
    TeacherStudent student,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _StudentSheet(student: student),
    );
  }
}

class _StudentSheet extends ConsumerStatefulWidget {
  final TeacherStudent student;

  const _StudentSheet({required this.student});

  @override
  ConsumerState<_StudentSheet> createState() => _StudentSheetState();
}

class _StudentSheetState extends ConsumerState<_StudentSheet> {
  int _stars = 1;
  bool _sent = false;
  String? _error;

  Future<void> _send() async {
    try {
      await ref.read(awardStarsProvider)(widget.student.profile.id, _stars);
      ref.read(soundServiceProvider).star();
      ref.invalidate(teacherStudentsProvider);
      setState(() {
        _sent = true;
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'تعذر الإرسال — تحقق من الصلاحيات');
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final level = OakTree.levelLabelFor(student.growthPercent);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: OakColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text('🧒', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.profile.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${level.$2} ${level.$1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatCard(
                emoji: '🌱',
                label: 'نمو الشجرة',
                value: '${student.growthPercent.round()}%',
                background: const Color(0xFFF0FDF4),
              ),
              const SizedBox(width: 8),
              _StatCard(
                emoji: '⭐',
                label: 'النجوم',
                value: '${student.progress.oakLeaves}',
                background: const Color(0xFFFEF9E7),
              ),
              const SizedBox(width: 8),
              _StatCard(
                emoji: '🏅',
                label: 'الشارات',
                value: '${student.progress.badgesUnlocked.length}',
                background: const Color(0xFFFFF7ED),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: student.growthPercent / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation(OakColors.primary),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9E7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أرسل نجوماً لـ ${student.profile.name.split(' ').first}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final n in const [1, 2, 3, 5])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Material(
                            color: _stars == n
                                ? const Color(0xFFFACC15)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () => setState(() => _stars = n),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Text(
                                  '$n⭐',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: _stars == n
                                        ? Colors.white
                                        : const Color(0xFFA16207),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_sent)
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFF22C55E),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'تم الإرسال!',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  )
                else ...[
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFACC15),
                      ),
                      onPressed: _send,
                      icon: const Icon(Icons.star, size: 16),
                      label: Text('إرسال $_stars نجمة'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── التنبيهات ───────────────────────────

class _AlertsTab extends ConsumerWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remedialAsync = ref.watch(teacherRemedialEventsProvider);
    return remedialAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('تعذر التحميل: $e')),
      data: (rows) => rows.isEmpty
          ? Center(
              child: Text(
                'لا تنبيهات حالياً 🎉',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[rows.length - 1 - index];
                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.priority_high,
                      color: Colors.orange,
                    ),
                    title: Text(
                      row['action_taken']?.toString() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(row['trigger_condition']?.toString() ?? ''),
                  ),
                );
              },
            ),
    );
  }
}

// ─────────────────────────── الرسائل ───────────────────────────

class _MessagesTab extends ConsumerStatefulWidget {
  final List<OakMessage> messages;
  final String? myId;

  const _MessagesTab({required this.messages, required this.myId});

  @override
  ConsumerState<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends ConsumerState<_MessagesTab> {
  final _controllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return Center(
        child: Text(
          'لا رسائل من أولياء الأمور بعد',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final msg in widget.messages.reversed)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        msg.senderId == widget.myId ? 'أنا' : 'ولي أمر',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (!msg.read && msg.recipientId == widget.myId)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: OakColors.coral.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'جديد',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: OakColors.coral,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(msg.body, style: const TextStyle(height: 1.6)),
                  if (msg.recipientId == widget.myId) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controllers.putIfAbsent(
                              msg.id,
                              TextEditingController.new,
                            ),
                            decoration: InputDecoration(
                              hintText: 'رد سريع...',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, size: 20),
                          onPressed: () async {
                            final text =
                                _controllers[msg.id]?.text.trim() ?? '';
                            if (text.isEmpty) return;
                            await ref
                                .read(messageServiceProvider)
                                .send(recipientId: msg.senderId, body: text);
                            ref.read(messageServiceProvider).markRead(msg.id);
                            _controllers[msg.id]?.clear();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم إرسال الرد ✅'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
