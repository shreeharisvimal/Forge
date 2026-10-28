// Shared test data for the progress feature tests.
//
// Seeds a realistic Hive store with a rich training history across a 90-day
// window: completed sessions spanning weeks, weigh-ins, a body-weight goal,
// stored records and a handful of personal-record events, so progress tests
// assert against a deterministic dataset.
library;

import 'package:forge/database/database_service.dart';
import 'package:forge/features/body/data/body_goal_repository.dart';
import 'package:forge/features/body/domain/body_goals.dart';
import 'package:forge/features/body/domain/body_measurement_fields.dart';
import 'package:forge/features/prs/data/pr_event.dart';
import 'package:forge/features/prs/data/pr_event_repository.dart';
import 'package:forge/features/prs/domain/pr_types.dart';
import 'package:forge/models/exercise.dart';
import 'package:forge/models/personal_record.dart';
import 'package:forge/models/settings_model.dart';
import 'package:forge/models/weight_entry.dart';
import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_session.dart';
import 'package:forge/models/workout_set.dart';
import 'package:forge/services/repositories/exercise_repository.dart';
import 'package:forge/services/repositories/personal_record_repository.dart';
import 'package:forge/services/repositories/settings_repository.dart';
import 'package:forge/services/repositories/weight_repository.dart';
import 'package:forge/services/repositories/workout_session_repository.dart';

/// The pinned progress clock used across progress tests (Wed 09:00).
final DateTime pinnedProgressNow = DateTime(2026, 2, 4, 9);

/// Seeds a rich dataset into [databaseService].
Future<void> seedProgressData(DatabaseService databaseService) async {
  final exerciseRepository = HiveExerciseRepository(databaseService.exerciseBox);
  for (final exercise in _exercises) {
    await exerciseRepository.save(exercise);
  }

  final sessionRepository =
      HiveWorkoutSessionRepository(databaseService.sessionBox);
  for (final session in _sessions) {
    await sessionRepository.save(session);
  }

  final weightRepository = HiveWeightRepository(databaseService.weightBox);
  for (final entry in _weightEntries) {
    await weightRepository.save(entry);
  }

  final recordRepository =
      HivePersonalRecordRepository(databaseService.prBox);
  for (final record in _records) {
    await recordRepository.save(record);
  }

  final prEventRepository = HivePrEventRepository(databaseService.prEventsBox);
  for (final event in _prEvents) {
    await prEventRepository.save(event);
  }

  final goalRepository = HiveBodyGoalRepository(databaseService.bodyGoalsBox);
  await goalRepository.save(BodyGoal(
    field: BodyField.weight,
    target: 80,
    createdAt: DateTime(2025, 12, 1),
  ));

  final settingsRepository = HiveSettingsRepository(databaseService.settingsBox);
  await settingsRepository
      .replace(SettingsModel(weightUnit: 'kg', goalWeight: 80));
}

final List<Exercise> _exercises = [
  Exercise(
    id: 'ex-bench',
    name: 'Bench Press',
    muscleGroup: 'Chest',
    equipment: 'Barbell',
    isCompound: true,
  ),
  Exercise(
    id: 'ex-row',
    name: 'Barbell Row',
    muscleGroup: 'Back',
    equipment: 'Barbell',
    isCompound: true,
  ),
  Exercise(
    id: 'ex-ohp',
    name: 'Overhead Press',
    muscleGroup: 'Shoulders',
    equipment: 'Barbell',
    isCompound: true,
  ),
  Exercise(
    id: 'ex-squat',
    name: 'Back Squat',
    muscleGroup: 'Quadriceps',
    equipment: 'Barbell',
    isCompound: true,
  ),
];

WorkoutSession _bench(DateTime date, int minutes, double weight, int reps) =>
    WorkoutSession(
      date: date,
      durationMinutes: minutes,
      exercises: [
        WorkoutExercise(
          exerciseId: 'ex-bench',
          exerciseName: 'Bench Press',
          sets: [
            WorkoutSet(weight: weight, reps: reps, completed: true),
            WorkoutSet(weight: weight - 5, reps: reps - 1, completed: true),
          ],
        ),
      ],
    );

WorkoutSession _full(DateTime date, int minutes, List<WorkoutExercise> exercises) =>
    WorkoutSession(date: date, durationMinutes: minutes, exercises: exercises);

