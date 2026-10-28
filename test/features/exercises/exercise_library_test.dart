// Tests for the exercise library query surface and reference checker.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/exercises/data/exercise_reference_checker.dart';
import 'package:forge/models/exercise.dart';
import 'package:forge/models/workout.dart';
import 'package:forge/models/workout_template.dart';
import 'package:forge/services/repositories/exercise_history_repository.dart';
import 'package:forge/services/repositories/exercise_repository.dart';
import 'package:forge/services/repositories/personal_record_repository.dart';
import 'package:forge/services/repositories/workout_repository.dart';
import 'package:forge/services/repositories/workout_session_repository.dart';
import 'package:forge/services/repositories/workout_template_repository.dart';

import '../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;
  late ExerciseRepository repository;

  Exercise exercise({
    String? name,
    String muscleGroup = 'Chest',
    String equipment = 'Barbell',
    bool isCompound = false,
    bool favorite = false,
    bool archived = false,
    List<String>? tags,
    int usageCount = 0,
    DateTime? lastUsedAt,
    DateTime? createdAt,
  }) {
    return Exercise(
      name: name ?? 'Press',
      muscleGroup: muscleGroup,
      equipment: equipment,
      isCompound: isCompound,
      favorite: favorite,
      archived: archived,
      tags: tags,
      usageCount: usageCount,
      lastUsedAt: lastUsedAt,
      createdAt: createdAt,
    );
  }

  setUp(() async {
    env = await HiveTestEnv.create();
    repository = HiveExerciseRepository(env.databaseService.exerciseBox);
  });

  tearDown(() => env.dispose());

  group('search', () {
    test('matches name, muscle group, equipment and tags case-insensitively',
        () async {
      await repository.saveAll([
        exercise(name: 'Bench Press', tags: ['push']),
        exercise(name: 'Cable Fly', muscleGroup: 'Chest', equipment: 'Cable'),
        exercise(name: 'Squat', muscleGroup: 'Quadriceps'),
      ]);

      expect(repository.search('bench').map((e) => e.name), ['Bench Press']);
      expect(repository.search('CHEST').length, 2);
      expect(repository.search('cable').length, 1);
      expect(repository.search('push').length, 1);
      expect(repository.search('').length, 3);
      expect(repository.search('zzz'), isEmpty);
    });
  });

  group('filters', () {
    test('favorites returns only starred exercises sorted by name', () async {
      await repository.saveAll([
        exercise(name: 'Zebra', favorite: true),
        exercise(name: 'Apple', favorite: true),
        exercise(name: 'Plain'),
      ]);

      expect(repository.favorites().map((e) => e.name), ['Apple', 'Zebra']);
    });

    test('visible excludes archived exercises', () async {
      await repository.saveAll([
        exercise(name: 'Active'),
        exercise(name: 'Old', archived: true),
      ]);

      expect(repository.visible().length, 1);
      expect(repository.visible().single.name, 'Active');
    });

    test('byFirstLetter groups exercises under their initial', () async {
      await repository.saveAll([
        exercise(name: 'Bench Press'),
        exercise(name: 'Back Squat'),
        exercise(name: 'Curl'),
      ]);

      final grouped = repository.byFirstLetter();
      expect(grouped.keys, ['B', 'C']);
      expect(grouped['B']!.map((e) => e.name), ['Back Squat', 'Bench Press']);
    });
  });

  group('sorting', () {
    test('newest and oldest order by createdAt', () async {
      final old = exercise(name: 'Old', createdAt: DateTime(2024, 1, 1));
      final mid = exercise(name: 'Mid', createdAt: DateTime(2024, 6, 1));
      final newExercise =
          exercise(name: 'New', createdAt: DateTime(2025, 1, 1));
      await repository.saveAll([mid, old, newExercise]);

      expect(
        repository
            .sorted(repository.all(), ExerciseSort.newest)
            .map((e) => e.name),
        ['New', 'Mid', 'Old'],
      );
      expect(
        repository
            .sorted(repository.all(), ExerciseSort.oldest)
            .map((e) => e.name),
        ['Old', 'Mid', 'New'],
      );
    });

    test('mostUsed orders by usageCount and recentlyUsed by lastUsedAt',
        () async {
      await repository.saveAll([
        exercise(name: 'Rare', usageCount: 1, lastUsedAt: DateTime(2024)),
        exercise(name: 'Hot', usageCount: 9, lastUsedAt: DateTime(2025)),
        exercise(name: 'Never'),
      ]);

      expect(
        repository
            .sorted(repository.all(), ExerciseSort.mostUsed)
            .map((e) => e.name),
        ['Hot', 'Rare', 'Never'],
      );
      expect(
        repository
            .sorted(repository.all(), ExerciseSort.recentlyUsed)
            .map((e) => e.name),
        ['Hot', 'Rare', 'Never'],
      );
    });

    test('recordUsage increments usage and stamps lastUsedAt', () async {
      final e = exercise(name: 'Press', usageCount: 4);
      await repository.save(e);

      await repository.recordUsage(e);

      final updated = repository.byId(e.id)!;
      expect(updated.usageCount, 5);
      expect(updated.lastUsedAt, isNotNull);
    });
  });

  group('reference checker', () {
    test('counts references across workouts and templates', () async {
      final e = exercise(name: 'Squat');
      await repository.save(e);

      final workoutRepo =
          HiveWorkoutRepository(env.databaseService.workoutBox);
      final templateRepo =
          HiveWorkoutTemplateRepository(env.databaseService.templateBox);

      await workoutRepo.save(Workout(
        date: DateTime(2025, 1, 1),
        exerciseIds: [e.id],
        notes: 'Leg day',
      ));
      await templateRepo.save(WorkoutTemplate(
        name: 'T1',
        weekday: 1,
        exerciseIds: [e.id, 'other'],
      ));

      final checker = ExerciseReferenceChecker(
        workoutRepository: workoutRepo,
        workoutTemplateRepository: templateRepo,
        workoutSessionRepository:
            HiveWorkoutSessionRepository(env.databaseService.sessionBox),
        personalRecordRepository:
            HivePersonalRecordRepository(env.databaseService.prBox),
        exerciseHistoryRepository:
            HiveExerciseHistoryRepository(env.databaseService.historyBox),
      );

      final references = checker.referencesFor(e.id);
      expect(references.workouts, 1);
      expect(references.templates, 1);
      expect(references.isReferenced, isTrue);

      final untouched = checker.referencesFor('unknown-id');
      expect(untouched.total, 0);
    });
  });
}
