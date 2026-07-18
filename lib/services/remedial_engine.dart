import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/adaptive_level.dart';
import '../models/game_session.dart';
import 'realtime_service.dart';

/// What the UI should show after [RemedialEngine.submitAttempt] runs.
enum RemedialActionType {
  /// Nothing special — attempt was recorded, keep playing.
  none,

  /// Rule 1 — 3 consecutive fails at the same level: pause the session,
  /// log a skill gap, and show السنديانة with an encouraging short video.
  encourageAndPause,

  /// Rule 2 — 2 fails at Medium/Advanced: drop one level and surface
  /// visual hints (e.g. semi-transparent guide animation).
  adaptiveDowngrade,

  /// Rule 3 — the student still can't clear the easier alternative game:
  /// alert the teacher dashboard and the parent in real time.
  teacherAlert,

  /// Rule 4 — the student cleared the easier/remediation game 100%:
  /// send them back to the original game with a fresh scenario, award the
  /// "شارة المحاولة الشجاعة" badge, and grow the progress tree one step.
  remediationPassed,
}

class RemedialOutcome {
  final RemedialActionType action;
  final GameSession session;
  final String message;

  const RemedialOutcome({
    required this.action,
    required this.session,
    required this.message,
  });
}

/// Implements the "خوارزمية الخطة العلاجية المؤتمتة" (automated remedial
/// plan) from the spec: watches attempts as they happen and reacts
/// immediately, the same way the original Socket.io backend would.
class RemedialEngine {
  final SupabaseClient _client;
  final RealtimeService _realtime;

  RemedialEngine(this._client, this._realtime);

  Future<GameSession> startSession({
    required String studentId,
    required String gameKey,
    required AdaptiveLevel level,
    bool isRemediation = false,
    String? remediationOfGameKey,
  }) async {
    final row = await _client
        .from('game_sessions')
        .insert({
          'student_id': studentId,
          'game_key': gameKey,
          'level': level.dbValue,
          'is_remediation': isRemediation,
          if (remediationOfGameKey != null) 'remediation_of_game_key': remediationOfGameKey,
        })
        .select()
        .single();
    return GameSession.fromMap(row);
  }

  Future<RemedialOutcome> submitAttempt(GameSession session, {required bool success}) async {
    if (success) {
      return _handleSuccess(session);
    }
    return _handleFailure(session);
  }

  Future<RemedialOutcome> _handleSuccess(GameSession session) async {
    // Rule 4: clearing a remediation/alternative game sends the student
    // back to the original game and rewards perseverance.
    if (session.isRemediation) {
      final updated = await _updateSession(
        session,
        attemptsCount: session.attemptsCount + 1,
        consecutiveFails: 0,
        status: GameSessionStatus.completed,
      );
      await _logRemedialEvent(
        session: session,
        eventType: 'remediation_passed',
        triggerCondition: 'تجاوز اللعبة الأسهل بنجاح 100%',
        actionTaken: 'إعادة توجيه للعبة الأصلية مع سيناريو مختلف ومنح شارة المحاولة الشجاعة',
      );
      await _awardBadgeAndGrowTree(session.studentId, badge: 'شارة المحاولة الشجاعة');
      return RemedialOutcome(
        action: RemedialActionType.remediationPassed,
        session: updated,
        message: 'أحسنت! لننطلق مجدداً إلى اللعبة الأصلية بتحدٍ جديد 🌳',
      );
    }

    final updated = await _updateSession(
      session,
      attemptsCount: session.attemptsCount + 1,
      consecutiveFails: 0,
      status: GameSessionStatus.completed,
    );
    return RemedialOutcome(action: RemedialActionType.none, session: updated, message: 'إجابة صحيحة!');
  }

