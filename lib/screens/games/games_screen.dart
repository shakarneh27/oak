import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/game_content.dart';
import '../../providers/core_providers.dart';
import 'engine/game_models.dart';

/// صفحة أنشطة الوحدة: بطاقات الألعاب المتنوعة (مطابقة/ترتيب/تصنيف/أسئلة).
class GamesScreen extends ConsumerWidget {
  final String unitKey;

  const GamesScreen({super.key, required this.unitKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = findGameUnit(unitKey);
    if (unit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الأنشطة')),
        body: const Center(child: Text('أنشطة هذه الوحدة قادمة قريباً 🌱')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('${unit.emoji} ${unit.title}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                unit.description,
                style: TextStyle(color: Colors.grey.shade600, height: 1.7),
              ),
              const SizedBox(height: 16),
              for (final activity in unit.activities)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ActivityCard(
                    activity: activity,
                    onTap: () {
                      ref.read(soundServiceProvider).click();
                      context.push('/games/${activity.id}');
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;

  const _ActivityCard({required this.activity, required this.onTap});

  String get _kindLabel => switch (activity.kind) {
    GameKind.quiz => 'أسئلة 🧠',
    GameKind.matching => 'مطابقة 🧩',
    GameKind.ordering => 'ترتيب 🔗',
    GameKind.classify => 'تصنيف 🗂️',
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: OakColors.secondary),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: OakColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  activity.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.blurb,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: OakColors.secondary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _kindLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
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
    );
  }
}
