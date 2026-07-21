import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/placement_questions.dart';
import '../../models/adaptive_level.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';

/// امتحان تحديد المستوى: 9 أسئلة علمية حقيقية متدرجة (سهل/متوسط/متقدم)
/// بنقاط موزونة، تحدد مستوى الطالب التكيفي (ضعيف/متوسط/متقدم) وتحفظه في
/// ملفه — مع إمكانية الخروج في أي وقت والإعادة لاحقاً من لوحته.
class DiagnosticTestScreen extends ConsumerStatefulWidget {
  const DiagnosticTestScreen({super.key});

  @override
  ConsumerState<DiagnosticTestScreen> createState() =>
      _DiagnosticTestScreenState();
}

class _DiagnosticTestScreenState extends ConsumerState<DiagnosticTestScreen> {
  static const _maxScore = 18;

  bool _started = false;
  int _index = 0;
  int _score = 0;
  int? _selected;
  String? _resultLevel;
  bool _saving = false;

  PlacementQuestion get _entry => kPlacementQuestions[_index];

  Future<void> _answer(int optionIndex) async {
    if (_selected != null) return;
    final correct = optionIndex == _entry.question.correct;
    final sound = ref.read(soundServiceProvider);
    correct ? sound.correct() : sound.wrong();
    setState(() {
      _selected = optionIndex;
      if (correct) _score += _entry.weight;
    });
  }