  Future<RemedialOutcome> _handleFailure(GameSession session) async {
    final nextFails = session.consecutiveFails + 1;
    final nextAttempts = session.attemptsCount + 1;

    // Rule 3: still failing on the easier alternative game -> alert
    // teacher + parent instead of downgrading further.
    if (session.isRemediation && nextFails >= 2) {
      final updated = await _updateSession(
        session,
        attemptsCount: nextAttempts,
        consecutiveFails: nextFails,
        status: GameSessionStatus.pausedForRemediation,
      );
      await _logRemedialEvent(
        session: session,
        eventType: 'teacher_alert',
        triggerCondition: 'استمرار الخطأ في اللعبة الأبهر البديلة',
        actionTaken: 'إرسال حدث فوري للوحة تحكم المعلم وتنبيه ولي الأمر',
      );
      await _realtime.logEvent(
        studentId: session.studentId,
        eventType: 'teacher_update',
        payload: {'game_key': session.gameKey, 'reason': 'remediation_stuck'},
      );
      return RemedialOutcome(
        action: RemedialActionType.teacherAlert,
        session: updated,
        message: "دعنا نكتشف هذا الدرس مع معلمنا مجدداً بقالب ممتع!",
      );
    }

    // Rule 1: 3 consecutive fails at the same level -> pause + log a skill gap.
    if (nextFails >= 3) {
      final updated = await _updateSession(
        session,
        attemptsCount: nextAttempts,
        consecutiveFails: nextFails,
        status: GameSessionStatus.pausedForRemediation,
      );
      await _logRemedialEvent(
        session: session,
        eventType: 'repeated_failure',
        triggerCondition: 'الخطأ 3 مرات متتالية في نفس مستوى النشاط',
        actionTaken: 'إيقاف مؤقت للجلسة، حفظ النقاط، وتسجيل فجوة مهارية للخلفية',
      );
      return RemedialOutcome(
        action: RemedialActionType.encourageAndPause,
        session: updated,
        message: 'لا بأس، السنديانة معك دائماً! لنشاهد شرحاً قصيراً معاً 🌱',
      );
    }

    // Rule 2: 2 fails at Medium/Advanced -> adaptive downgrade one level.
    if (nextFails >= 2 && session.level != AdaptiveLevel.weak) {
      final downgraded = session.level.downgraded;
      final updated = await _updateSession(
        session,
        attemptsCount: nextAttempts,
        consecutiveFails: 0,
        level: downgraded,
        isRemediation: true,
        remediationOfGameKey: session.gameKey,
      );
      await _logRemedialEvent(
        session: session,
        eventType: 'adaptive_downgrade',
        triggerCondition: 'الخطأ في المستوى المتقدم أو المتوسط مرتين',
        actionTaken: 'خفض مستوى التحدي درجة واحدة وتقديم تلميحات ذكية مرئية',
      );
      return RemedialOutcome(
        action: RemedialActionType.adaptiveDowngrade,
        session: updated,
        message: 'لنجرب مستوى أسهل قليلاً مع بعض التلميحات المرئية ✨',
      );
    }

    final updated = await _updateSession(session, attemptsCount: nextAttempts, consecutiveFails: nextFails);
    return RemedialOutcome(action: RemedialActionType.none, session: updated, message: 'حاول مجدداً، أنت قريب!');
  }

  Future<GameSession> _updateSession(
    GameSession session, {
    required int attemptsCount,
    required int consecutiveFails,
    GameSessionStatus? status,
    AdaptiveLevel? level,
    bool? isRemediation,
    String? remediationOfGameKey,
  }) async {
    final row = await _client
        .from('game_sessions')
        .update({
          'attempts_count': attemptsCount,
          'consecutive_fails': consecutiveFails,
          if (status != null) 'status': status.dbValue,
          if (level != null) 'level': level.dbValue,
          if (isRemediation != null) 'is_remediation': isRemediation,
          if (remediationOfGameKey != null) 'remediation_of_game_key': remediationOfGameKey,
          if (status != null && status != GameSessionStatus.inProgress) 'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('session_id', session.sessionId)
        .select()
        .single();
    return GameSession.fromMap(row);
  }

  Future<void> _logRemedialEvent({
    required GameSession session,
    required String eventType,
    required String triggerCondition,
    required String actionTaken,
  }) async {
    await _client.from('remedial_events').insert({
      'student_id': session.studentId,
      'game_key': session.gameKey,
      'event_type': eventType,
      'trigger_condition': triggerCondition,
      'action_taken': actionTaken,
    });
  }

  Future<void> _awardBadgeAndGrowTree(String studentId, {required String badge, int points = 0}) async {
    final row = await _client
        .from('student_progress')
        .select()
        .eq('student_id', studentId)
        .single();
    final badges = List<String>.from(row['badges_unlocked'] as List<dynamic>? ?? const []);
    if (!badges.contains(badge)) badges.add(badge);
    await _client.from('student_progress').update({
      'badges_unlocked': badges,
      'oak_leaves': ((row['oak_leaves'] as num?) ?? 0) + points,
      'tree_growth_stage': ((row['tree_growth_stage'] as num?) ?? 0) + 1,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('student_id', studentId);
  }

  /// Called by the generic game shell whenever a normal (non-remediation)
  /// session completes successfully, to grant its listed points/badge.
  Future<void> awardGameReward(String studentId, {required int points, String? badge}) async {
    final row = await _client
        .from('student_progress')
        .select()
        .eq('student_id', studentId)
        .single();
    final badges = List<String>.from(row['badges_unlocked'] as List<dynamic>? ?? const []);
    if (badge != null && !badges.contains(badge)) badges.add(badge);
    await _client.from('student_progress').update({
      'badges_unlocked': badges,
      'oak_leaves': ((row['oak_leaves'] as num?) ?? 0) + points,
      'tree_growth_stage': ((row['tree_growth_stage'] as num?) ?? 0) + 1,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('student_id', studentId);
  }
}
