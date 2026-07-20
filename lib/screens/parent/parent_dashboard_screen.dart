import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/adaptive_level.dart';
import '../../models/app_user.dart';
import '../../providers/core_providers.dart';
import '../../providers/parent_providers.dart';
import '../../services/message_service.dart';
import '../../widgets/oak_tree.dart';
import 'widgets/parent_palette.dart';
import 'widgets/weekly_minutes_chart.dart';

const _weekDays = [
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];

const _homeTips = [
  (
    '📖',
    'اسأله كل يوم: "ماذا تعلمت في السنديانة اليوم؟" — يساعده على تذكر المعلومات.',
  ),
  ('⏰', 'خصّص 15–20 دقيقة يومياً للتعلم في وقت ثابت — الروتين يبني العادة.'),
  ('🏅', 'احتفلوا بكل نجمة يكسبها — التشجيع اللفظي أقوى من أي مكافأة مادية.'),
  ('🌿', 'شجّعوه على شرح ما تعلّمه لأحد أفراد الأسرة — الشرح يرسّخ المعلومات.'),
];

const _achievementCatalog = [
  ('🌟', 'نجم المجموعة الشمسية', 'أكمل جميع أنشطة الفضاء'),
  ('🔥', 'المداومة الأسبوعية', '7 أيام متواصلة بدون انقطاع'),
  ('🌱', 'البذرة الأولى', 'أول نشاط مكتمل'),
  ('🏆', 'عالم الكواكب', 'رتّب جميع الكواكب بدقة'),
  ('🔬', 'عالم الأحياء', 'أكمل أنشطة التنوع البيولوجي'),
  ('💡', 'خبير الضوء', 'اجتاز مسابقة الضوء والصوت'),
];

/// لوحة ولي الأمر — نقل أمين لتصميم ParentDashboardPage المرجعي:
/// أربعة تبويبات (تقرير الطفل، الرسائل، تواصل، الإنجازات) بثيم كريمي دافئ
/// وبيانات حقيقية من Supabase (الطفل المرتبط، جلساته، ورسائل المعلم).
class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(parentChildProvider);

    return childAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('تعذر التحميل: $e'))),
      data: (child) {
        if (child == null) {
          return _NoLinkedChild(
            onSignOut: () => ref.read(authServiceProvider).signOut(),
          );
        }
        return _ParentDashboardBody(child: child);
      },
    );
  }
}

class _NoLinkedChild extends StatelessWidget {
  final VoidCallback onSignOut;

