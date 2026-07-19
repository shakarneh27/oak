import 'package:flutter/material.dart';

import '../../data/game_content.dart';
import 'engine/game_shell.dart';

/// صفحة اللعب: تبحث عن النشاط في كتالوج الوحدات وتشغّله عبر محرك الألعاب
/// (اختيار الصعوبة → اللعب بالأصوات → النتيجة بالنجوم والمكافآت).
class GamePlayerScreen extends StatelessWidget {
  final String gameKey;

  const GamePlayerScreen({super.key, required this.gameKey});

  @override
  Widget build(BuildContext context) {
    final activity = findActivity(gameKey);
    if (activity == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('النشاط')),
        body: const Center(child: Text('هذا النشاط غير متوفر بعد 🌱')),
      );
    }
    return GameShell(activity: activity);
  }
}
