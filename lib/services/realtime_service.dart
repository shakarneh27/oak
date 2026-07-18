import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Realtime Channels stand in for the Socket.io events listed in
/// the original spec. Row Level Security on each table already scopes what
/// a student / teacher / parent can see, so every stream below is safe to
/// subscribe to broadly — Postgres only ever sends rows the caller may read.
///
/// Socket.io event  -> Supabase Realtime equivalent
///   sync_tree_growth          -> watchStudentProgress
///   get_realtime_announcements-> watchAnnouncements
///   teacher_update             -> watchGameSessions / watchRemedialEvents
///   parent_sync_report         -> watchRemedialEvents (scoped by RLS to linked kids)
///   unlock_badge_trigger       -> watchStudentProgress (badges_unlocked diff)
class RealtimeService {
  final SupabaseClient _client;

  RealtimeService(this._client);

  Stream<List<Map<String, dynamic>>> watchStudentProgress(String studentId) {
    return _client
        .from('student_progress')
        .stream(primaryKey: ['student_id'])
        .eq('student_id', studentId);
  }

  Stream<List<Map<String, dynamic>>> watchGameSessions(String studentId) {
    return _client
        .from('game_sessions')
        .stream(primaryKey: ['session_id'])
        .eq('student_id', studentId)
        .order('started_at');
  }

  /// Broad stream of every session row the caller's RLS policy allows —
  /// used by the teacher dashboard to see live activity across a classroom.
  Stream<List<Map<String, dynamic>>> watchAllVisibleGameSessions() {
    return _client
        .from('game_sessions')
        .stream(primaryKey: ['session_id'])
        .order('started_at');
  }

  Stream<List<Map<String, dynamic>>> watchRemedialEvents(String studentId) {
    return _client
        .from('remedial_events')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .order('created_at');
  }

  /// Broad stream of remedial events visible to the caller (teacher sees
  /// their classroom, parent sees their linked children) via RLS.
  Stream<List<Map<String, dynamic>>> watchAllVisibleRemedialEvents() {
    return _client
        .from('remedial_events')
        .stream(primaryKey: ['id'])
        .order('created_at');
  }

  Stream<List<Map<String, dynamic>>> watchAnnouncements({int limit = 20}) {
    return _client
        .from('realtime_logs')
        .stream(primaryKey: ['log_id'])
        .order('created_at')
        .limit(limit);
  }

  Future<void> logEvent({
    required String studentId,
    required String eventType,
    Map<String, dynamic> payload = const {},
  }) async {
    await _client.from('realtime_logs').insert({
      'student_id': studentId,
      'event_type': eventType,
      'payload': payload,
    });
  }
}
