import 'adaptive_level.dart';

class StudentProgress {
  final String studentId;
  final AdaptiveLevel currentLevel;
  final int oakLeaves;
  final int treeGrowthStage;
  final List<String> badgesUnlocked;
  final bool placementDone;

  const StudentProgress({
    required this.studentId,
    required this.currentLevel,
    required this.oakLeaves,
    required this.treeGrowthStage,
    required this.badgesUnlocked,
    this.placementDone = false,
  });

  factory StudentProgress.initial(String studentId) => StudentProgress(
    studentId: studentId,
    currentLevel: AdaptiveLevel.weak,
    oakLeaves: 0,
    treeGrowthStage: 0,
    badgesUnlocked: const [],
  );

  factory StudentProgress.fromMap(Map<String, dynamic> map) {
    return StudentProgress(
      studentId: map['student_id'] as String,
      currentLevel: AdaptiveLevelX.fromString(
        map['current_level'] as String? ?? 'Weak',
      ),
      oakLeaves: (map['oak_leaves'] as num?)?.toInt() ?? 0,
      treeGrowthStage: (map['tree_growth_stage'] as num?)?.toInt() ?? 0,
      badgesUnlocked:
          (map['badges_unlocked'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      placementDone: map['placement_done'] as bool? ?? false,
    );
  }
}
