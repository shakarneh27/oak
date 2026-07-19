/// أنواع الألعاب المدعومة في محرك الأنشطة (مأخوذة من التصميم المرجعي).
enum GameKind { quiz, matching, ordering, classify }

enum GameDifficulty { easy, medium, hard }

extension GameDifficultyX on GameDifficulty {
  String get labelAr => switch (this) {
    GameDifficulty.easy => 'سهل',
    GameDifficulty.medium => 'متوسط',
    GameDifficulty.hard => 'متقدم',
  };

  String get emoji => switch (this) {
    GameDifficulty.easy => '🟢',
    GameDifficulty.medium => '🟡',
    GameDifficulty.hard => '🔴',
  };

  String get descriptionAr => switch (this) {
    GameDifficulty.easy => 'خيارات أقل + تلميحات مساعدة',
    GameDifficulty.medium => 'مستوى طبيعي بدون تلميحات',
    GameDifficulty.hard => 'تحدٍّ أصعب + مؤقت ضيّق',
  };

  /// Maps onto the adaptive levels stored in game_sessions.
  String get dbLevel => switch (this) {
    GameDifficulty.easy => 'Weak',
    GameDifficulty.medium => 'Medium',
    GameDifficulty.hard => 'Advanced',
  };
}

class QuizQuestion {
  final String text;
  final List<String> options;
  final int correct;
  final String explanation;
  final String? hint;

  const QuizQuestion({
    required this.text,
    required this.options,
    required this.correct,
    required this.explanation,
    this.hint,
  });
}

/// زوج مطابقة: مصطلح ↔ وصفه (أو رمزه).
class MatchPair {
  final String term;
  final String match;

  const MatchPair({required this.term, required this.match});
}

/// عنصر في لعبة ترتيب/سلسلة — [order] يبدأ من 1.
class OrderItem {
  final String label;
  final int order;
  final String? emoji;

  const OrderItem({required this.label, required this.order, this.emoji});
}

class ClassifyBucket {
  final String key;
  final String label;
  final String emoji;

  const ClassifyBucket({
    required this.key,
    required this.label,
    required this.emoji,
  });
}

class ClassifyItem {
  final String label;
  final String bucket;
  final String emoji;
  final String? hint;

  const ClassifyItem({
    required this.label,
    required this.bucket,
    required this.emoji,
    this.hint,
  });
}

/// تعريف نشاط واحد داخل وحدة — الحمولة تعتمد على [kind].
class Activity {
  final String id;
  final String unitKey;
  final String name;
  final String emoji;
  final GameKind kind;

  /// وصف قصير يظهر في بطاقة النشاط.
  final String blurb;

  final List<QuizQuestion> quiz;
  final List<MatchPair> pairs;
  final List<OrderItem> orderItems;
  final String orderPrompt;
  final List<ClassifyBucket> buckets;
  final List<ClassifyItem> classifyItems;

  const Activity({
    required this.id,
    required this.unitKey,
    required this.name,
    required this.emoji,
    required this.kind,
    required this.blurb,
    this.quiz = const [],
    this.pairs = const [],
    this.orderItems = const [],
    this.orderPrompt = '',
    this.buckets = const [],
    this.classifyItems = const [],
  });
}

class GameUnit {
  final String unitKey;
  final String title;
  final String description;
  final String emoji;
  final List<Activity> activities;

  const GameUnit({
    required this.unitKey,
    required this.title,
    required this.description,
    required this.emoji,
    required this.activities,
  });
}
