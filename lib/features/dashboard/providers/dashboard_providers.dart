// Dashboard providers for the Forge application.
//
// Composes the repositories into the read models each dashboard panel
// renders. Every provider watches the relevant box-change stream so the
// dashboard stays live after any save, and each panel watches only the data
// it needs so edits elsewhere never rebuild the whole screen.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/body_measurement.dart';
import '../../../models/exercise.dart';
import '../../../models/personal_record.dart';
import '../../../models/settings_model.dart';
import '../../../services/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../services/repositories/exercise_history_repository.dart';
import '../data/dashboard_box_watchers.dart';
import '../domain/dashboard_calculations.dart';
import '../domain/dashboard_models.dart';
import '../domain/quote_engine.dart';
import '../domain/recovery_service.dart';

/// The dashboard's notion of "now".
///
/// Exposed as a provider so tests can pin a fixed date.
final dashboardNowProvider = Provider<DateTime>((_) => DateTime.now());

/// The current [SettingsModel], reactive to the settings box.
final dashboardSettingsProvider = Provider<SettingsModel>((ref) {
  ref.watch(settingsBoxChangesProvider);
  return ref.watch(settingsRepositoryProvider).current ?? SettingsModel();
});

/// Muscle recovery readings for the six dashboard buckets.
final recoveryProvider = Provider<List<MuscleRecovery>>((ref) {
  ref.watch(sessionBoxChangesProvider);
  final now = ref.watch(dashboardNowProvider);
  final sessions = ref.watch(workoutSessionRepositoryProvider).all();

  final exercisesById = {
    for (final exercise in ref.watch(exerciseRepositoryProvider).all())
      exercise.id: exercise,
  };
  final resolve = LibraryRecoveryResolver.fromLibrary(exercisesById);
  return RecoveryService.compute(sessions: sessions, now: now, resolve: resolve);
});

/// The current weight panel data.
final weightPanelProvider = Provider<DashboardWeightData>((ref) {
  ref.watch(weightBoxChangesProvider);
  final settings = ref.watch(dashboardSettingsProvider);
  final repository = ref.watch(weightRepositoryProvider);

  final entries = repository.between(
    dateOnly(ref.watch(dashboardNowProvider)).subtract(const Duration(days: 13)),
    dateOnly(ref.watch(dashboardNowProvider)),
  );

  double? delta;
  if (entries.length >= 2) {
    delta = entries.last.weight - entries[entries.length - 2].weight;
  }

  return DashboardWeightData(
    latest: repository.latest()?.weight,
    delta: delta,
    trend: [for (final entry in entries) WeightPoint(date: entry.date, weight: entry.weight)],
    goal: settings.goalWeight,
    unit: settings.weightUnit,
  );
});

/// The weekly summary panel data.
final weeklySummaryProvider = Provider<WeeklySummaryData>((ref) {
  ref.watch(sessionBoxChangesProvider);
  return DashboardCalculations.weeklySummary(
    sessions: ref.watch(workoutSessionRepositoryProvider).all(),
    now: ref.watch(dashboardNowProvider),
  );
});

/// The most recent personal records with their previous bests.
final recentPrsProvider = Provider<List<RecentPrEntry>>((ref) {
  ref.watch(prBoxChangesProvider);
  ref.watch(historyBoxChangesProvider);

  final prs = [...ref.watch(personalRecordRepositoryProvider).all()]
    ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

  final exercisesById = {
    for (final exercise in ref.watch(exerciseRepositoryProvider).all())
      exercise.id: exercise,
  };

  return [
    for (final record in prs.take(3))
      _prEntry(
        record,
        exercisesById,
        ref.watch(exerciseHistoryRepositoryProvider),
      ),
  ];
});

RecentPrEntry _prEntry(
  PersonalRecord record,
  Map<String, Exercise> exercisesById,
  ExerciseHistoryRepository historyRepository,
) {
  final exercise = exercisesById[record.exerciseId];
  return RecentPrEntry(
    exerciseId: record.exerciseId,
    exerciseName: exercise?.name ?? 'Exercise',
    estimatedOneRM: record.estimatedOneRM,
    bestWeight: record.highestWeight,
    bestReps: record.bestReps,
    previous: DashboardCalculations.previousBest(
      history: historyRepository.forExercise(record.exerciseId),
      before: record.lastUpdated,
    ),
    date: record.lastUpdated,
  );
}