  const _NoLinkedChild({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentPalette.creamTop,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👨‍👩‍👧', style: TextStyle(fontSize: 48)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'لا يوجد طفل مرتبط بحسابك بعد',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'اطلب من معلم الصف ربط حساب طفلك بحسابك لتصلك التقارير والرسائل.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentDashboardBody extends ConsumerWidget {
  final ParentChild child;

  const _ParentDashboardBody({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacher = ref.watch(childTeacherProvider).valueOrNull;
    final messages =
        ref.watch(myMessagesProvider).valueOrNull ?? const <OakMessage>[];
    final myId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final unread = messages
        .where((m) => m.recipientId == myId && !m.read)
        .length;
    final level = OakTree.levelLabelFor(child.growthPercent);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: ParentPalette.creamTop,
        appBar: AppBar(
          backgroundColor: ParentPalette.creamTop,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ParentPalette.orange.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  child.profile.displayAvatar,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      child.profile.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: OakColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${child.profile.classroom ?? 'الصف'} · ${level.$2} ${level.$1}',
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
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: CircleAvatar(
                backgroundColor: ParentPalette.orange.withValues(alpha: 0.15),
                child: IconButton(
                  icon: const Icon(
                    Icons.logout,
                    size: 18,
                    color: ParentPalette.orangeDeep,
                  ),
                  tooltip: 'تسجيل الخروج',
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: ParentPalette.orangeDeep,
            unselectedLabelColor: Colors.grey.shade400,
            indicatorColor: ParentPalette.orange,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              fontFamily: 'Cairo',
            ),
            tabs: [
              const Tab(
                icon: Icon(Icons.trending_up, size: 18),
                text: 'تقرير الطفل',
              ),
              Tab(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.chat_bubble_outline, size: 18),
                ),
                text: 'الرسائل',
              ),
              const Tab(
                icon: Icon(Icons.phone_outlined, size: 18),
                text: 'تواصل',
              ),
              const Tab(
                icon: Icon(Icons.emoji_events_outlined, size: 18),
                text: 'الإنجازات',
              ),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: TabBarView(
              children: [
                _OverviewTab(child: child),
                _MessagesTab(
                  child: child,
                  teacher: teacher,
                  messages: messages,
                  myId: myId,
                ),
                _ContactTab(child: child, teacher: teacher),
                _AchievementsTab(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── تقرير الطفل ───────────────────────────

class _OverviewTab extends ConsumerWidget {
  final ParentChild child;

  const _OverviewTab({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly =
        ref.watch(childWeeklyMinutesProvider).valueOrNull ?? List.filled(7, 0);
    final stats =
        ref.watch(childSessionStatsProvider).valueOrNull ??
        (completed: 0, streakDays: 0);
    final topics =
        ref.watch(childTopicsProvider).valueOrNull ??
        (strong: const <String>[], weak: const <String>[]);
    final teacher = ref.watch(childTeacherProvider).valueOrNull;

    final firstName = child.profile.name.split(' ').first;
    final growth = child.growthPercent.round();
    const classAvg = 59;
    final level = OakTree.levelLabelFor(child.growthPercent);
    final totalMinutes = weekly.fold<int>(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _ChildInfoCard(child: child, teacher: teacher),
        const SizedBox(height: AppSpacing.sm),
        _SoftCard(
          gradient: const [Color(0xFFF0F9E8), Color(0xFFE8F5D8)],
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'شجرة $firstName',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: OakColors.ink,
                          ),
                        ),
                        Text(
                          '${level.$2} ${level.$1}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$growth%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          color: OakColors.leafDark,
                        ),
                      ),
                      Text(
                        'نمو الشجرة',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 150,
                width: 150,
                child: OakTree(growth: child.growthPercent),
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: growth / 100,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.6),
                  valueColor: const AlwaysStoppedAnimation(OakColors.leafDark),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'متوسط الصف: $classAvg%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      growth > classAvg
                          ? '⬆ أعلى من المتوسط'
                          : '⬇ أقل من المتوسط',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _StatTile(
              emoji: '⭐',
              label: 'نجوم',
              value: '${child.progress.oakLeaves}',
              color: const Color(0xFFB98A00),
              background: const Color(0xFFFEF9E7),
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatTile(
              emoji: '🔥',
              label: 'أيام متواصلة',
              value: '${stats.streakDays}',
              color: OakColors.coral,
              background: const Color(0xFFFEF2F2),
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatTile(
              emoji: '✅',
              label: 'أنشطة',
              value: '${stats.completed}',
              color: OakColors.leafDark,
              background: const Color(0xFFF0F9E8),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'وقت التعلم هذا الأسبوع',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: OakColors.ink,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ParentPalette.orange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: ParentPalette.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$totalMinutes دقيقة',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ParentPalette.orangeDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 140,
                child: WeeklyMinutesChart(
                  minutes: weekly,
                  dayLabels: _weekDays,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TopicsCard(
                icon: Icons.check_circle,
                iconColor: const Color(0xFF22C55E),
                title: 'يتفوق فيها',
                titleColor: const Color(0xFF166534),
                background: const Color(0xFFF0FDF4),
                chipBackground: const Color(0xFFDCFCE7),
                chipColor: const Color(0xFF15803D),
                topics: topics.strong,
                emptyText: 'لم تُحدَّد بعد',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TopicsCard(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFEAB308),
                title: 'يحتاج تعزيز',
                titleColor: const Color(0xFF854D0E),
                background: const Color(0xFFFEFCE8),
                chipBackground: const Color(0xFFFEF9C3),
                chipColor: const Color(0xFFA16207),
                topics: topics.weak,
                emptyText: 'ممتاز! لا توجد نقاط ضعف',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _SoftCard(
          gradient: const [Color(0xFFFFF9EC), Color(0xFFFEF5E0)],
          accentBorder: ParentPalette.orange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/nouri.svg',
                    width: 28,
                    height: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'نصيحة نوري لكم',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: OakColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                topics.weak.isNotEmpty
                    ? 'طفلكم يحتاج تعزيزاً في ${topics.weak.first}. اطلبوا منه شرح الموضوع بأسلوبه الخاص — هذه أفضل طريقة للتثبيت.'
                    : 'أداء $firstName ممتاز في جميع المواضيع. استمروا في التشجيع والمتابعة اليومية!',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.7,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite, size: 16, color: OakColors.coral),
                  SizedBox(width: 6),
                  Text(
                    'كيف تساعدوه في المنزل؟',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: OakColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final (emoji, tip) in [
                ..._homeTips,
                if (topics.weak.isNotEmpty)
                  (
                    '🌙',
                    'ساعدوه على مراجعة "${topics.weak.first}" — هو موضوعه الأضعف هذا الأسبوع.',
                  ),
              ])
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// «بيانات ابني» — بطاقة تعريف كاملة بالطفل: صورته واسمه وصفه ومعلمه
/// ومستواه التكيفي الناتج عن امتحان تحديد المستوى.
class _ChildInfoCard extends StatelessWidget {
  final ParentChild child;
  final AppUser? teacher;

  const _ChildInfoCard({required this.child, required this.teacher});

  @override
  Widget build(BuildContext context) {
    final level = child.progress.currentLevel;
    final placementDone = child.progress.placementDone;
    final levelColor = switch (level) {
      AdaptiveLevel.weak => OakColors.coral,
      AdaptiveLevel.medium => const Color(0xFFB98A00),
      AdaptiveLevel.advanced => OakColors.leafDark,
    };

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: ParentPalette.orange.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  child.profile.displayAvatar,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بيانات ابني',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ParentPalette.orangeDeep,
                      ),
                    ),
                    Text(
                      child.profile.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: OakColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  placementDone ? 'مستوى ${level.labelAr}' : 'لم يُقيَّم بعد',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: placementDone ? levelColor : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _InfoChip(
                emoji: '🏫',
                label: child.profile.classroom ?? 'صف غير محدد',
              ),
              _InfoChip(
                emoji: '🧑‍🏫',
                label: teacher != null
                    ? 'المعلم: ${teacher!.name}'
                    : 'لا معلم مرتبط بعد',
              ),
              _InfoChip(
                emoji: '🏅',
                label: '${child.progress.badgesUnlocked.length} شارة',
              ),
              _InfoChip(
                emoji: placementDone ? '✅' : '⏳',
                label: placementDone
                    ? 'أنجز امتحان تحديد المستوى'
                    : 'امتحان المستوى قيد الانتظار',
              ),
            ],
          ),
          if (!placementDone) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'شجّعوه على إنجاز امتحان تحديد المستوى عند دخوله القادم ليحصل '
              'على أنشطة تناسب مستواه تماماً.',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade600,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String emoji;
  final String label;

  const _InfoChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Text(
        '$emoji $label',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: OakColors.ink,
        ),
      ),
    );
  }
}

// ─────────────────────────── الرسائل ───────────────────────────

class _MessagesTab extends ConsumerStatefulWidget {
  final ParentChild child;
  final AppUser? teacher;
  final List<OakMessage> messages;
  final String? myId;

  const _MessagesTab({
    required this.child,
    required this.teacher,
    required this.messages,
    required this.myId,
  });

  @override
  ConsumerState<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends ConsumerState<_MessagesTab> {
  final _controller = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final teacher = widget.teacher;
    if (text.isEmpty || teacher == null) return;
    await ref
        .read(messageServiceProvider)
        .send(
          recipientId: teacher.id,
          body: text,
          studentId: widget.child.profile.id,
        );
    if (!mounted) return;
    setState(() {
      _sent = true;
      _controller.clear();
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _sent = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final teacherName = widget.teacher?.name ?? 'المعلم';
    final firstName = widget.child.profile.name.split(' ').first;
    final quickPhrases = [
      'شكراً على المتابعة!',
      '$firstName بحاجة لمساعدة إضافية',
      'هل يمكن موعد للتحدث؟',
      '$firstName مريض اليوم',
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Center(
          child: Column(
            children: [
              const Text(
                'رسائل المعلم',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: OakColors.ink,
                ),
              ),
              Text(
                'تواصل مع $teacherName',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.messages.isEmpty)
          _SoftCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'لا رسائل بعد — أرسل أول رسالة للمعلم من الأسفل 👇',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ),
          )
        else
          for (final msg in widget.messages.reversed)
            _MessageCard(
              message: msg,
              mine: msg.senderId == widget.myId,
              senderName: msg.senderId == widget.myId ? 'أنا' : teacherName,
              onTap: () {
                if (msg.recipientId == widget.myId && !msg.read) {
                  ref.read(messageServiceProvider).markRead(msg.id);
                }
                _openThread(context, msg, teacherName);
              },
            ),
        const SizedBox(height: AppSpacing.sm),
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.send, size: 16, color: ParentPalette.orange),
                  SizedBox(width: 6),
                  Text(
                    'رسالة جديدة للمعلم',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: OakColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final phrase in quickPhrases)
                    ActionChip(
                      label: Text(phrase, style: const TextStyle(fontSize: 11)),
                      backgroundColor: ParentPalette.orange.withValues(
                        alpha: 0.08,
                      ),
                      side: BorderSide(
                        color: ParentPalette.orange.withValues(alpha: 0.2),
                      ),
                      labelStyle: const TextStyle(
                        color: ParentPalette.orangeDeep,
                        fontWeight: FontWeight.w700,
                      ),
                      onPressed: () => _controller.text = phrase,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك لـ $teacherName...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_sent)
                const _SuccessBanner(text: 'وصلت رسالتك للمعلم!')
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ParentPalette.orange,
                    ),
                    onPressed: widget.teacher == null ? null : _send,
                    icon: const Icon(Icons.send, size: 16),
                    label: Text(
                      widget.teacher == null
                          ? 'لا يوجد معلم مرتبط بالصف بعد'
                          : 'إرسال',
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  void _openThread(BuildContext context, OakMessage msg, String teacherName) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _MessageThreadSheet(
        message: msg,
        senderName: msg.senderId == widget.myId ? 'أنا' : teacherName,
        onReply: (text) => ref
            .read(messageServiceProvider)
            .send(
              recipientId: msg.senderId == widget.myId
                  ? msg.recipientId
                  : msg.senderId,
              body: text,
              studentId: widget.child.profile.id,
            ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final OakMessage message;
  final bool mine;
  final String senderName;
  final VoidCallback onTap;

  const _MessageCard({
    required this.message,
    required this.mine,
    required this.senderName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNew = !message.read && !mine;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isNew
              ? const Border(
                  right: BorderSide(color: ParentPalette.orange, width: 4),
                )
              : Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        senderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: OakColors.ink,
                        ),
                      ),
                      if (isNew) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ParentPalette.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'جديد',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: ParentPalette.orangeDeep,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, size: 18, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime time) {
  final local = time.toLocal();
  final now = DateTime.now();
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  final hh = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final mm = local.minute.toString().padLeft(2, '0');
  final ampm = local.hour >= 12 ? 'م' : 'ص';
  if (day == today) return 'اليوم - $hh:$mm$ampm';
  if (day == today.subtract(const Duration(days: 1)))
    return 'أمس - $hh:$mm$ampm';
  return '${local.year}/${local.month}/${local.day}';
}

class _MessageThreadSheet extends StatefulWidget {
  final OakMessage message;
  final String senderName;
  final Future<void> Function(String) onReply;

  const _MessageThreadSheet({
    required this.message,
    required this.senderName,
    required this.onReply,
  });

  @override
  State<_MessageThreadSheet> createState() => _MessageThreadSheetState();
}

class _MessageThreadSheetState extends State<_MessageThreadSheet> {
  final _controller = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.senderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: OakColors.ink,
                    ),
                  ),
                  Text(
                    _formatTime(widget.message.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Text(
              widget.message.body,
              style: const TextStyle(height: 1.7),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_sent)
            const _SuccessBanner(text: 'تم إرسال ردّك بنجاح')
          else ...[
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب ردّك على المعلم...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ParentPalette.orange,
                ),
                onPressed: () async {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  await widget.onReply(text);
                  if (mounted) setState(() => _sent = true);
                },
                icon: const Icon(Icons.send, size: 16),
                label: const Text('إرسال الرد'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────── تواصل ───────────────────────────

class _ContactTab extends ConsumerStatefulWidget {
  final ParentChild child;
  final AppUser? teacher;

  const _ContactTab({required this.child, required this.teacher});

  @override
  ConsumerState<_ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends ConsumerState<_ContactTab> {
  final _controller = TextEditingController();
  bool _sent = false;

  static const _quickReasons = [
    'غياب اليوم',
    'استفسار عن الأداء',
    'طلب اجتماع',
    'تبليغ عن مشكلة',
    'شكر وتقدير',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final teacher = widget.teacher;
    if (text.isEmpty || teacher == null) return;
    await ref
        .read(messageServiceProvider)
        .send(
          recipientId: teacher.id,
          body: '[رسالة للمدرسة] $text',
          studentId: widget.child.profile.id,
        );
    if (!mounted) return;
    setState(() {
      _sent = true;
      _controller.clear();
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _sent = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final teacherName = widget.teacher?.name ?? 'المعلم';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const Center(
          child: Text(
            'تواصل معنا',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: OakColors.ink,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SoftCard(
          gradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.menu_book, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacherName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: OakColors.ink,
                          ),
                        ),
                        Text(
                          'معلم الصف الرابع · العلوم',
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
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('اتصال'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                      ),
                      onPressed: () =>
                          DefaultTabController.of(context).animateTo(1),
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('رسالة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SoftCard(
          gradient: const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🏫', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المدرسة',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: OakColors.ink,
                          ),
                        ),
                        Text(
                          'الإدارة المدرسية',
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
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('042345678'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: ParentPalette.orange,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'رسالة للمدرسة',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: OakColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final reason in _quickReasons)
                    ActionChip(
                      label: Text(reason, style: const TextStyle(fontSize: 11)),
                      onPressed: () => _controller.text = reason,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك للمدرسة...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_sent)
                const _SuccessBanner(text: 'وصلت رسالتك للمدرسة!')
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ParentPalette.orange,
                    ),
                    onPressed: widget.teacher == null ? null : _send,
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('إرسال'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⏰ أوقات التواصل',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: OakColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final (label, value) in const [
                ('الأحد – الخميس', '7:30ص – 2:30م'),
                ('الاستقبال والإدارة', '7:30ص – 12:00م'),
                ('ساعات المعلم للتواصل', '11:00ص – 12:00م'),
              ])
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: OakColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ─────────────────────────── الإنجازات ───────────────────────────

class _AchievementsTab extends StatelessWidget {
  final ParentChild child;

  const _AchievementsTab({required this.child});

  @override
  Widget build(BuildContext context) {
    final firstName = child.profile.name.split(' ').first;
    // reference rule: achievements unlock as the tree grows
    final earnedCount = child.growthPercent <= 0
        ? 0
        : ((child.growthPercent / 20).floor() + 1).clamp(1, 4);
    final earned = _achievementCatalog.take(earnedCount).toList();
    final locked = _achievementCatalog.skip(earned.length).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'إنجازات $firstName',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: OakColors.ink,
                ),
              ),
              Text(
                '${earned.length} من ${_achievementCatalog.length} مكتملة',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SoftCard(
          gradient: const [Color(0xFFFEF9E7), Color(0xFFFEF5D0)],
          child: Column(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: earned.length / _achievementCatalog.length,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFFF3E8C0),
                      valueColor: const AlwaysStoppedAnimation(
                        ParentPalette.orange,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${earned.length}/${_achievementCatalog.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: ParentPalette.orangeDeep,
                            ),
                          ),
                          Text(
                            'إنجاز',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                earned.length >= 4
                    ? 'أداء رائع! استمر!'
                    : 'لديه إنجازات رائعة أمامه!',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (earned.isNotEmpty) ...[
          Text(
            '✅ مكتملة',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AchievementGrid(entries: earned, locked: false),
          const SizedBox(height: AppSpacing.md),
        ],
        if (locked.isNotEmpty) ...[
          Text(
            '🔒 قادمة',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AchievementGrid(entries: locked, locked: true),
          const SizedBox(height: AppSpacing.md),
        ],
        _SoftCard(
          gradient: const [Color(0xFFFFF9EC), Color(0xFFFEF5E0)],
          accentBorder: ParentPalette.orange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💬 كلمة تشجيع',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: OakColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '"$firstName يُظهر تقدماً رائعاً في رحلته التعليمية. شجّعوه وسيصل إلى قمة السنديانة!"',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.7,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '— نوري، مساعد السنديانة الذكي 🐿️',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ParentPalette.orange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  final List<(String, String, String)> entries;
  final bool locked;

  const _AchievementGrid({required this.entries, required this.locked});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final (emoji, title, desc) = entries[index];
        return Opacity(
          opacity: locked ? 0.6 : 1,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: locked
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFFEF9E7), Color(0xFFFEF0C0)],
                    ),
              color: locked ? Colors.white : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: locked ? Colors.grey.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: locked ? Colors.grey.shade500 : OakColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────── shared bits ───────────────────────────

class _SoftCard extends StatelessWidget {
  final Widget child;
  final List<Color>? gradient;
  final Color? accentBorder;

  const _SoftCard({required this.child, this.gradient, this.accentBorder});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: gradient == null ? Colors.white : null,
        gradient: gradient == null ? null : LinearGradient(colors: gradient!),
        borderRadius: BorderRadius.circular(16),
        border: accentBorder != null
            ? Border(right: BorderSide(color: accentBorder!, width: 3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  final Color background;

  const _StatTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final Color background;
  final Color chipBackground;
  final Color chipColor;
  final List<String> topics;
  final String emptyText;

  const _TopicsCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.background,
    required this.chipBackground,
    required this.chipColor,
    required this.topics,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (topics.isEmpty)
            Text(
              emptyText,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            )
          else
            for (final topic in topics)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: chipBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  topic,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: chipColor,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String text;

  const _SuccessBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF22C55E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF15803D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
