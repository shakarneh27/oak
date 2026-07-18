import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_providers.dart';

/// صفحة الألعاب: المحيط التعليمي الذي يحتوي على الألعاب بمستوياتها الثلاثة
/// لكل وحدة (`start_game_session`).
class GamesScreen extends ConsumerWidget {
  final String unitKey;
  const GamesScreen({super.key, required this.unitKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(gamesForUnitProvider(unitKey));
    return Scaffold(
      appBar: AppBar(title: const Text('الألعاب')),
      body: gamesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذر التحميل: $e')),
        data: (games) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.gameName, style: Theme.of(context).textTheme.titleMedium),
                    Text(game.lessonName, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text('🟢 ضعيف: ${game.weakContent}'),
                    Text('🟡 متوسط: ${game.mediumContent}'),
                    Text('🔴 متقدم: ${game.advancedContent}'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('+${game.pointsReward} نقطة${game.badgeReward != null ? ' | ${game.badgeReward}' : ''}'),
                        FilledButton(
                          onPressed: () => context.push('/games/${game.gameKey}'),
                          child: const Text('ابدأ اللعب'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
