import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/game_content.dart';
import '../../models/adaptive_level.dart';
import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/parent_providers.dart';
import '../../providers/teacher_providers.dart';
import '../../services/message_service.dart';
import '../../widgets/oak_tree.dart';
import '../games/engine/game_models.dart';

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
                icon: Icon(Icons.healing_outlined, size: 18),
                text: 'الخطة العلاجية',
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
                _RemedialPlanTab(students: students),
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
                      child: Text(
                        student.profile.displayAvatar,
                        style: const TextStyle(fontSize: 20),
                      ),
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
  final _parentEmailController = TextEditingController();
  bool _linking = false;
  String? _linkMessage;
  bool _linkSuccess = false;

  @override
  void dispose() {
    _parentEmailController.dispose();
    super.dispose();
  }

  Future<void> _linkParent() async {
    final email = _parentEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _linkSuccess = false;
        _linkMessage = 'أدخل بريداً إلكترونياً صحيحاً لولي الأمر';
      });
      return;
    }
    setState(() => _linking = true);
    try {
      final result = await ref.read(linkParentProvider)(
        email,
        widget.student.profile.id,
      );
      setState(() {
        _linkSuccess = result == 'ok';
        _linkMessage = switch (result) {
          'ok' => 'تم ربط ولي الأمر بنجاح ✅ سيرى بيانات ابنه فوراً',
          'parent_not_found' =>
            'لا يوجد حساب «ولي أمر» بهذا البريد — اطلب منه إنشاء حساب أولاً',
          'not_teacher' => 'هذا الطالب ليس في صفوفك',
          _ => 'تعذر الربط — حاول مرة أخرى',
        };
      });
      if (_linkSuccess) {
        ref.read(soundServiceProvider).correct();
        ref.invalidate(linkedParentStudentIdsProvider);
      }
    } catch (_) {
      setState(() {
        _linkSuccess = false;
        _linkMessage = 'تعذر الربط — تحقق من الاتصال';
      });
    } finally {
      setState(() => _linking = false);
    }
  }

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
      child: SingleChildScrollView(
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
                child: Text(
                  student.profile.displayAvatar,
                  style: const TextStyle(fontSize: 22),
                ),
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
          const SizedBox(height: 12),
          _buildParentLinkCard(),
        ],
        ),
      ),
    );
  }

  /// ربط ولي الأمر: يُدخل المعلم بريد ولي الأمر فيرتبط حسابه بالطالب
  /// عبر RPC آمنة، فيرى وليُّ الأمر بيانات ابنه فوراً.
  Widget _buildParentLinkCard() {
    final linkedIds =
        ref.watch(linkedParentStudentIdsProvider).valueOrNull ??
        const <String>{};
    final alreadyLinked = linkedIds.contains(widget.student.profile.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👨‍👩‍👧', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'ربط ولي الأمر',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
              if (alreadyLinked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'مرتبط ✓',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            alreadyLinked
                ? 'لهذا الطالب ولي أمر مرتبط بالفعل، ويمكنك ربط ولي أمر إضافي.'
                : 'أدخل البريد الإلكتروني لحساب ولي الأمر ليتابع تقدم ابنه.',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _parentEmailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: 'parent@example.com',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: OakColors.accentBlue,
                ),
                onPressed: _linking ? null : _linkParent,
                icon: _linking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.link, size: 16),
                label: const Text('ربط'),
              ),
            ],
          ),
          if (_linkMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _linkMessage!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.6,
                  color: _linkSuccess
                      ? const Color(0xFF15803D)
                      : OakColors.coral,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────── الخطة العلاجية ───────────────────────

/// خطة علاجية مقترحة لطالب ضعيف أو متوسط: نقاط الضعف المرصودة من
/// جلسات اللعب، وأنشطة مقترحة تبدأ من وحداته الأضعف.
class _RemedialPlan {
  final TeacherStudent student;
  final List<String> weakUnitTitles;
  final List<Activity> suggestedActivities;

  const _RemedialPlan({
    required this.student,
    required this.weakUnitTitles,
    required this.suggestedActivities,
  });
}

class _RemedialPlanTab extends ConsumerWidget {
  final List<TeacherStudent> students;

  const _RemedialPlanTab({required this.students});

  /// Builds the plan client-side from the RLS-scoped session history:
  /// failed / struggling sessions mark a unit as weak, and the plan
  /// suggests the first activities of those units (or the syllabus start
  /// when there is no history yet).
  _RemedialPlan _planFor(
    TeacherStudent student,
    List<Map<String, dynamic>> sessions,
  ) {
    final weakUnitKeys = <String>{};
    for (final row in sessions) {
      if (row['student_id'] != student.profile.id) continue;
      final struggled =
          row['status'] == 'failed' ||
          ((row['consecutive_fails'] as num?) ?? 0) >= 2;
      if (!struggled) continue;
      final activity = findActivity(row['game_key']?.toString() ?? '');
      if (activity != null) weakUnitKeys.add(activity.unitKey);
    }

    final sourceUnits = weakUnitKeys.isEmpty
        ? kGameUnits.take(2).toList()
        : [
            for (final key in weakUnitKeys)
              if (findGameUnit(key) != null) findGameUnit(key)!,
          ];
    final suggestions = <Activity>[
      for (final unit in sourceUnits) ...unit.activities.take(2),
    ].take(3).toList();

    return _RemedialPlan(
      student: student,
      weakUnitTitles: [
        for (final key in weakUnitKeys) findGameUnit(key)?.title ?? key,
      ],
      suggestedActivities: suggestions,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions =
        ref.watch(teacherGameSessionsProvider).valueOrNull ??
        const <Map<String, dynamic>>[];
    final alerts =
        ref.watch(teacherRemedialEventsProvider).valueOrNull ??
        const <Map<String, dynamic>>[];

    final needsPlan =
        students
            .where((s) => s.progress.currentLevel != AdaptiveLevel.advanced)
            .toList()
          ..sort(
            (a, b) => a.progress.currentLevel.index.compareTo(
              b.progress.currentLevel.index,
            ),
          );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: OakColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Text('💊', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'خطط علاجية مقترحة للطلاب الضعفاء والمتوسطين، مبنية على '
                  'نتيجة امتحان تحديد المستوى وأداء الطالب في الأنشطة.',
                  style: TextStyle(fontSize: 12, height: 1.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (needsPlan.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'كل طلابك في المستوى المتقدم — لا حاجة لخطط علاجية حالياً 🎉',
                style: TextStyle(color: Colors.grey.shade600, height: 1.7),
              ),
            ),
          )
        else
          for (final student in needsPlan)
            _PlanCard(plan: _planFor(student, sessions)),
        if (alerts.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'أحدث التنبيهات',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 8),
          for (final row in alerts.reversed.take(10))
            Card(
              child: ListTile(
                leading: const Icon(Icons.priority_high, color: Colors.orange),
                title: Text(
                  row['action_taken']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(row['trigger_condition']?.toString() ?? ''),
              ),
            ),
        ],
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _RemedialPlan plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final student = plan.student;
    final level = student.progress.currentLevel;
    final isWeak = level == AdaptiveLevel.weak;
    final color = isWeak ? OakColors.coral : const Color(0xFFB98A00);
    final guidance = isWeak
        ? 'ابدأ بالأنشطة في المستوى السهل مع جلسات قصيرة، وامدح كل محاولة '
              'ناجحة بإرسال النجوم لتعزيز ثقته.'
        : 'ثبّت مهاراته بالمستوى المتوسط، وعند حصوله على ٣ نجوم مرتين '
              'متتاليتين جرّب معه المستوى المتقدم.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                student.profile.displayAvatar,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  student.profile.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'مستوى ${level.labelAr}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!student.progress.placementDone)
            Text(
              '⏳ لم يؤدِّ امتحان تحديد المستوى بعد — شجّعه على إنجازه أولاً.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.6,
              ),
            )
          else if (plan.weakUnitTitles.isNotEmpty)
            Text(
              '📉 يواجه صعوبة في: ${plan.weakUnitTitles.join('، ')}',
              style: const TextStyle(fontSize: 12, height: 1.6),
            ),
          const SizedBox(height: 8),
          const Text(
            'أنشطة مقترحة:',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final activity in plan.suggestedActivities)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: OakColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activity.emoji} ${activity.name}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '💡 $guidance',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade700,
              height: 1.7,
            ),
          ),
        ],
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
