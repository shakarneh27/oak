import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/adaptive_level.dart';
import '../../providers/core_providers.dart';

class _DiagnosticQuestion {
  final String prompt;
  final List<(String label, AdaptiveLevel level)> options;
  const _DiagnosticQuestion(this.prompt, this.options);
}

const _questions = [
  _DiagnosticQuestion('كيف تصف معرفتك بمكونات الطقس (شمس، مطر، غيوم)؟', [
    ('أتعرف عليها من الصور فقط', AdaptiveLevel.weak),
    ('أستطيع وصف حالة الطقس كاملة', AdaptiveLevel.medium),
    ('أستطيع تحليل نشرة جوية واستنتاج الحالة', AdaptiveLevel.advanced),
  ]),
  _DiagnosticQuestion('ترتيب الكواكب حول الشمس بالنسبة لك:', [
    ('أحتاج للسحب والإفلات مع المساعدة', AdaptiveLevel.weak),
    ('أستطيع تحديد ترتيب أي كوكب', AdaptiveLevel.medium),
    ('أستطيع الترتيب الكامل ضمن وقت محدد', AdaptiveLevel.advanced),
  ]),
  _DiagnosticQuestion('عند حديثك عن الكسوف والخسوف:', [
    ('أعرف ترتيب الأجرام الثلاثة فقط', AdaptiveLevel.weak),
    ('أفهم كيف يتكون الظل في الظاهرتين', AdaptiveLevel.medium),
    ('أستطيع محاكاة حركة القمر الفلكية', AdaptiveLevel.advanced),
  ]),
];

/// اختبار تحديد المستوى: تقييم مبدئي لتحديد نقطة انطلاق الطالب، يقابل
/// حدث `submit_diagnostic_test` بكتابة النتيجة مباشرة إلى `student_progress`.
class DiagnosticTestScreen extends ConsumerStatefulWidget {
  const DiagnosticTestScreen({super.key});

  @override
  ConsumerState<DiagnosticTestScreen> createState() =>
      _DiagnosticTestScreenState();
}

class _DiagnosticTestScreenState extends ConsumerState<DiagnosticTestScreen> {
  int _index = 0;
  final List<AdaptiveLevel> _answers = [];
  bool _submitting = false;

  Future<void> _select(AdaptiveLevel level) async {
    _answers.add(level);
    if (_index < _questions.length - 1) {
      setState(() => _index++);
      return;
    }
    setState(() => _submitting = true);
    final scores = {
      for (final l in AdaptiveLevel.values)
        l: _answers.where((a) => a == l).length,
    };
    final result = scores.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    final client = ref.read(supabaseClientProvider);
    final studentId = client.auth.currentUser!.id;
    await client
        .from('student_progress')
        .update({
          'current_level': result.dbValue,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('student_id', studentId);

    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    if (_submitting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final question = _questions[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'اختبار تحديد المستوى (${_index + 1}/${_questions.length})',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (_index) / _questions.length),
            const SizedBox(height: 24),
            Text(
              question.prompt,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            for (final option in question.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  onPressed: () => _select(option.$2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(option.$1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
