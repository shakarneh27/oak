import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'game_models.dart';

/// لعبة المطابقة: يظهر المصطلح ويختار الطالب وصفه الصحيح من بين الخيارات
/// (سهل: 3 خيارات، متوسط: 4، متقدم: كل الأوصاف).
class MatchingGame extends StatefulWidget {
  final List<MatchPair> pairs;
  final GameDifficulty difficulty;
  final void Function(bool correct) onAnswer;
  final void Function(int correct, int total) onFinished;

  const MatchingGame({
    super.key,
    required this.pairs,
    required this.difficulty,
    required this.onAnswer,
    required this.onFinished,
  });

  @override
  State<MatchingGame> createState() => _MatchingGameState();
}

class _MatchingGameState extends State<MatchingGame> {
  late final List<MatchPair> _pairs = List.of(widget.pairs)..shuffle();
  int _index = 0;
  int _correctCount = 0;
  int? _selected;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _buildOptions();
  }

  MatchPair get _pair => _pairs[_index];

  void _buildOptions() {
    _selected = null;
    final optionCount = switch (widget.difficulty) {
      GameDifficulty.easy => 3,
      GameDifficulty.medium => 4,
      GameDifficulty.hard => _pairs.length,
    };
    final others = [
      for (final p in _pairs)
        if (p.match != _pair.match) p.match,
    ]..shuffle();
    _options = [_pair.match, ...others.take(optionCount - 1)]..shuffle();
  }

  void _answer(String option) {
    if (_selected != null) return;
    final correct = option == _pair.match;
    if (correct) _correctCount += 1;
    widget.onAnswer(correct);
    setState(() => _selected = _options.indexOf(option));
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      if (_index < _pairs.length - 1) {
        setState(() {
          _index += 1;
          _buildOptions();
        });
      } else {
        widget.onFinished(_correctCount, _pairs.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final answered = _selected != null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'مطابقة ${_index + 1}/${_pairs.length}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _index / _pairs.length,
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0F9E8), Color(0xFFE8F5D8)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              _pair.term,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'اختر الوصف الصحيح 👇',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final option in _options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: !answered
                  ? Colors.white
                  : option == _pair.match
                  ? const Color(0xFFF0FDF4)
                  : _options.indexOf(option) == _selected
                  ? const Color(0xFFFEF2F2)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: answered ? null : () => _answer(option),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: !answered
                          ? Colors.grey.shade200
                          : option == _pair.match
                          ? const Color(0xFF86EFAC)
                          : _options.indexOf(option) == _selected
                          ? const Color(0xFFFCA5A5)
                          : Colors.grey.shade100,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: OakColors.ink,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