/// The split day scheduled for today, plus whether it was already logged.
final todayWorkoutProvider = Provider<TodayWorkoutData>((ref) {
  ref.watch(splitBoxChangesProvider);
  ref.watch(sessionBoxChangesProvider);
  final now = ref.watch(dashboardNowProvider);

  final split = ref.watch(workoutSplitRepositoryProvider).activeSplit;
  if (split == null || split.days.isEmpty) {
    return const TodayWorkoutData(
      hasSplit: false,
      splitName: null,
      splitColor: 0xFF7C4DFF,
      today: null,
      loggedToday: false,
    );
  }

  final schedule = WeeklySplitSchedule(
    split: split,
    days: split.days,
    createdAt: split.createdAt,
  );
  final today = schedule.snapshotFor(now);

  final sessions = ref.watch(workoutSessionRepositoryProvider).all();
  final loggedToday = sessions
      .where((session) =>
          dateOnly(session.date).isAtSameMomentAs(dateOnly(now)))
      .any((session) => session.exercises.any(
            (performed) => performed.sets.any((set) => set.completed),
          ));

  if (today.day.isRestDay) {
    return TodayWorkoutData(
      hasSplit: true,
      splitName: split.name,
      splitColor: split.color,
      today: today,
      loggedToday: loggedToday,
    );
  }

  final exercisesById = {
    for (final exercise in ref.watch(exerciseRepositoryProvider).all())
      exercise.id: exercise,
  };
  final recovery = RecoveryService.compute(
    sessions: sessions,
    now: now,
    resolve: LibraryRecoveryResolver.fromLibrary(exercisesById),
  );

  var estimatedSeconds = 0;
  final buckets = <RecoveryGroup>{};
  var records = 0;
  final recordRepository = ref.watch(personalRecordRepositoryProvider);

  for (final assignment in today.day.exercises) {
    final sets = assignment.sets > 0 ? assignment.sets : 3;
    final rest = assignment.restSeconds > 0 ? assignment.restSeconds : 90;
    estimatedSeconds += sets * (rest + 45);
    final exercise = exercisesById[assignment.exerciseId];
    if (exercise != null) {
      buckets.addAll(RecoveryGroupResolver.resolve(exercise.muscleGroup));
      if (recordRepository.forExercise(assignment.exerciseId) != null) {
        records++;
      }
    }
  }

  final muscleRecovery = {for (final reading in recovery) reading.group: reading};
  final touched = [
    for (final group in buckets)
      if (muscleRecovery[group] != null) muscleRecovery[group]!,
  ];
  final recoveryPercent = touched.isEmpty
      ? null
      : touched.fold<double>(0, (sum, r) => sum + r.percent) / touched.length;

  return TodayWorkoutData(
    hasSplit: true,
    splitName: split.name,
    splitColor: split.color,
    today: today,
    loggedToday: loggedToday,
    estimatedMinutes: (estimatedSeconds / 60).round(),
    muscleGroups: [for (final group in buckets) group.label],
    recoveryPercent: recoveryPercent,
    recordCount: records,
  );
});

/// The next scheduled training day after today.
final upcomingWorkoutProvider = Provider<SplitDaySnapshot?>((ref) {
  ref.watch(splitBoxChangesProvider);
  final now = ref.watch(dashboardNowProvider);

  final split = ref.watch(workoutSplitRepositoryProvider).activeSplit;
  if (split == null || split.days.isEmpty) return null;

  return DashboardCalculations.nextTrainingDay(
    days: split.days,
    splitCreatedAt: split.createdAt,
    from: now,
  );
});

/// The day's motivational quote.
final dailyQuoteProvider = Provider<DashboardQuote>((ref) {
  return QuoteEngine.forDate(ref.watch(dashboardNowProvider));
});

/// The recent activity feed (workouts, weigh-ins, measurements, records).
final recentActivityProvider = Provider<List<ActivityItem>>((ref) {
  ref.watch(sessionBoxChangesProvider);
  ref.watch(weightBoxChangesProvider);
  ref.watch(measurementBoxChangesProvider);
  ref.watch(prBoxChangesProvider);

  final items = <ActivityItem>[];

  for (final session in ref.watch(workoutSessionRepositoryProvider).recent(4)) {
    final exerciseCount = session.exercises.length;
    final minutes = session.durationMinutes;
    items.add(ActivityItem(
      kind: ActivityKind.workout,
      title: exerciseCount == 1
          ? 'Completed a workout'
          : 'Completed $exerciseCount exercises',
      subtitle: minutes > 0 ? '$minutes minutes' : null,
      date: session.date,
    ));
  }

  for (final entry in [...ref.watch(weightRepositoryProvider).all()]) {
    items.add(ActivityItem(
      kind: ActivityKind.weight,
      title: 'Logged a weigh-in',
      subtitle: '${entry.weight} ${ref.watch(dashboardSettingsProvider).weightUnit}',
      date: entry.date,
    ));
  }

  for (final measurement in [...ref.watch(measurementRepositoryProvider).all()]
    ..sort((a, b) => b.date.compareTo(a.date))
    ..take(3)) {
    items.add(ActivityItem(
      kind: ActivityKind.measurement,
      title: 'Logged body measurements',
      subtitle: _measurementSummary(measurement),
      date: measurement.date,
    ));
  }

  final prs = [...ref.watch(personalRecordRepositoryProvider).all()]
    ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  final exercisesById = {
    for (final exercise in ref.watch(exerciseRepositoryProvider).all())
      exercise.id: exercise,
  };
  for (final record in prs.take(3)) {
    items.add(ActivityItem(
      kind: ActivityKind.record,
      title: 'Set a new personal record',
      subtitle: exercisesById[record.exerciseId]?.name ?? 'Exercise',
      date: record.lastUpdated,
    ));
  }

  items.sort((a, b) => b.date.compareTo(a.date));
  return items.take(8).toList();
});

String _measurementSummary(BodyMeasurement measurement) {
  final parts = <String>[];
  if (measurement.waist != null) parts.add('Waist');
  if (measurement.chest != null) parts.add('Chest');
  if (measurement.leftArm != null) parts.add('Arms');
  if (measurement.bodyFat != null) parts.add('Body fat');
  if (parts.isEmpty) return 'Full body';
  return parts.join(' · ');
}
