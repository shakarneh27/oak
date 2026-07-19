import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/student_progress.dart';
import 'core_providers.dart';

/// A classroom student with their progress row (as visible to the
/// signed-in teacher through RLS).
class TeacherStudent {
  final AppUser profile;
  final StudentProgress progress;

  const TeacherStudent({required this.profile, required this.progress});

  double get growthPercent =>
      (progress.treeGrowthStage * 5).clamp(0, 100).toDouble();
}

/// Students of the signed-in teacher's classrooms — RLS on `profiles`
/// and `student_progress` already scopes rows to their classes.
final teacherStudentsProvider = FutureProvider<List<TeacherStudent>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final profiles = await client.from('profiles').select().eq('role', 'student');
  if (profiles.isEmpty) return const [];
  final progressRows = await client.from('student_progress').select();
  final progressById = {
    for (final row in progressRows) row['student_id'] as String: row,
  };
  return [
    for (final row in profiles)
      TeacherStudent(
        profile: AppUser.fromMap(row),
        progress: progressById[row['id']] != null
            ? StudentProgress.fromMap(progressById[row['id']]!)
            : StudentProgress.initial(row['id'] as String),
      ),
  ];
});

/// Awards stars from the teacher: bumps the student's oak_leaves.
/// (Requires the `progress_update_teacher` policy from migration 0005.)
final awardStarsProvider = Provider((ref) {
  return (String studentId, int stars) async {
    final client = ref.read(supabaseClientProvider);
    final row = await client
        .from('student_progress')
        .select('oak_leaves')
        .eq('student_id', studentId)
        .single();
    await client
        .from('student_progress')
        .update({
          'oak_leaves': ((row['oak_leaves'] as num?) ?? 0) + stars,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('student_id', studentId);
  };
});
