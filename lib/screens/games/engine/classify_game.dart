import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'game_models.dart';

/// لعبة التصنيف: يظهر عنصر كبير ويضغط الطالب السلة الصحيحة
/// (سهل: يظهر تلميح العنصر تلقائياً).
class ClassifyGame extends StatefulWidget {
  final List<ClassifyBucket> buckets;
  final List<ClassifyItem> items;
  final GameDifficulty difficulty;
  final void Function(bool correct) onAnswer;
  final void Function(int correct, int total) onFinished;

  const ClassifyGame({
    super.key,
    required this.buckets,
    required this.items,
    required this.difficulty,
    required this.onAnswer,
    required this.onFinished,
  });

  @override
  State<ClassifyGame> createState() => _ClassifyGameState();
}

class _ClassifyGameState extends State<ClassifyGame> {
  late final List<ClassifyItem> _items = () {
    final list = List.of(widget.items)..shuffle();
    // hard mode: more items, easy: fewer
    final count = switch (widget.difficulty) {
      GameDifficulty.easy => (list.length * 0.7).ceil(),
      _ => list.length,
    };
    return list.take(count).toList();
  }();

  int _index = 0;
  int _correctCount = 0;
  String? _feedback; // bucket key of wrong pick, or 'ok'

  ClassifyItem get _item => _items[_index];

  void _pick(ClassifyBucket bucket) {
    if (_feedback == 'ok') return;
    final correct = bucket.key == _item.bucket;
    widget.onAnswer(correct);
    if (correct) {
      _correctCount += 1;
      setState(() => _feedback = 'ok');
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        if (_index < _items.length - 1) {
          setState(() {
            _index += 1;
            _feedback = null;
          });
        } else {
          widget.onFinished(_correctCount, _items.length);
        }
      });
    } else {
      setState(() => _feedback = bucket.key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'عنصر ${_index + 1}/${_items.length}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _index / _items.length,
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: 24),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _feedback == 'ok' ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _feedback == 'ok'
                  ? const Color(0xFF86EFAC)
                  : Colors.grey.shade200,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: OakColors.primary.withValues(alpha: 0.15),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(_item.emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text(
                _item.label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (widget.difficulty == GameDifficulty.easy &&
                  _item.hint != null) ...[
                const SizedBox(height: 6),
                Text(
                  '💡 ${_item.hint}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'اضغط المجموعة الصحيحة 👇',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final bucket in widget.buckets)
              Material(
                color: _feedback == bucket.key
                    ? const Color(0xFFFEF2F2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => _pick(bucket),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _feedback == bucket.key
                            ? const Color(0xFFFCA5A5)
                            : OakColors.secondary,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          bucket.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bucket.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_feedback != null && _feedback != 'ok') ...[
          const SizedBox(height: 14),
          Center(
            child: Text(
              'ليست المجموعة الصحيحة — جرّب مرة أخرى!',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
