// Session launch provider for the Forge application.
//
// Derives the initial preparation session from the active split's training
// day, pre-filling each exercise with the user's most recent performance
// (history best weight/reps) and lifetime records. When no split or training
// day is scheduled the launch degrades to an empty free-form workout so the
// session screen always has something to start with.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/providers.dart';
import '../../dashboard/data/dashboard_box_watchers.dart';
import '../../dashboard/domain/dashboard_calculations.dart';
import '../domain/session_preparation.dart';
import 'session_providers.dart';

/// The name and planned exercises for a freshly opened session.
class SessionLaunchData {
  /// Creates launch data.
  const SessionLaunchData({required this.name, required this.plans});

  /// Display name of the session.
  final String name;

  /// Planned exercises (may be empty for a free-form workout).
  final List<ActiveExercisePlan> plans;
}

/// Builds the launch data from today's split day.
final sessionLaunchProvider = Provider<SessionLaunchData>((ref) {
  ref.watch(splitBoxChangesProvider);
  final now = ref.watch(sessionNowProvider);

  final split = ref.watch(workoutSplitRepositoryProvider).activeSplit;
  if (split == null || split.days.isEmpty) {
    return const SessionLaunchData(name: 'Workout', plans: []);
  }

  final schedule = WeeklySplitSchedule(
    split: split,
    days: split.days,
    createdAt: split.createdAt,
  );
  final today = schedule.snapshotFor(now);
  if (today.day.isRestDay) {
    return SessionLaunchData(name: split.name, plans: const []);
  }

  final historyRepository = ref.watch(exerciseHistoryRepositoryProvider);
  final recordRepository = ref.watch(personalRecordRepositoryProvider);

  final plans = <ActiveExercisePlan>[];
  for (final assignment in today.day.exercises) {
    final history = historyRepository.forExercise(assignment.exerciseId);
    final last = history.isEmpty ? null : history.last;
    final record = recordRepository.forExercise(assignment.exerciseId);
    plans.add(ActiveExercisePlan(
      exerciseId: assignment.exerciseId,
      exerciseName: assignment.exerciseName,
      targetSets: assignment.sets,
      targetReps: assignment.reps,
      rpe: assignment.rpe,
      restSeconds: assignment.restSeconds,
      tempo: assignment.tempo.isEmpty ? null : assignment.tempo,
      notes: assignment.notes,
      prefillWeight: last?.bestWeight ?? record?.highestWeight ?? 0,
      prefillReps: last?.bestReps,
    ));
  }
  return SessionLaunchData(name: today.day.name, plans: plans);
});
