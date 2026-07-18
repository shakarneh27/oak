import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/game_interactions_data.dart';
import '../../data/games_matrix_data.dart';
import '../../models/adaptive_level.dart';
import '../../models/game_definition.dart';
import '../../models/game_interaction.dart';
import '../../models/game_session.dart';
import '../../providers/core_providers.dart';
import '../../services/remedial_engine.dart';
import 'widgets/match_round_widget.dart';
import 'widgets/mcq_round_widget.dart';
import 'widgets/sequence_round_widget.dart';

/// صفحة اللعب: يبدأ جلسة لعب (`start_game_session`) ويغذي كل محاولة
/// (`submit_move`) لمحرك الخطة العلاجية، الذي يقرر فوراً ما إذا كان يجب
/// خفض المستوى، إيقاف الجلسة مؤقتاً، أو تنبيه المعلم/ولي الأمر.
class GamePlayerScreen extends ConsumerStatefulWidget {
  final String gameKey;
  const GamePlayerScreen({super.key, required this.gameKey});

  @override
  ConsumerState<GamePlayerScreen> createState() => _GamePlayerScreenState();
}

class _GamePlayerScreenState extends ConsumerState<GamePlayerScreen> {
  GameSession? _session;
  AdaptiveLevel? _originalLevel;
  int _mcqIndex = 0;
  bool _loading = true;
  String? _error;

  late final GameDefinition _game;

  @override
  void initState() {
    super.initState();
    _game = kGamesMatrix.firstWhere((g) => g.gameKey == widget.gameKey);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final studentId = client.auth.currentUser!.id;
      final progressRow =
          await client.from('student_progress').select('current_level').eq('student_id', studentId).maybeSingle();
      final level = progressRow == null
          ? AdaptiveLevel.weak
          : AdaptiveLevelX.fromString(progressRow['current_level'] as String? ?? 'Weak');
      final engine = ref.read(remedialEngineProvider);
      final session = await engine.startSession(studentId: studentId, gameKey: widget.gameKey, level: level);
      setState(() {
        _session = session;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  GameInteractionConfig get _config => kGameInteractions[widget.gameKey]!;

  Future<void> _handleAttempt(bool success) async {
    final session = _session;
    if (session == null) return;
    _originalLevel ??= session.level;
    final engine = ref.read(remedialEngineProvider);
    final outcome = await engine.submitAttempt(session, success: success);
    if (!mounted) return;
    setState(() => _session = outcome.session);

    switch (outcome.action) {
      case RemedialActionType.none:
        _advanceOrNotify(success, outcome.message);
        break;
      case RemedialActionType.adaptiveDowngrade:
        setState(() => _mcqIndex = 0);
        _showSnack(outcome.message);
        break;
      case RemedialActionType.encourageAndPause:
        await _showRemedyDialog(
          title: 'لا بأس، السنديانة معك 🌳',
          message: outcome.message,
          confirmLabel: 'أحاول مجدداً',
          onConfirm: () => _restartAtLevel(_session!.level),
        );
        break;
      case RemedialActionType.teacherAlert:
        await _showRemedyDialog(
          title: 'دعنا نطلب المساعدة',
          message: outcome.message,
          confirmLabel: 'العودة للوحدات',
          onConfirm: () => context.go('/units'),
        );
        break;
      case RemedialActionType.remediationPassed:
        // The courage badge + tree growth were already granted inside
        // RemedialEngine — the original game's own reward is only earned
        // once the student actually clears it again below.
        await _showRemedyDialog(
          title: 'أحسنت! 🌟',
          message: outcome.message,
          confirmLabel: 'إلى التحدي الأصلي',
          onConfirm: () => _restartAtLevel(_originalLevel ?? AdaptiveLevel.weak),
        );
        break;
    }
  }

  void _advanceOrNotify(bool success, String message) {
    if (_config.type == GameInteractionType.mcq) {
      final questions = _config.mcqQuestionsByLevel![_session!.level]!;
      final isLastQuestion = _mcqIndex >= questions.length - 1;
      if (!isLastQuestion) {
        setState(() => _mcqIndex++);
        _showSnack(message);
        return;
      }
      if (!success) {
        _showRemedyDialog(
          title: 'انتهى التحدي',
          message: 'أجبت عن كل الأسئلة، هل تجرب مرة أخرى؟',
          confirmLabel: 'حاول مجدداً',
          onConfirm: () => _restartAtLevel(_session!.level),
        );
        return;
      }
    }
    if (success) {
      _showCompletionDialog();
    } else {
      _showSnack(message);
    }
  }

  Future<void> _restartAtLevel(AdaptiveLevel level) async {
    final engine = ref.read(remedialEngineProvider);
    final session = await engine.startSession(
      studentId: _session!.studentId,
      gameKey: widget.gameKey,
      level: level,
    );
    if (!mounted) return;
    setState(() {
      _session = session;
      _mcqIndex = 0;
    });
  }

  Future<void> _showCompletionDialog() async {
    final client = ref.read(supabaseClientProvider);
    await ref.read(remedialEngineProvider).awardGameReward(
          client.auth.currentUser!.id,
          points: _game.pointsReward,
          badge: _game.badgeReward,
        );
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أحسنت! 🎉'),
        content: Text('أنجزت لعبة "${_game.gameName}" وحصلت على +${_game.pointsReward} نقطة'
            '${_game.badgeReward != null ? ' و "${_game.badgeReward}"' : ''}!'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('عودة للألعاب'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRemedyDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.park_rounded, size: 40),
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text('تعذر بدء اللعبة: $_error')));

    final session = _session!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_game.gameName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: Chip(
                label: Text(session.level.labelAr),
                backgroundColor: session.isRemediation ? Colors.amber.withValues(alpha: 0.3) : null,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (session.isRemediation)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('🌱 جولة مساعدة: لنبنِ الأساس قبل العودة للتحدي الأصلي', textAlign: TextAlign.center),
              ),
            Text('المحاولات: ${session.attemptsCount}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(child: _buildMechanic(session))),
          ],
        ),
      ),
    );
  }

  Widget _buildMechanic(GameSession session) {
    switch (_config.type) {
      case GameInteractionType.match:
        final items = _config.matchItemsByLevel![session.level]!;
        return MatchRoundWidget(key: ValueKey(session.level), items: items, onCheck: _handleAttempt);
      case GameInteractionType.sequence:
        final order = _config.sequenceItemsByLevel![session.level]!;
        return SequenceRoundWidget(key: ValueKey(session.level), correctOrder: order, onCheck: _handleAttempt);
      case GameInteractionType.mcq:
        final questions = _config.mcqQuestionsByLevel![session.level]!;
        final question = questions[_mcqIndex.clamp(0, questions.length - 1)];
        return McqRoundWidget(key: ValueKey('${session.level}-$_mcqIndex'), question: question, onAnswer: _handleAttempt);
    }
  }
}
