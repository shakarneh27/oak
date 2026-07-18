import 'adaptive_level.dart';

enum GameSessionStatus { inProgress, completed, failed, pausedForRemediation }

GameSessionStatus _statusFromString(String value) {
  switch (value) {
    case 'completed':
      return GameSessionStatus.completed;
    case 'failed':
      return GameSessionStatus.failed;
    case 'paused_for_remediation':
      return GameSessionStatus.pausedForRemediation;
    case 'in_progress':
    default:
      return GameSessionStatus.inProgress;
  }
}

extension GameSessionStatusX on GameSessionStatus {
  String get dbValue => switch (this) {
        GameSessionStatus.inProgress => 'in_progress',
        GameSessionStatus.completed => 'completed',
        GameSessionStatus.failed => 'failed',
        GameSessionStatus.pausedForRemediation => 'paused_for_remediation',
      };
}

class GameSession {
  final String sessionId;
  final String studentId;
  final String gameKey;
  final AdaptiveLevel level;
  final int attemptsCount;
  final int consecutiveFails;
  final GameSessionStatus status;
  final bool isRemediation;
  final String? remediationOfGameKey;

  const GameSession({
    required this.sessionId,
    required this.studentId,
    required this.gameKey,
    required this.level,
    required this.attemptsCount,
    required this.consecutiveFails,
    required this.status,
    this.isRemediation = false,
    this.remediationOfGameKey,
  });

  factory GameSession.fromMap(Map<String, dynamic> map) {
    return GameSession(
      sessionId: map['session_id'] as String,
      studentId: map['student_id'] as String,
      gameKey: map['game_key'] as String,
      level: AdaptiveLevelX.fromString(map['level'] as String? ?? 'Weak'),
      attemptsCount: (map['attempts_count'] as num?)?.toInt() ?? 0,
      consecutiveFails: (map['consecutive_fails'] as num?)?.toInt() ?? 0,
      status: _statusFromString(map['status'] as String? ?? 'in_progress'),
      isRemediation: map['is_remediation'] as bool? ?? false,
      remediationOfGameKey: map['remediation_of_game_key'] as String?,
    );
  }
}
