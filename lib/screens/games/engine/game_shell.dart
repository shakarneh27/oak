import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/core_providers.dart';
import 'classify_game.dart';
import 'game_models.dart';
import 'matching_game.dart';
import 'ordering_game.dart';
import 'quiz_game.dart';

/// غلاف اللعبة: اختيار الصعوبة → اللعب (مع أصوات صح/خطأ) → النتيجة
/// بالنجوم والاحتفال، مع تسجيل الجلسة ومنح المكافآت في Supabase.
class GameShell extends ConsumerStatefulWidget {
  final Activity activity;

  const GameShell({super.key, required this.activity});

  @override
  ConsumerState<GameShell> createState() => _GameShellState();
}

enum _Phase { difficulty, playing, result }

class _GameShellState extends ConsumerState<GameShell> {
  _Phase _phase = _Phase.difficulty;
  GameDifficulty _difficulty = GameDifficulty.easy;
  int _stars = 0;
  int _correct = 0;
  int _total = 0;

  void _start(GameDifficulty difficulty) {
    ref.read(soundServiceProvider).click();
    setState(() {
      _difficulty = difficulty;
      _phase = _Phase.playing;
    });
  }

  void _onAnswer(bool correct) {
    final sound = ref.read(soundServiceProvider);
    correct ? sound.correct() : sound.wrong();
  }

  Future<void> _onFinished(int correct, int total) async {
    final ratio = total == 0 ? 0.0 : correct / total;
    final stars = ratio >= 0.9
        ? 3
        : ratio >= 0.6
        ? 2
        : 1;
    setState(() {
      _phase = _Phase.result;
      _stars = stars;
      _correct = correct;
      _total = total;
    });
    final sound = ref.read(soundServiceProvider);
    sound.complete(stars);
    sound.speak(
      stars == 3
          ? 'رائع! أداء ممتاز'
          : stars == 2
          ? 'أحسنت! نتيجة جيدة'
          : 'محاولة طيبة، جرب مرة أخرى',
    );

    // record the session + award leaves/growth (best effort — the result
    // screen shows regardless of connectivity).
    try {
      final client = ref.read(supabaseClientProvider);
      final studentId = client.auth.currentUser?.id;
      if (studentId != null) {
        await client.from('game_sessions').insert({
          'student_id': studentId,
          'game_key': widget.activity.id,
          'level': _difficulty.dbLevel,
          'attempts_count': total,
          'status': 'completed',
          'ended_at': DateTime.now().toIso8601String(),
          'realtime_payload': {
            'stars': stars,
            'correct': correct,
            'total': total,
          },
        });
        await ref
            .read(remedialEngineProvider)
            .awardGameReward(studentId, points: stars * 5);
      }
    } catch (_) {
      // offline / RLS issues shouldn't break the celebration
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.activity.emoji} ${widget.activity.name}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: switch (_phase) {
            _Phase.difficulty => _DifficultySelect(onSelect: _start),
            _Phase.playing => _buildGame(),
            _Phase.result => _ResultView(
              stars: _stars,
              correct: _correct,
              total: _total,
              onRetry: () => setState(() => _phase = _Phase.difficulty),
              onExit: () => context.pop(),
            ),
          },
        ),
      ),
    );
  }

  Widget _buildGame() {
    final activity = widget.activity;
    return switch (activity.kind) {
      GameKind.quiz => QuizGame(
        questions: activity.quiz,
        difficulty: _difficulty,
        onAnswer: _onAnswer,
        onFinished: _onFinished,
      ),
      GameKind.matching => MatchingGame(
        pairs: activity.pairs,
        difficulty: _difficulty,
        onAnswer: _onAnswer,
        onFinished: _onFinished,
      ),
      GameKind.ordering => OrderingGame(
        prompt: activity.orderPrompt,
        items: activity.orderItems,
        difficulty: _difficulty,
        onAnswer: _onAnswer,
        onFinished: _onFinished,
      ),
      GameKind.classify => ClassifyGame(
        buckets: activity.buckets,
        items: activity.classifyItems,
        difficulty: _difficulty,
        onAnswer: _onAnswer,
        onFinished: _onFinished,
      ),
    };
  }
}

class _DifficultySelect extends StatelessWidget {
  final void Function(GameDifficulty) onSelect;

  const _DifficultySelect({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        const Center(child: Text('🎯', style: TextStyle(fontSize: 44))),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'اختر مستوى الصعوبة',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ),
        Center(
          child: Text(
            'كل مستوى له تحدياته الخاصة',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
        const SizedBox(height: 20),
        for (final difficulty in GameDifficulty.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: switch (difficulty) {
                GameDifficulty.easy => const Color(0xFFF0FDF4),
                GameDifficulty.medium => const Color(0xFFFEFCE8),
                GameDifficulty.hard => const Color(0xFFFEF2F2),
              },
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () => onSelect(difficulty),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: switch (difficulty) {
                        GameDifficulty.easy => const Color(0xFF86EFAC),
                        GameDifficulty.medium => const Color(0xFFFDE047),
                        GameDifficulty.hard => const Color(0xFFFCA5A5),
                      },
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        difficulty.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              difficulty.labelAr,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              difficulty.descriptionAr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_left, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final int stars;
  final int correct;
  final int total;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  const _ResultView({
    required this.stars,
    required this.correct,
    required this.total,
    required this.onRetry,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _ConfettiLayer()),
        ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Center(
              child: Text(
                stars == 3
                    ? '🎉'
                    : stars == 2
                    ? '👏'
                    : '💪',
                style: const TextStyle(fontSize: 56),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                stars == 3
                    ? 'مذهل! أنت نجم حقيقي'
                    : stars == 2
                    ? 'أحسنت! نتيجة رائعة'
                    : 'محاولة طيبة — التدريب يصنع الإتقان',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Opacity(
                      opacity: i <= stars ? 1 : 0.2,
                      child: Text(
                        '⭐',
                        style: TextStyle(fontSize: i <= stars ? 42 : 34),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '$correct إجابة صحيحة من $total',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${stars * 5} 🍃 أوراق سنديانة',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: OakColors.leafDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.replay),
              label: const Text('العب مرة أخرى'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onExit,
              child: const Text('العودة للأنشطة'),
            ),
          ],
        ),
      ],
    );
  }
}

/// طبقة احتفال خفيفة: قصاصات ملونة تتساقط مرة واحدة.
class _ConfettiLayer extends StatefulWidget {
  const _ConfettiLayer();

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) =>
            CustomPaint(painter: _ConfettiPainter(progress: _controller.value)),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  static const _colors = [
    OakColors.primary,
    OakColors.gold,
    OakColors.accentBlue,
    OakColors.coral,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(11);
    final paint = Paint();
    for (var i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final speed = 0.6 + random.nextDouble() * 0.8;
      final y =
          (progress * speed * (size.height + 60)) -
          30 +
          random.nextDouble() * 40;
      if (y > size.height) continue;
      paint.color = _colors[i % _colors.length].withValues(
        alpha: (1 - progress).clamp(0.0, 1.0),
      );
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 6 * (i.isEven ? 1 : -1));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 8, height: 5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