  Future<void> _next() async {
    ref.read(soundServiceProvider).click();
    if (_index < kPlacementQuestions.length - 1) {
      setState(() {
        _index += 1;
        _selected = null;
      });
      return;
    }
    // grade and persist
    setState(() => _saving = true);
    final level = placementLevelFor(_score);
    try {
      final client = ref.read(supabaseClientProvider);
      final studentId = client.auth.currentUser!.id;
      await client
          .from('student_progress')
          .update({
            'current_level': level,
            'placement_done': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('student_id', studentId);
      await ref.read(realtimeServiceProvider).logEvent(
            studentId: studentId,
            eventType: 'submit_diagnostic_test',
            payload: {'score': _score, 'max': _maxScore, 'level': level},
          );
      ref.invalidate(studentProgressProvider);
    } catch (_) {
      // keep the result screen even if saving failed
    }
    final sound = ref.read(soundServiceProvider);
    sound.complete(level == 'Advanced' ? 3 : level == 'Medium' ? 2 : 1);
    sound.speak('أحسنت! مستواك ${AdaptiveLevelX.fromString(level).labelAr}');
    if (mounted) {
      setState(() {
        _saving = false;
        _resultLevel = level;
      });
    }
  }

  /// الخروج من الامتحان دون إكماله — يعود الطالب إلى لوحته ويمكنه إعادته
  /// لاحقاً من بطاقة «قِس مستواك». نؤكّد فقط إن كان قد بدأ الإجابة.
  Future<void> _exit() async {
    ref.read(soundServiceProvider).click();
    final started = _started && _resultLevel == null;
    if (started) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('الخروج من الامتحان؟'),
          content: const Text(
            'لن تُحفظ إجاباتك الحالية، ويمكنك إعادة الامتحان في أي وقت من '
            'صفحتك الرئيسية. هل تريد الخروج؟',
            style: TextStyle(height: 1.7),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('متابعة الامتحان'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: OakColors.coral),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('خروج'),
            ),
          ],
        ),
      );
      if (leave != true) return;
    }
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OakColors.cream,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: OakColors.forest,
        surfaceTintColor: OakColors.forest,
        automaticallyImplyLeading: false,
        title: const Text(
          'امتحان تحديد المستوى',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [OakColors.forest, OakColors.forestLight, Color(0xFF486E42)],
            ),
          ),
        ),
        actions: [
          // زر الخروج من الامتحان — متاح في كل المراحل عدا شاشة النتيجة
          if (_resultLevel == null && !_saving)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton.icon(
                onPressed: _exit,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.close, size: 18),
                label: const Text(
                  'خروج',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _saving
              ? const Center(child: CircularProgressIndicator())
              : _resultLevel != null
                  ? _buildResult()
                  : _started
                      ? _buildQuestion()
                      : _buildIntro(),
        ),
      ),
    );
  }

  // ── مقدمة الامتحان ───────────────────────────────────────────────────
  Widget _buildIntro() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [OakColors.leafLight, OakColors.cream],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: OakColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: SvgPicture.asset('assets/images/nouri.svg',
                width: 110, height: 110),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text('مرحباً! أنا نوري 🐿️',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: OakColors.ink)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'سأطرح عليك 9 أسئلة ممتعة لأعرف من أين نبدأ رحلتنا.\nلا تقلق — لا يوجد رسوب هنا أبداً! 🌱',
            textAlign: TextAlign.center,
            style: TextStyle(color: OakColors.ink.withValues(alpha: 0.7), height: 1.8),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: OakColors.leafLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OakColors.primary.withValues(alpha: 0.4)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📋 ماذا سيحدث؟',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, color: OakColors.ink)),
              SizedBox(height: 8),
              _IntroBullet(text: 'أسئلة متدرجة: سهلة ثم متوسطة ثم متقدمة'),
              _IntroBullet(text: 'حسب إجاباتك يتحدد مستوى الألعاب المناسب لك'),
              _IntroBullet(
                  text: 'يمكنك الخروج أو إعادة الامتحان لاحقاً من صفحتك'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: OakColors.leafDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
          onPressed: () {
            ref.read(soundServiceProvider).click();
            setState(() => _started = true);
          },
          icon: const Icon(Icons.rocket_launch_outlined),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('ابدأ الامتحان',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: _exit,
            style: TextButton.styleFrom(foregroundColor: OakColors.ink),
            child: const Text('ربما لاحقاً — العودة إلى صفحتي'),
          ),
        ),
      ],
    );
  }

  // ── سؤال ─────────────────────────────────────────────────────────────
  Widget _buildQuestion() {
    final question = _entry.question;
    final answered = _selected != null;
    final (diffEmoji, diffLabel, diffColor) = switch (_entry.weight) {
      1 => ('🟢', 'سهل', OakColors.leafDark),
      2 => ('🟡', 'متوسط', const Color(0xFFB98A00)),
      _ => ('🔴', 'متقدم', OakColors.coral),
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('سؤال ${_index + 1}/${kPlacementQuestions.length}',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: OakColors.ink.withValues(alpha: 0.6))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: diffColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: diffColor.withValues(alpha: 0.4)),
              ),
              child: Text('$diffEmoji $diffLabel',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: diffColor)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_index + (answered ? 1 : 0)) / kPlacementQuestions.length,
            minHeight: 9,
            backgroundColor: OakColors.secondary,
            valueColor: const AlwaysStoppedAnimation(OakColors.leafDark),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: OakColors.primary.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(question.text,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  height: 1.6,
                  color: OakColors.ink)),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: !answered
                  ? Colors.white
                  : i == question.correct
                      ? OakColors.leafLight.withValues(alpha: 0.6)
                      : i == _selected
                          ? OakColors.coral.withValues(alpha: 0.12)
                          : Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: answered ? null : () => _answer(i),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: !answered
                          ? OakColors.secondary
                          : i == question.correct
                              ? OakColors.leafDark
                              : i == _selected
                                  ? OakColors.coral
                                  : OakColors.secondary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(question.options[i],
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                                color: OakColors.ink)),
                      ),
                      if (answered && i == question.correct) const Text('✅'),
                      if (answered &&
                          i == _selected &&
                          i != question.correct)
                        const Text('❌'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (answered) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _selected == question.correct
                  ? OakColors.leafLight.withValues(alpha: 0.5)
                  : OakColors.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _selected == question.correct
                    ? OakColors.leafDark.withValues(alpha: 0.4)
                    : OakColors.gold.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selected == question.correct ? '🌟' : '💡'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(question.explanation,
                      style: const TextStyle(
                          height: 1.7,
                          fontWeight: FontWeight.w600,
                          color: OakColors.ink)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: OakColors.leafDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _next,
            child: Text(
                _index < kPlacementQuestions.length - 1
                    ? 'السؤال التالي ←'
                    : 'اعرض نتيجتي 🎯',
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ],
    );
  }

  // ── النتيجة ──────────────────────────────────────────────────────────
  Widget _buildResult() {
    final level = AdaptiveLevelX.fromString(_resultLevel!);
    final (emoji, message, accent) = switch (level) {
      AdaptiveLevel.advanced => (
          '🏆',
          'مستواك متقدم! ستبدأ بتحديات قوية تناسب ذكاءك.',
          OakColors.leafDark,
        ),
      AdaptiveLevel.medium => (
          '🌟',
          'مستواك متوسط! ستبدأ بألعاب متوازنة وتتقدم بسرعة.',
          const Color(0xFFB98A00),
        ),
      AdaptiveLevel.weak => (
          '🌱',
          'سنبدأ معاً من الأساسيات خطوة بخطوة — وستتفاجأ بسرعة تقدمك!',
          OakColors.coral,
        ),
    };
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [accent.withValues(alpha: 0.18), OakColors.cream],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 64)),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text('مستواك: ${level.labelAr}',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: accent)),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text('النتيجة: $_score من $_maxScore نقطة',
              style: TextStyle(
                  color: OakColors.ink.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: OakColors.leafLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OakColors.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              SvgPicture.asset('assets/images/nouri.svg',
                  width: 44, height: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message,
                    style: const TextStyle(
                        height: 1.7,
                        fontWeight: FontWeight.w600,
                        color: OakColors.ink)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: OakColors.leafDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
          onPressed: () {
            ref.read(soundServiceProvider).click();
            context.go('/dashboard');
          },
          icon: const Icon(Icons.park_outlined),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('انطلق إلى شجرتك 🌳',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

class _IntroBullet extends StatelessWidget {
  final String text;

  const _IntroBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(
                  height: 1.6,
                  fontWeight: FontWeight.w900,
                  color: OakColors.leafDark)),
          Expanded(
            child: Text(text,
                style: const TextStyle(height: 1.7, color: OakColors.ink)),
          ),
        ],
      ),
    );
  }
}
