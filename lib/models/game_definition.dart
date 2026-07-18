class GameDefinition {
  final String gameKey;
  final String unitKey;
  final String lessonName;
  final String gameName;
  final String weakContent;
  final String mediumContent;
  final String advancedContent;
  final int pointsReward;
  final String? badgeReward;

  const GameDefinition({
    required this.gameKey,
    required this.unitKey,
    required this.lessonName,
    required this.gameName,
    required this.weakContent,
    required this.mediumContent,
    required this.advancedContent,
    required this.pointsReward,
    this.badgeReward,
  });

  factory GameDefinition.fromMap(Map<String, dynamic> map) {
    return GameDefinition(
      gameKey: map['game_key'] as String,
      unitKey: map['unit_key'] as String,
      lessonName: map['lesson_name'] as String,
      gameName: map['game_name'] as String,
      weakContent: map['weak_content'] as String,
      mediumContent: map['medium_content'] as String,
      advancedContent: map['advanced_content'] as String,
      pointsReward: (map['points_reward'] as num?)?.toInt() ?? 0,
      badgeReward: map['badge_reward'] as String?,
    );
  }
}

class Unit {
  final String unitKey;
  final String nameAr;
  final int sortOrder;

  const Unit({
    required this.unitKey,
    required this.nameAr,
    required this.sortOrder,
  });

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      unitKey: map['unit_key'] as String,
      nameAr: map['name_ar'] as String,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
