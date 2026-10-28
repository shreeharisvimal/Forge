// Progress feature providers for the Forge application.
//
// Composes the repositories and the analytics domain into the read models
// the Progress tab renders: the range-scoped analytics snapshot, the
// lifetime snapshot that powers achievements, and the per-window lists each
// section watches. Every provider watches the box-change stream it reads so
// the tab stays live after any save from any feature.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;

import '../../../models/exercise.dart';
import '../../../models/personal_record.dart';
import '../../../models/weight_entry.dart';
import '../../../models/workout_session.dart';
import '../../../services/providers.dart';
import '../../body/domain/body_goals.dart';
import '../../body/domain/body_measurement_fields.dart';
import '../../exercises/providers/exercise_library_providers.dart';
import '../../prs/data/pr_event.dart';
import '../../prs/providers/pr_providers.dart';
import '../data/progress_box_watchers.dart';
import '../domain/achievements.dart';
import '../domain/analytics_models.dart';
import '../domain/analytics_range.dart';
import '../domain/progress_calculations.dart';

/// The Progress tab's notion of "now". Overridden in tests to pin a date.
final progressNowProvider = Provider<DateTime>((_) => DateTime.now());

/// The selected analytics window.
final progressRangeProvider = legacy.StateProvider<AnalyticsRange>(
  (_) => AnalyticsRange.last90Days,
);

/// Every stored workout session, in insertion order.
final progressSessionsProvider = Provider<List<WorkoutSession>>((ref) {
  ref.watch(progressSessionBoxChangesProvider);
  return ref.watch(workoutSessionRepositoryProvider).all();
});

/// Every stored weigh-in, oldest first.
final progressWeightEntriesProvider = Provider<List<WeightEntry>>((ref) {
  ref.watch(progressWeightBoxChangesProvider);
  final all = ref.watch(weightRepositoryProvider).all();
  all.sort((a, b) => a.date.compareTo(b.date));
  return all;
});

/// Every personal-record event, newest first.
final progressPrEventsProvider = Provider<List<PrEvent>>((ref) {
  ref.watch(progressPrEventsBoxChangesProvider);
  final all = ref.watch(prEventRepositoryProvider).all();
  all.sort((a, b) => b.date.compareTo(a.date));
  return all;
});

/// Every stored lifetime personal-record best.
final progressRecordsProvider = Provider<List<PersonalRecord>>((ref) {
  ref.watch(progressRecordBoxChangesProvider);
  return ref.watch(personalRecordRepositoryProvider).all();
});

/// The exercise library keyed by id, for analytics decoration.
final progressExercisesByIdProvider = Provider<Map<String, Exercise>>((ref) {
  ref.watch(exerciseBoxChangesProvider);
  return {
    for (final exercise in ref.watch(exerciseRepositoryProvider).all())
      exercise.id: exercise,
  };
});

/// The body-weight goal, or null when none is set.
final progressGoalWeightProvider = Provider<BodyGoal?>((ref) {
  ref.watch(progressGoalsBoxChangesProvider);
  return ref.watch(bodyGoalRepositoryProvider).forField(BodyField.weight);
});

/// The full analytics snapshot for the selected range.
final progressSnapshotProvider = Provider<AnalyticsSnapshot>((ref) {
  return ProgressCalculations.compute(
    sessions: ref.watch(progressSessionsProvider),
    now: ref.watch(progressNowProvider),
    range: ref.watch(progressRangeProvider),
    weightEntries: ref.watch(progressWeightEntriesProvider),
    prEvents: ref.watch(progressPrEventsProvider),
    records: ref.watch(progressRecordsProvider),
    exercisesById: ref.watch(progressExercisesByIdProvider),
    formula: ref.watch(prFormulaProvider),
  );
});

/// The lifetime snapshot, which the achievement engine evaluates against.
final progressLifetimeSnapshotProvider = Provider<AnalyticsSnapshot>((ref) {
  return ProgressCalculations.compute(
    sessions: ref.watch(progressSessionsProvider),
    now: ref.watch(progressNowProvider),
    range: AnalyticsRange.lifetime,
    weightEntries: ref.watch(progressWeightEntriesProvider),
    prEvents: ref.watch(progressPrEventsProvider),
    records: ref.watch(progressRecordsProvider),
    exercisesById: ref.watch(progressExercisesByIdProvider),
    formula: ref.watch(prFormulaProvider),
  );
});

/// Every achievement evaluated against the lifetime history.
final progressAchievementsProvider = Provider<List<AchievementState>>((ref) {
  final score = ref.watch(strengthScoreProvider);
  return AchievementEngine.evaluate(
    snapshot: ref.watch(progressLifetimeSnapshotProvider),
    score: score.overall,
    bodyweightRatio: score.bodyweightRatio,
    weighInCount: ref.watch(progressWeightEntriesProvider).length,
  );
});
