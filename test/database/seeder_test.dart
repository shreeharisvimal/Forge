// Integration tests for the first-launch Seeder.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/database/default_exercises.dart';
import 'package:forge/database/seeder.dart';
import 'package:forge/services/repositories/exercise_repository.dart';

import '../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;
  late Seeder seeder;
  late ExerciseRepository exerciseRepository;
  late int seededCount;

  setUp(() async {
    env = await HiveTestEnv.create();
    exerciseRepository =
        HiveExerciseRepository(env.databaseService.exerciseBox);
    seeder = Seeder(
      databaseService: env.databaseService,
      exerciseRepository: exerciseRepository,
    );
    seededCount = defaultExercises().length;
  });

  tearDown(() => env.dispose());

  test('seeds the default catalog on first launch', () async {
    final seeded = await seeder.runIfNeeded();

    expect(seeded, greaterThan(0));
    expect(exerciseRepository.count, seeded);
    expect(env.databaseService.isFirstLaunch, isFalse);
  });

  test('is a no-op after the schema version is applied', () async {
    await seeder.runIfNeeded();
    final seededAgain = await seeder.runIfNeeded();

    expect(seededAgain, 0);
    expect(exerciseRepository.count, seededCount);
  });

  test('seeded exercises are unique by name and well categorized', () async {
    await seeder.runIfNeeded();

    final exercises = exerciseRepository.all();
    final names = exercises.map((exercise) => exercise.name).toSet();
    expect(names.length, exercises.length, reason: 'names must be unique');

    final muscleGroups = exerciseRepository.muscleGroups();
    expect(
      muscleGroups,
      containsAll(['Chest', 'Back', 'Shoulders', 'Quadriceps', 'Abs']),
    );

    final equipment = exercises.map((exercise) => exercise.equipment).toSet();
    expect(equipment, containsAll(['Barbell', 'Dumbbell', 'Cable']));
  });
}
