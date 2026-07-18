import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';

class _ChatMessage {
  final String text;
  final bool fromOak;
  const _ChatMessage(this.text, {required this.fromOak});
}

/// صفحة الذكاء الاصطناعي: يحلل إجابات الطلاب ويقدم الدعم الفوري
/// (`ai_analyze_voice`, `ai_get_hint`).
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      'أهلاً بك! أنا السنديانة 🌳، اسألني عن أي شيء يصعب عليك في الدروس.',
      fromOak: true,
    ),
  ];
  bool _thinking = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text, fromOak: false));
      _thinking = true;
      _controller.clear();
    });
    final hint = await ref.read(aiAssistantServiceProvider).getHint(text);
    setState(() {
      _messages.add(_ChatMessage(hint, fromOak: true));
      _thinking = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مساعد السنديانة الذكي')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.fromOak
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: message.fromOak
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),
          if (_thinking) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'اكتب سؤالك هنا...',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mic_none),
                  onPressed: () {},
                  tooltip: 'تحليل صوتي (قريباً)',
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _thinking ? null : _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
