import 'adaptive_level.dart';

/// The three generic, reusable mechanics every catalog game is built on —
/// difficulty across the three adaptive levels is expressed by varying the
/// item count / distractors / question count within each mechanic, not by
/// swapping mechanics.
enum GameInteractionType { match, sequence, mcq }

/// One emoji/label pair for [GameInteractionType.match].
class MatchItem {
  final String emoji;
  final String label;
  const MatchItem(this.emoji, this.label);
}

/// One question for [GameInteractionType.mcq].
class McqQuestion {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  const McqQuestion(this.prompt, this.options, this.correctIndex);
}

/// Full per-level content for a single game, keyed by [GameInteractionType].
class GameInteractionConfig {
  final GameInteractionType type;
  final Map<AdaptiveLevel, List<MatchItem>>? matchItemsByLevel;
  final Map<AdaptiveLevel, List<String>>? sequenceItemsByLevel;
  final Map<AdaptiveLevel, List<McqQuestion>>? mcqQuestionsByLevel;

  const GameInteractionConfig.match(this.matchItemsByLevel)
      : type = GameInteractionType.match,
        sequenceItemsByLevel = null,
        mcqQuestionsByLevel = null;

  const GameInteractionConfig.sequence(this.sequenceItemsByLevel)
      : type = GameInteractionType.sequence,
        matchItemsByLevel = null,
        mcqQuestionsByLevel = null;

  const GameInteractionConfig.mcq(this.mcqQuestionsByLevel)
      : type = GameInteractionType.mcq,
        matchItemsByLevel = null,
        sequenceItemsByLevel = null;
}
