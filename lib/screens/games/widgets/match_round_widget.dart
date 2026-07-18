import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/game_interaction.dart';

/// Generic "match the pairs" mechanic: tap an emoji, then tap the label
/// you think matches it, for every pair, then press تحقق to validate the
/// whole round in a single attempt.
class MatchRoundWidget extends StatefulWidget {
  final List<MatchItem> items;
  final ValueChanged<bool> onCheck;

  const MatchRoundWidget({
    super.key,
    required this.items,
    required this.onCheck,
  });

  @override
  State<MatchRoundWidget> createState() => _MatchRoundWidgetState();
}

class _MatchRoundWidgetState extends State<MatchRoundWidget> {
  late List<int> _labelOrder;
  final Map<int, int> _assignment = {}; // emojiIndex -> labelSlotPosition
  int? _selectedEmojiIndex;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  @override
  void didUpdateWidget(covariant MatchRoundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) _shuffle();
  }

  void _shuffle() {
    _labelOrder = List.generate(widget.items.length, (i) => i)
      ..shuffle(Random());
    _assignment.clear();
    _selectedEmojiIndex = null;
  }

  void _check() {
    final allCorrect = widget.items.asMap().entries.every((entry) {
      final emojiIndex = entry.key;
      final assignedSlot = _assignment[emojiIndex];
      if (assignedSlot == null) return false;
      return _labelOrder[assignedSlot] == emojiIndex;
    });
    widget.onCheck(allCorrect);
    if (!allCorrect) setState(_shuffle);
  }

  @override
  Widget build(BuildContext context) {
    final complete = _assignment.length == widget.items.length;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: widget.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final selected = _selectedEmojiIndex == index;
                  final matched = _assignment.containsKey(index);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ChoiceChip(
                      label: Text(
                        entry.value.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      selected: selected,
                      onSelected: matched
                          ? null
                          : (_) => setState(() => _selectedEmojiIndex = index),
                      backgroundColor: matched
                          ? Colors.green.withValues(alpha: 0.2)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: _labelOrder.asMap().entries.map((entry) {
                  final slot = entry.key;
                  final label = widget.items[entry.value].label;
                  final taken = _assignment.containsValue(slot);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: OutlinedButton(
                      onPressed: (_selectedEmojiIndex == null || taken)
                          ? null
                          : () => setState(() {
                              _assignment[_selectedEmojiIndex!] = slot;
                              _selectedEmojiIndex = null;
                            }),
                      child: Text(label, textAlign: TextAlign.center),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: complete ? _check : null,
          child: const Text('تحقق من الإجابات'),
        ),
      ],
    );
  }
}