final List<WorkoutSession> _sessions = [
  // One session before the 90-day window so previous-period deltas exist.
  WorkoutSession(
    date: DateTime(2025, 10, 15, 18),
    durationMinutes: 40,
    exercises: [
      WorkoutExercise(
        exerciseId: 'ex-bench',
        exerciseName: 'Bench Press',
        sets: [WorkoutSet(weight: 60, reps: 8, completed: true)],
      ),
    ],
  ),
  _bench(DateTime(2025, 11, 25, 17), 50, 65, 8),
  _full(DateTime(2025, 12, 29, 18), 45, [
    WorkoutExercise(
      exerciseId: 'ex-bench',
      exerciseName: 'Bench Press',
      sets: [WorkoutSet(weight: 70, reps: 8, completed: true)],
    ),
    WorkoutExercise(
      exerciseId: 'ex-squat',
      exerciseName: 'Back Squat',
      sets: [WorkoutSet(weight: 90, reps: 5, completed: true)],
    ),
  ]),
  _full(DateTime(2026, 1, 13, 17), 55, [
    WorkoutExercise(
      exerciseId: 'ex-squat',
      exerciseName: 'Back Squat',
      sets: [WorkoutSet(weight: 100, reps: 5, completed: true)],
    ),
    WorkoutExercise(
      exerciseId: 'ex-ohp',
      exerciseName: 'Overhead Press',
      sets: [WorkoutSet(weight: 40, reps: 10, completed: true)],
    ),
  ]),
  _full(DateTime(2026, 1, 27, 18), 40, [
    WorkoutExercise(
      exerciseId: 'ex-bench',
      exerciseName: 'Bench Press',
      sets: [WorkoutSet(weight: 75, reps: 8, completed: true)],
    ),
    WorkoutExercise(
      exerciseId: 'ex-row',
      exerciseName: 'Barbell Row',
      sets: [WorkoutSet(weight: 70, reps: 10, completed: true)],
    ),
  ]),
  _bench(DateTime(2026, 2, 3, 18), 30, 80, 8),
  _full(DateTime(2026, 2, 4, 8), 45, [
    WorkoutExercise(
      exerciseId: 'ex-bench',
      exerciseName: 'Bench Press',
      sets: [
        WorkoutSet(weight: 80, reps: 8, completed: true),
        WorkoutSet(weight: 80, reps: 7, completed: true),
      ],
    ),
    WorkoutExercise(
      exerciseId: 'ex-row',
      exerciseName: 'Barbell Row',
      sets: [WorkoutSet(weight: 70, reps: 10, completed: true)],
    ),
  ]),
];

final List<WeightEntry> _weightEntries = [
  WeightEntry(date: DateTime(2025, 12, 15), weight: 81.0),
  WeightEntry(date: DateTime(2026, 1, 5), weight: 81.5),
  WeightEntry(date: DateTime(2026, 1, 20), weight: 82.0),
  WeightEntry(date: DateTime(2026, 2, 3), weight: 82.5),
];

final List<PersonalRecord> _records = [
  PersonalRecord(
    exerciseId: 'ex-bench',
    highestWeight: 80,
    bestReps: 8,
    estimatedOneRM: 100,
    lastUpdated: DateTime(2026, 1, 27, 12),
  ),
  PersonalRecord(
    exerciseId: 'ex-squat',
    highestWeight: 100,
    bestReps: 5,
    estimatedOneRM: 115,
    lastUpdated: DateTime(2026, 1, 13, 12),
  ),
  PersonalRecord(
    exerciseId: 'ex-ohp',
    highestWeight: 40,
    bestReps: 10,
    estimatedOneRM: 53,
    lastUpdated: DateTime(2026, 1, 13, 12),
  ),
  PersonalRecord(
    exerciseId: 'ex-row',
    highestWeight: 70,
    bestReps: 10,
    estimatedOneRM: 93,
    lastUpdated: DateTime(2026, 1, 27, 12),
  ),
];

final List<PrEvent> _prEvents = [
  PrEvent(
    exerciseId: 'ex-bench',
    exerciseName: 'Bench Press',
    type: PrType.estimatedOneRM.name,
    value: 100,
    previousValue: 90,
    date: DateTime(2026, 1, 27, 12),
  ),
  PrEvent(
    exerciseId: 'ex-bench',
    exerciseName: 'Bench Press',
    type: PrType.heaviestWeight.name,
    value: 80,
    previousValue: 75,
    date: DateTime(2026, 1, 27, 12),
  ),
  PrEvent(
    exerciseId: 'ex-squat',
    exerciseName: 'Back Squat',
    type: PrType.heaviestWeight.name,
    value: 100,
    previousValue: 0,
    date: DateTime(2025, 12, 29, 18),
  ),
];
