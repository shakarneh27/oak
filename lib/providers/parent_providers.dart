import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/student_progress.dart';
import '../services/message_service.dart';
import 'core_providers.dart';
import 'data_providers.dart';

final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService(ref.watch(supabaseClientProvider));
});

/// The parent's first linked child (profile + live-ish progress row).
class ParentChild {
  final AppUser profile;
  final StudentProgress progress;

  const ParentChild({required this.profile, required this.progress});

  /// Tree growth as a 0–100 percentage for the OakTree widget (each
  /// growth step from the remedial/reward engine ≈ 5%).
  double get growthPercent =>
      (progress.treeGrowthStage * 5).clamp(0, 100).toDouble();
}

final parentChildProvider = FutureProvider<ParentChild?>((ref) async {
  final rows = await ref.watch(linkedStudentsProvider.future);
  if (rows.isEmpty) return null;
  final first = rows.first;
  final profile = AppUser.fromMap(first['profile'] as Map<String, dynamic>);
  final progressMap = first['progress'] as Map<String, dynamic>?;
  return ParentChild(
    profile: profile,
    progress: progressMap != null
        ? StudentProgress.fromMap(progressMap)
        : StudentProgress.initial(profile.id),
  );
});

/// The teacher of the linked child's classroom (for الرسائل / تواصل).
final childTeacherProvider = FutureProvider<AppUser?>((ref) async {
  final child = await ref.watch(parentChildProvider.future);
  if (child == null) return null;
  return ref
      .watch(messageServiceProvider)
      .findTeacherForClassroom(child.profile.classroom);
});

/// Live message stream for the signed-in user (RLS-scoped).
final myMessagesProvider = StreamProvider<List<OakMessage>>((ref) {
  return ref.watch(messageServiceProvider).watchMyMessages();
});

/// Learning minutes per weekday (Sun..Sat) over the last 7 days, computed
/// from the child's game_sessions durations — backs the weekly chart.
final childWeeklyMinutesProvider = FutureProvider<List<int>>((ref) async {
  final child = await ref.watch(parentChildProvider.future);
  if (child == null) return List.filled(7, 0);
  final client = ref.watch(supabaseClientProvider);
  final since = DateTime.now().subtract(const Duration(days: 7));
  final rows = await client
      .from('game_sessions')
      .select('started_at, ended_at')
      .eq('student_id', child.profile.id)
      .gte('started_at', since.toIso8601String());

  final minutes = List.filled(7, 0);
  for (final row in rows) {
    final start = DateTime.tryParse(row['started_at'] as String? ?? '');
    if (start == null) continue;
    final end =
        DateTime.tryParse(row['ended_at'] as String? ?? '') ??
        start.add(const Duration(minutes: 5));
    // cap a single session's contribution at 30 minutes
    final duration = end.difference(start).inMinutes.clamp(1, 30);
    // DateTime.weekday: Mon=1..Sun=7 -> index Sun=0..Sat=6
    final index = start.toLocal().weekday % 7;
    minutes[index] += duration;
  }
  return minutes;
});

/// Completed-activity count and learning streak (consecutive days with
/// activity, counting back from today) for the stat tiles.
final childSessionStatsProvider =
    FutureProvider<({int completed, int streakDays})>((ref) async {
      final child = await ref.watch(parentChildProvider.future);
      if (child == null) return (completed: 0, streakDays: 0);
      final client = ref.watch(supabaseClientProvider);
      final rows = await client
          .from('game_sessions')
          .select('started_at, status')
          .eq('student_id', child.profile.id);

      final completed = rows.where((r) => r['status'] == 'completed').length;
      final activeDays = <DateTime>{
        for (final r in rows)
          if (DateTime.tryParse(r['started_at'] as String? ?? '') case final d?)
            DateTime(d.toLocal().year, d.toLocal().month, d.toLocal().day),
      };
      var streak = 0;
      var day = DateTime.now();
      while (activeDays.contains(DateTime(day.year, day.month, day.day))) {
        streak += 1;
        day = day.subtract(const Duration(days: 1));
      }
      return (completed: completed, streakDays: streak);
    });

/// Lessons the child excels at / struggles with, derived from completed
/// sessions vs remedial events joined onto the games catalog.
final childTopicsProvider =
    FutureProvider<({List<String> strong, List<String> weak})>((ref) async {
      final child = await ref.watch(parentChildProvider.future);
      if (child == null)
        return (strong: const <String>[], weak: const <String>[]);
      final client = ref.watch(supabaseClientProvider);

      final games = await ref.watch(allGamesProvider.future);
      final lessonByGame = {for (final g in games) g.gameKey: g.lessonName};

      final sessions = await client
          .from('game_sessions')
          .select('game_key, status')
          .eq('student_id', child.profile.id);
      final remedials = await client
          .from('remedial_events')
          .select('game_key')
          .eq('student_id', child.profile.id);

      final weakLessons = <String>{
        for (final r in remedials)
          if (lessonByGame[r['game_key']] != null) lessonByGame[r['game_key']]!,
      };
      final strongLessons = <String>{
        for (final s in sessions)
          if (s['status'] == 'completed' &&
              lessonByGame[s['game_key']] != null &&
              !weakLessons.contains(lessonByGame[s['game_key']]))
            lessonByGame[s['game_key']]!,
      };
      return (
        strong: strongLessons.take(3).toList(),
        weak: weakLessons.take(3).toList(),
      );
    });
