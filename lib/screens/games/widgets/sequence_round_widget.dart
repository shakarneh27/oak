import 'dart:math';

import 'package:flutter/material.dart';

/// Generic "drag into the correct order" mechanic: [correctOrder] is the
/// answer key; the displayed list starts shuffled and the student drags
/// items until they believe the order is right, then presses تحقق for a
/// single attempt.
class SequenceRoundWidget extends StatefulWidget {
  final List<String> correctOrder;
  final ValueChanged<bool> onCheck;

  const SequenceRoundWidget({
    super.key,
    required this.correctOrder,
    required this.onCheck,
  });

  @override
  State<SequenceRoundWidget> createState() => _SequenceRoundWidgetState();
}

class _SequenceRoundWidgetState extends State<SequenceRoundWidget> {
  late List<String> _order;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  @override
  void didUpdateWidget(covariant SequenceRoundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.correctOrder != widget.correctOrder) _shuffle();
  }

  void _shuffle() {
    _order = List.of(widget.correctOrder);
    do {
      _order.shuffle(Random());
    } while (_order.length > 1 && _isCorrect());
  }

  bool _isCorrect() {
    for (var i = 0; i < _order.length; i++) {
      if (_order[i] != widget.correctOrder[i]) return false;
    }
    return true;
  }

  void _check() => widget.onCheck(_isCorrect());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'رتّب العناصر بالسحب من الأعلى إلى الأسفل بالترتيب الصحيح',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _order.removeAt(oldIndex);
              _order.insert(newIndex, item);
            });
          },
          children: [
            for (final item in _order)
              Card(
                key: ValueKey(item),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(item, style: const TextStyle(fontSize: 18)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _check, child: const Text('تحقق من الترتيب')),
      ],
    );
  }
}
