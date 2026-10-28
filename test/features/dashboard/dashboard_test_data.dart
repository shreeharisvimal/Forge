// Shared test data for the dashboard feature tests.
//
// Seeds a realistic Hive store with an active split, completed sessions,
// weigh-ins, a personal record and a goal so dashboard tests assert against
// a rich, deterministic dataset.
library;

import 'package:forge/database/database_service.dart';
import 'package:forge/models/exercise.dart';
import 'package:forge/models/exercise_history.dart';
import 'package:forge/models/personal_record.dart';
import 'package:forge/models/settings_model.dart';
import 'package:forge/models/weight_entry.dart';
import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_session.dart';
import 'package:forge/models/workout_set.dart';
import 'package:forge/models/workout_split.dart';
import 'package:forge/models/workout_split_day.dart';
import 'package:forge/models/workout_split_exercise.dart';
import 'package:forge/services/repositories/exercise_history_repository.dart';
import 'package:forge/services/repositories/exercise_repository.dart';
import 'package:forge/services/repositories/personal_record_repository.dart';
import 'package:forge/services/repositories/settings_repository.dart';
import 'package:forge/services/repositories/weight_repository.dart';
import 'package:forge/services/repositories/workout_session_repository.dart';
import 'package:forge/services/repositories/workout_split_repository.dart';

/// The pinned dashboard clock used across dashboard tests (Wed 09:00).
final DateTime pinnedDashboardNow = DateTime(2026, 2, 4, 9);

/// Seeds a rich dataset into [databaseService].
Future<void> seedDashboardData(DatabaseService databaseService) async {
  final exercises = [
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
  final exerciseRepository = HiveExerciseRepository(databaseService.exerciseBox);
  for (final exercise in exercises) {
    await exerciseRepository.save(exercise);
  }

  final split = WorkoutSplit(
    name: 'Push / Pull / Legs',
    isActive: true,
    createdAt: DateTime(2026, 2, 2),
    days: [
      WorkoutSplitDay(
        name: 'Legs',
        focus: 'Lower body',
        exercises: [
          WorkoutSplitExercise(
              exerciseId: 'ex-squat', exerciseName: 'Back Squat'),
        ],
      ),
      WorkoutSplitDay(
        name: 'Push',
        focus: 'Chest & shoulders',
        exercises: [
          WorkoutSplitExercise(
              exerciseId: 'ex-bench', exerciseName: 'Bench Press'),
          WorkoutSplitExercise(
              exerciseId: 'ex-ohp', exerciseName: 'Overhead Press'),
        ],
      ),
      WorkoutSplitDay(
        name: 'Pull',
        focus: 'Back work',
        exercises: [
          WorkoutSplitExercise(
              exerciseId: 'ex-row', exerciseName: 'Barbell Row'),
        ],
      ),
      WorkoutSplitDay(name: 'Rest', isRestDay: true),
      WorkoutSplitDay(name: 'Rest', isRestDay: true),
      WorkoutSplitDay(name: 'Rest', isRestDay: true),
      WorkoutSplitDay(name: 'Rest', isRestDay: true),
    ],
  );
  final splitRepository = HiveWorkoutSplitRepository(databaseService.splitBox);
  await splitRepository.save(split);
  await splitRepository.activate(split.id);

  final sessionRepository =
      HiveWorkoutSessionRepository(databaseService.sessionBox);
  await sessionRepository.save(WorkoutSession(
    date: DateTime(2026, 2, 4, 8),
    durationMinutes: 45,
    completed: true,
    exercises: [
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
    ],
  ));
  await sessionRepository.save(WorkoutSession(
    date: DateTime(2026, 2, 3, 18),
    durationMinutes: 30,
    completed: true,
    exercises: [
      WorkoutExercise(
        exerciseId: 'ex-bench',
        exerciseName: 'Bench Press',
        sets: [WorkoutSet(weight: 75, reps: 8, completed: true)],
      ),
    ],
  ));

  final weightRepository = HiveWeightRepository(databaseService.weightBox);
  await weightRepository
      .save(WeightEntry(date: DateTime(2026, 2, 3), weight: 81.5));
  await weightRepository
      .save(WeightEntry(date: DateTime(2026, 2, 4), weight: 82.0));

  final prRepository = HivePersonalRecordRepository(databaseService.prBox);
  await prRepository.save(PersonalRecord(
    exerciseId: 'ex-bench',
    highestWeight: 80,
    bestReps: 8,
    estimatedOneRM: 100,
    lastUpdated: DateTime(2026, 2, 3, 12),
  ));

  final historyRepository =
      HiveExerciseHistoryRepository(databaseService.historyBox);
  await historyRepository.save(ExerciseHistory(
    exerciseId: 'ex-bench',
    date: DateTime(2026, 2, 1),
    estimatedOneRM: 90,
  ));

  final settingsRepository = HiveSettingsRepository(databaseService.settingsBox);
  await settingsRepository
      .replace(SettingsModel(weightUnit: 'kg', goalWeight: 80));
}
