// Shared test data for the calendar feature golden tests.
//
// Seeds a realistic Hive store with calendar rows, weigh-ins, a full body
// measurement, completed sessions and a personal record so the calendar
// golden asserts against a rich, deterministic February 2026 frame.
library;

import 'package:forge/database/database_service.dart';
import 'package:forge/models/body_measurement.dart';
import 'package:forge/models/calendar_day.dart';
import 'package:forge/models/exercise.dart';
import 'package:forge/models/personal_record.dart';
import 'package:forge/models/weight_entry.dart';
import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_session.dart';
import 'package:forge/models/workout_set.dart';
import 'package:forge/services/repositories/calendar_repository.dart';
import 'package:forge/services/repositories/exercise_repository.dart';
import 'package:forge/services/repositories/measurement_repository.dart';
import 'package:forge/services/repositories/personal_record_repository.dart';
import 'package:forge/services/repositories/weight_repository.dart';
import 'package:forge/services/repositories/workout_session_repository.dart';

/// The pinned calendar clock used by the golden (Wed 09:00).
final DateTime pinnedCalendarNow = DateTime(2026, 2, 4, 9);

/// Seeds a rich dataset into [databaseService] for the calendar golden.
Future<void> seedCalendarData(DatabaseService databaseService) async {
  final exerciseRepository = HiveExerciseRepository(databaseService.exerciseBox);
  await exerciseRepository.save(Exercise(
    id: 'ex-bench',
    name: 'Bench Press',
    muscleGroup: 'Chest',
    equipment: 'Barbell',
    isCompound: true,
  ));
  await exerciseRepository.save(Exercise(
    id: 'ex-row',
    name: 'Barbell Row',
    muscleGroup: 'Back',
    equipment: 'Barbell',
    isCompound: true,
  ));

  final calendarRepository =
      HiveCalendarRepository(databaseService.calendarBox);
  await calendarRepository.save(CalendarDay(
    date: DateTime(2026, 2, 3),
    waterLitres: 2.5,
    mood: 3,
    notes: 'Easy rest day',
  ));
  await calendarRepository.save(CalendarDay(
    date: DateTime(2026, 2, 4),
    weight: 82,
    workoutCompleted: true,
    sleepHours: 7.5,
    waterLitres: 3.0,
    mood: 4,
    notes: 'Great session',
    durationMinutes: 45,
  ));

  final weightRepository = HiveWeightRepository(databaseService.weightBox);
  await weightRepository
      .save(WeightEntry(date: DateTime(2026, 2, 3), weight: 81.5));
  await weightRepository
      .save(WeightEntry(date: DateTime(2026, 2, 4), weight: 82.0));

  final measurementRepository =
      HiveMeasurementRepository(databaseService.measurementBox);
  await measurementRepository.save(BodyMeasurement(
    date: DateTime(2026, 2, 4),
    waist: 80,
    chest: 100,
    leftArm: 38,
    bodyFat: 18,
  ));

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

  final prRepository = HivePersonalRecordRepository(databaseService.prBox);
  await prRepository.save(PersonalRecord(
    exerciseId: 'ex-bench',
    highestWeight: 80,
    bestReps: 8,
    estimatedOneRM: 100,
    lastUpdated: DateTime(2026, 2, 3, 12),
  ));
}
