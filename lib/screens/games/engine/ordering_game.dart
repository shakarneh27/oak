import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'game_models.dart';

/// لعبة الترتيب/السلاسل: اضغط العناصر بالترتيب الصحيح لملء الخانات.
/// (سهل: العنصر التالي الصحيح يتوهّج قليلاً كمساعدة).
class OrderingGame extends StatefulWidget {
  final String prompt;
  final List<OrderItem> items;
  final GameDifficulty difficulty;
  final void Function(bool correct) onAnswer;
  final void Function(int correct, int total) onFinished;

  const OrderingGame({
    super.key,
    required this.prompt,
    required this.items,
    required this.difficulty,
    required this.onAnswer,
    required this.onFinished,
  });

  @override
  State<OrderingGame> createState() => _OrderingGameState();
}

class _OrderingGameState extends State<OrderingGame> {
  late final List<OrderItem> _sorted = List.of(widget.items)
    ..sort((a, b) => a.order.compareTo(b.order));
  late List<OrderItem> _pool = List.of(widget.items)..shuffle();
  final List<OrderItem> _placed = [];
  int _mistakes = 0;
  int _correctTaps = 0;

  void _tap(OrderItem item) {
    final expected = _sorted[_placed.length];
    if (item.order == expected.order) {
      _correctTaps += 1;
      widget.onAnswer(true);
      setState(() {
        _placed.add(item);
        _pool = List.of(_pool)..remove(item);
      });
      if (_placed.length == _sorted.length) {
        // score by taps: perfect run = all correct on first try
        widget.onFinished(
          _correctTaps - _mistakes < 0
              ? 0
              : _sorted.length - _mistakes.clamp(0, _sorted.length),
          _sorted.length,
        );
      }
    } else {
      _mistakes += 1;
      widget.onAnswer(false);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextExpected = _placed.length < _sorted.length
        ? _sorted[_placed.length]
        : null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          widget.prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        // placed sequence
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9E8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < _sorted.length; i++) ...[
                if (i > 0)
                  const Text(
                    '←',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: i < _placed.length
                        ? OakColors.leafDark
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: i < _placed.length
                          ? OakColors.leafDark
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    i < _placed.length
                        ? '${_placed[i].emoji ?? ''} ${_placed[i].label}'
                        : '${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: i < _placed.length
                          ? Colors.white
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'اضغط العناصر بالترتيب الصحيح 👇',
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
            for (final item in _pool)
              _PoolChip(
                item: item,
                glow:
                    widget.difficulty == GameDifficulty.easy &&
                    item.order == nextExpected?.order,
                onTap: () => _tap(item),
              ),
          ],
        ),
        if (_mistakes > 0) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              'محاولات خاطئة: $_mistakes',
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

class _PoolChip extends StatelessWidget {
  final OrderItem item;
  final bool glow;
  final VoidCallback onTap;

  const _PoolChip({
    required this.item,
    required this.glow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: glow ? OakColors.gold : Colors.grey.shade200,
              width: 2,
            ),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: OakColors.gold.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Text(
            '${item.emoji ?? ''} ${item.label}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
