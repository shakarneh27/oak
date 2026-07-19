import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'game_models.dart';

/// لعبة الأسئلة: خيارات متعددة مع شرح بعد كل إجابة — في السهل يُحذف خيار
/// خاطئ ويظهر زر تلميح، وفي المتقدم مؤقت 15 ثانية لكل سؤال.
class QuizGame extends StatefulWidget {
  final List<QuizQuestion> questions;
  final GameDifficulty difficulty;
  final void Function(bool correct) onAnswer;
  final void Function(int correct, int total) onFinished;

  const QuizGame({
    super.key,
    required this.questions,
    required this.difficulty,
    required this.onAnswer,
    required this.onFinished,
  });

  @override
  State<QuizGame> createState() => _QuizGameState();
}

class _QuizGameState extends State<QuizGame> {
  late final List<QuizQuestion> _questions = List.of(widget.questions)
    ..shuffle();
  int _index = 0;
  int _correctCount = 0;
  int? _selected;
  bool _showHint = false;
  int? _removedOption;
  Timer? _timer;
  int _secondsLeft = 15;

  QuizQuestion get _question => _questions[_index];

  @override
  void initState() {
    super.initState();
    _prepareQuestion();
  }

  void _prepareQuestion() {
    _selected = null;
    _showHint = false;
    _removedOption = null;
    if (widget.difficulty == GameDifficulty.easy) {
      // remove one wrong option
      final wrongs = [
        for (var i = 0; i < _question.options.length; i++)
          if (i != _question.correct) i,
      ]..shuffle(Random());
      _removedOption = wrongs.first;
    }
    _timer?.cancel();
    if (widget.difficulty == GameDifficulty.hard) {
      _secondsLeft = 15;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _secondsLeft -= 1);
        if (_secondsLeft <= 0) {
          t.cancel();
          _answer(-1); // timeout counts as wrong
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _answer(int i) {
    if (_selected != null) return;
    _timer?.cancel();
    final correct = i == _question.correct;
    if (correct) _correctCount += 1;
    widget.onAnswer(correct);
    setState(() => _selected = i);
  }

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() {
        _index += 1;
        _prepareQuestion();
      });
    } else {
      widget.onFinished(_correctCount, _questions.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final answered = _selected != null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'سؤال ${_index + 1}/${_questions.length}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
              ),
            ),
            if (widget.difficulty == GameDifficulty.hard && !answered)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _secondsLeft <= 5
                      ? Colors.red.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '⏱️ $_secondsLeft ث',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _secondsLeft <= 5 ? Colors.red : OakColors.ink,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _index / _questions.length,
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _question.text,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _question.options.length; i++)
          if (i != _removedOption)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionTile(
                label: _question.options[i],
                state: !answered
                    ? _OptionState.idle
                    : i == _question.correct
                    ? _OptionState.correct
                    : i == _selected
                    ? _OptionState.wrong
                    : _OptionState.dimmed,
                onTap: answered ? null : () => _answer(i),
              ),
            ),
        if (!answered &&
            widget.difficulty == GameDifficulty.easy &&
            _question.hint != null) ...[
          const SizedBox(height: 4),
          _showHint
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '💡 ${_question.hint}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              : TextButton.icon(
                  onPressed: () => setState(() => _showHint = true),
                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                  label: const Text('أعطني تلميحاً'),
                ),
        ],
        if (answered) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _selected == _question.correct
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _question.explanation,
              style: const TextStyle(height: 1.7, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _next,
            child: Text(
              _index < _questions.length - 1
                  ? 'السؤال التالي ←'
                  : 'اعرض النتيجة 🎉',
            ),
          ),
        ],
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  const _OptionTile({required this.label, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (background, border, foreground) = switch (state) {
      _OptionState.idle => (Colors.white, Colors.grey.shade200, OakColors.ink),
      _OptionState.correct => (
        const Color(0xFFF0FDF4),
        const Color(0xFF86EFAC),
        const Color(0xFF15803D),
      ),
      _OptionState.wrong => (
        const Color(0xFFFEF2F2),
        const Color(0xFFFCA5A5),
        const Color(0xFFB91C1C),
      ),
      _OptionState.dimmed => (
        Colors.grey.shade50,
        Colors.grey.shade100,
        Colors.grey.shade400,
      ),
    };
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                    height: 1.5,
                  ),
                ),
              ),
              if (state == _OptionState.correct) const Text('✅'),
              if (state == _OptionState.wrong) const Text('❌'),
            ],
          ),
        ),
      ),
    );
  }
}
