import 'package:flutter/material.dart';

import '../../../models/game_interaction.dart';

/// Generic timed multiple-choice mechanic: one question at a time, an
/// answer tap is a single attempt. The parent screen decides what happens
/// next (advance, downgrade, pause, ...).
class McqRoundWidget extends StatefulWidget {
  final McqQuestion question;
  final ValueChanged<bool> onAnswer;

  const McqRoundWidget({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  State<McqRoundWidget> createState() => _McqRoundWidgetState();
}

class _McqRoundWidgetState extends State<McqRoundWidget> {
  int? _selected;

  @override
  void didUpdateWidget(covariant McqRoundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.question.prompt,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < widget.question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: _selected == null
                    ? null
                    : i == widget.question.correctIndex
                    ? Colors.green.withValues(alpha: 0.2)
                    : (i == _selected
                          ? Colors.red.withValues(alpha: 0.2)
                          : null),
              ),
              onPressed: _selected != null
                  ? null
                  : () {
                      setState(() => _selected = i);
                      widget.onAnswer(i == widget.question.correctIndex);
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(widget.question.options[i]),
              ),
            ),
          ),
      ],
    );
  }
}
