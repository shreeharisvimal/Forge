// Integration tests for the Hive-backed repositories.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/models/calendar_day.dart';
import 'package:forge/models/exercise.dart';
import 'package:forge/models/personal_record.dart';
import 'package:forge/models/settings_model.dart';
import 'package:forge/models/weight_entry.dart';
import 'package:forge/models/workout.dart';
import 'package:forge/models/workout_session.dart';
import 'package:forge/services/repositories/calendar_repository.dart';
import 'package:forge/services/repositories/exercise_repository.dart';
import 'package:forge/services/repositories/personal_record_repository.dart';
import 'package:forge/services/repositories/settings_repository.dart';
import 'package:forge/services/repositories/weight_repository.dart';
import 'package:forge/services/repositories/workout_repository.dart';
import 'package:forge/services/repositories/workout_session_repository.dart';

import '../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;

  setUp(() async => env = await HiveTestEnv.create());
  tearDown(() => env.dispose());

  group('BaseRepository CRUD', () {
    test('save, byId, update and delete round-trip', () async {
      final repo =
          HiveExerciseRepository(env.databaseService.exerciseBox);

      final exercise = Exercise(name: 'Squat', muscleGroup: 'Legs', equipment: 'Barbell');
      await repo.save(exercise);
      expect(repo.contains(exercise.id), isTrue);
      expect(repo.byId(exercise.id), exercise);
      expect(repo.count, 1);

      final updated = exercise.copyWith(notes: 'Deep');
      await repo.save(updated);
      expect(repo.byId(exercise.id)?.notes, 'Deep');
      expect(repo.count, 1, reason: 'update must not add a second row');

      await repo.delete(exercise.id);
      expect(repo.byId(exercise.id), isNull);
      expect(repo.count, 0);
    });

    test('saveAll, deleteAll and clear operate in batches', () async {
      final repo =
          HiveExerciseRepository(env.databaseService.exerciseBox);
      final items = [
        Exercise(name: 'A', muscleGroup: 'Chest', equipment: 'Barbell'),
        Exercise(name: 'B', muscleGroup: 'Back', equipment: 'Cable'),
        Exercise(name: 'C', muscleGroup: 'Legs', equipment: 'Machine'),
      ];

      await repo.saveAll(items);
      expect(repo.count, 3);

      await repo.deleteAll(items.map((item) => item.id));
      expect(repo.count, 0);
    });

    test('allByIds preserves order and drops missing ids', () async {
      final repo =
          HiveExerciseRepository(env.databaseService.exerciseBox);
      final a = Exercise(name: 'A', muscleGroup: 'Chest', equipment: 'Barbell');
      final b = Exercise(name: 'B', muscleGroup: 'Back', equipment: 'Cable');
      await repo.saveAll([a, b]);

      final result = repo.allByIds([b.id, 'missing', a.id]);
      expect(result.map((item) => item.name), ['B', 'A']);
    });
  });

  group('ExerciseRepository', () {
    late ExerciseRepository repo;

    setUp(() {
      repo = HiveExerciseRepository(env.databaseService.exerciseBox);
    });

    test('byName matches case-insensitively after trimming', () async {
      await repo.save(
        Exercise(name: 'Bench Press', muscleGroup: 'Chest', equipment: 'Barbell'),
      );

      expect(repo.byName('BENCH PRESS')?.id, isNotNull);
      expect(repo.byName('  bench press  ')?.id, isNotNull);
      expect(repo.byName('Deadlift'), isNull);
    });

    test('muscleGroups returns distinct sorted groups', () async {
      await repo.saveAll([
        Exercise(name: 'Squat', muscleGroup: 'Legs', equipment: 'Barbell'),
        Exercise(name: 'Bench', muscleGroup: 'Chest', equipment: 'Barbell'),
        Exercise(name: 'Pull-Up', muscleGroup: 'Back', equipment: 'Bodyweight'),
        Exercise(name: 'Lunge', muscleGroup: 'Legs', equipment: 'Dumbbell'),
      ]);

      expect(repo.muscleGroups(), ['Back', 'Chest', 'Legs']);
    });

    test('compounds only returns multi-joint exercises', () async {
      await repo.saveAll([
        Exercise(
          name: 'Squat',
          muscleGroup: 'Legs',
          equipment: 'Barbell',
          isCompound: true,
        ),
        Exercise(name: 'Curl', muscleGroup: 'Biceps', equipment: 'Barbell'),
      ]);

      expect(repo.compounds().single.name, 'Squat');
    });
  });

  group('WorkoutRepository', () {
    late WorkoutRepository repo;

    setUp(() {
      repo = HiveWorkoutRepository(env.databaseService.workoutBox);
    });

    test('onDate and between match at day precision', () async {
      final today = DateTime(2026, 8, 4);
      await repo.saveAll([
        Workout(id: 'a', date: today),
        Workout(id: 'b', date: DateTime(2026, 8, 5)),
        Workout(id: 'c', date: DateTime(2026, 7, 30)),
      ]);

      expect(repo.onDate(today).single.id, 'a');
      expect(repo.between(DateTime(2026, 8, 1), DateTime(2026, 8, 31)).length, 2);
      expect(repo.between(DateTime(2026, 8, 5), DateTime(2026, 8, 31)).single.id, 'b');
    });

    test('recent returns newest first', () async {
      await repo.saveAll([
        Workout(id: 'a', date: DateTime(2026, 8, 1)),
        Workout(id: 'b', date: DateTime(2026, 8, 4)),
        Workout(id: 'c', date: DateTime(2026, 8, 2)),
      ]);

      expect(repo.recent(2).map((workout) => workout.id), ['b', 'c']);
    });
  });

  group('WorkoutSessionRepository', () {
    late WorkoutSessionRepository repo;

    setUp(() {
      repo = HiveWorkoutSessionRepository(env.databaseService.sessionBox);
    });

    test('forWorkout filters by originating plan', () async {
      await repo.saveAll([
        WorkoutSession(
          id: 's1',
          workoutId: 'w1',
          date: DateTime(2026, 8, 4),
        ),
        WorkoutSession(id: 's2', date: DateTime(2026, 8, 5)),
        WorkoutSession(
          id: 's3',
          workoutId: 'w1',
          date: DateTime(2026, 8, 6),
        ),
      ]);

      expect(repo.forWorkout('w1').map((session) => session.id), ['s1', 's3']);
    });
  });

  group('WeightRepository', () {
    late WeightRepository repo;

    setUp(() {
      repo = HiveWeightRepository(env.databaseService.weightBox);
    });

    test('onDate, between and latest behave as expected', () async {
      await repo.saveAll([
        WeightEntry(id: 'a', date: DateTime(2026, 8, 2), weight: 80),
        WeightEntry(id: 'b', date: DateTime(2026, 8, 4), weight: 79.5),
        WeightEntry(id: 'c', date: DateTime(2026, 8, 10), weight: 79),
      ]);

      expect(repo.onDate(DateTime(2026, 8, 4, 18))?.weight, 79.5);
      expect(
        repo.between(DateTime(2026, 8, 3), DateTime(2026, 8, 9)).length,
        1,
      );
      expect(repo.latest()?.id, 'c');
    });
  });

  group('SettingsRepository', () {
    late SettingsRepository repo;

    setUp(() {
      repo = HiveSettingsRepository(env.databaseService.settingsBox);
    });

    test('current is null on a fresh install', () {
      expect(repo.current, isNull);
    });

    test('replace keeps exactly one settings row', () async {
      await repo.replace(SettingsModel(weightUnit: 'lb'));
      await repo.replace(SettingsModel(themeMode: 'dark', restTimer: 120));

      expect(repo.count, 1);
      expect(repo.current?.themeMode, 'dark');
      expect(repo.current?.restTimer, 120);
    });
  });

  group('PersonalRecordRepository', () {
    test('forExercise finds the row for an exercise', () async {
      final repo =
          HivePersonalRecordRepository(env.databaseService.prBox);
      await repo.save(PersonalRecord(exerciseId: 'e1', highestWeight: 100));
      await repo.save(PersonalRecord(exerciseId: 'e2', highestWeight: 50));

      expect(repo.forExercise('e1')?.highestWeight, 100);
      expect(repo.forExercise('nope'), isNull);
    });
  });

  group('CalendarRepository', () {
    test('onDate returns the row for the given day', () async {
      final repo = HiveCalendarRepository(env.databaseService.calendarBox);
      await repo.save(
        CalendarDay(
          id: 'c1',
          date: DateTime(2026, 8, 4),
          sleepHours: 7.5,
          mood: 4,
        ),
      );

      expect(repo.onDate(DateTime(2026, 8, 4))?.sleepHours, 7.5);
      expect(repo.onDate(DateTime(2026, 8, 5)), isNull);
    });
  });
}
