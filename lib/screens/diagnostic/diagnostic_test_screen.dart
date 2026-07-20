import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../data/placement_questions.dart';
import '../../models/adaptive_level.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';

/// امتحان تحديد المستوى: 9 أسئلة علمية حقيقية متدرجة (سهل/متوسط/متقدم)
/// بنقاط موزونة، تحدد مستوى الطالب التكيفي (ضعيف/متوسط/متقدم) وتحفظه في
/// ملفه — مع إمكانية الإعادة لاحقاً من لوحته.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('امتحان تحديد المستوى')),
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
          child: SvgPicture.asset('assets/images/nouri.svg',
              width: 110, height: 110),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text('مرحباً! أنا نوري 🐿️',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'سأطرح عليك 9 أسئلة ممتعة لأعرف من أين نبدأ رحلتنا.\nلا تقلق — لا يوجد رسوب هنا أبداً! 🌱',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.8),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9E8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📋 ماذا سيحدث؟',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text('• أسئلة متدرجة: سهلة ثم متوسطة ثم متقدمة',
                  style: TextStyle(height: 1.8)),
              Text('• حسب إجاباتك يتحدد مستوى الألعاب المناسب لك',
                  style: TextStyle(height: 1.8)),
              Text('• يمكنك إعادة الامتحان لاحقاً من صفحتك الرئيسية',
                  style: TextStyle(height: 1.8)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {
            ref.read(soundServiceProvider).click();
            setState(() => _started = true);
          },
          icon: const Icon(Icons.rocket_launch_outlined),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('ابدأ الامتحان'),
          ),
        ),
      ],
    );
  }

  // ── سؤال ─────────────────────────────────────────────────────────────
  Widget _buildQuestion() {
    final question = _entry.question;
    final answered = _selected != null;
    final difficultyLabel = switch (_entry.weight) {
      1 => ('🟢', 'سهل'),
      2 => ('🟡', 'متوسط'),
      _ => ('🔴', 'متقدم'),
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('سؤال ${_index + 1}/${kPlacementQuestions.length}',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('${difficultyLabel.$1} ${difficultyLabel.$2}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _index / kPlacementQuestions.length,
            minHeight: 8,
            backgroundColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: 20),
        Text(question.text,
            style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.w900, height: 1.6)),
        const SizedBox(height: 16),
        for (var i = 0; i < question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: !answered
                  ? Colors.white
                  : i == question.correct
                      ? const Color(0xFFF0FDF4)
                      : i == _selected
                          ? const Color(0xFFFEF2F2)
                          : Colors.grey.shade50,
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
                          ? Colors.grey.shade200
                          : i == question.correct
                              ? const Color(0xFF86EFAC)
                              : i == _selected
                                  ? const Color(0xFFFCA5A5)
                                  : Colors.grey.shade100,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(question.options[i],
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, height: 1.5)),
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
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(question.explanation,
                style:
                    const TextStyle(height: 1.7, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _next,
            child: Text(_index < kPlacementQuestions.length - 1
                ? 'السؤال التالي ←'
                : 'اعرض نتيجتي 🎯'),
          ),
        ],
      ],
    );
  }

  // ── النتيجة ──────────────────────────────────────────────────────────
  Widget _buildResult() {
    final level = AdaptiveLevelX.fromString(_resultLevel!);
    final (emoji, message) = switch (level) {
      AdaptiveLevel.advanced => (
          '🏆',
          'مستواك متقدم! ستبدأ بتحديات قوية تناسب ذكاءك.'
        ),
      AdaptiveLevel.medium => (
          '🌟',
          'مستواك متوسط! ستبدأ بألعاب متوازنة وتتقدم بسرعة.'
        ),
      AdaptiveLevel.weak => (
          '🌱',
          'سنبدأ معاً من الأساسيات خطوة بخطوة — وستتفاجأ بسرعة تقدمك!'
        ),
    };
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        Center(child: Text(emoji, style: const TextStyle(fontSize: 64))),
        const SizedBox(height: 10),
        Center(
          child: Text('مستواك: ${level.labelAr}',
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text('النتيجة: $_score من $_maxScore نقطة',
              style: TextStyle(
                  color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9E8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              SvgPicture.asset('assets/images/nouri.svg',
                  width: 44, height: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message,
                    style: const TextStyle(
                        height: 1.7, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {
            ref.read(soundServiceProvider).click();
            context.go('/dashboard');
          },
          icon: const Icon(Icons.park_outlined),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('انطلق إلى شجرتك 🌳'),
          ),
        ),
      ],
    );
  }
}
