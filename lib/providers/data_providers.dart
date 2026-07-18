import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_definition.dart';
import '../models/student_progress.dart';
import 'core_providers.dart';

final unitsProvider = FutureProvider((ref) => ref.watch(catalogServiceProvider).fetchUnits());

final gamesForUnitProvider = FutureProvider.family<List<GameDefinition>, String>((ref, unitKey) {
  return ref.watch(catalogServiceProvider).fetchGames(unitKey: unitKey);
});

final allGamesProvider = FutureProvider((ref) => ref.watch(catalogServiceProvider).fetchGames());

/// Live "شجرة التقدم" sync — replaces the `sync_tree_growth` socket event.
final studentProgressProvider = StreamProvider.family<StudentProgress?, String>((ref, studentId) {
  return ref.watch(realtimeServiceProvider).watchStudentProgress(studentId).map(
        (rows) => rows.isEmpty ? null : StudentProgress.fromMap(rows.first),
      );
});

/// Live announcements feed for the student dashboard
/// (`get_realtime_announcements`).
final announcementsProvider = StreamProvider((ref) {
  return ref.watch(realtimeServiceProvider).watchAnnouncements();
});

/// Live feed for the teacher dashboard (`teacher_update`) — RLS restricts
/// rows to students in the signed-in teacher's classrooms.
final teacherGameSessionsProvider = StreamProvider((ref) {
  return ref.watch(realtimeServiceProvider).watchAllVisibleGameSessions();
});

final teacherRemedialEventsProvider = StreamProvider((ref) {
  return ref.watch(realtimeServiceProvider).watchAllVisibleRemedialEvents();
});

/// Live feed for the parent dashboard (`parent_sync_report`) — RLS
/// restricts rows to the signed-in parent's linked children.
final parentRemedialEventsProvider = StreamProvider((ref) {
  return ref.watch(realtimeServiceProvider).watchAllVisibleRemedialEvents();
});

/// The signed-in parent's linked children, with their current progress —
/// RLS on `parent_student_links` and `student_progress` scopes this to
/// only the caller's own kids.
final linkedStudentsProvider = FutureProvider((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final parentId = client.auth.currentUser?.id;
  if (parentId == null) return const <Map<String, dynamic>>[];
  final links = await client.from('parent_student_links').select('student_id').eq('parent_id', parentId);
  final studentIds = links.map((row) => row['student_id'] as String).toList();
  if (studentIds.isEmpty) return const <Map<String, dynamic>>[];

  final profiles = await client.from('profiles').select().inFilter('id', studentIds);
  final progressRows = await client.from('student_progress').select().inFilter('student_id', studentIds);
  final progressById = {for (final row in progressRows) row['student_id'] as String: row};

  return profiles
      .map((profile) => {
            'profile': profile,
            'progress': progressById[profile['id']],
          })
      .toList();
});
