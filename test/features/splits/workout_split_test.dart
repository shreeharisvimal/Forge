// Tests for the workout split models and repository.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/models/workout_split.dart';
import 'package:forge/models/workout_split_day.dart';
import 'package:forge/models/workout_split_exercise.dart';
import 'package:forge/services/repositories/workout_split_repository.dart';

import '../../helpers/hive_test_env.dart';

WorkoutSplit buildSplit({
  String? id,
  String name = 'Push / Pull / Legs',
  bool isActive = false,
  int color = 0xFF7C4DFF,
  int iconCodePoint = 0xe306,
  List<WorkoutSplitDay>? days,
}) {
  return WorkoutSplit(
    id: id,
    name: name,
    isActive: isActive,
    color: color,
    iconCodePoint: iconCodePoint,
    days: days,
  );
}

void main() {
  group('WorkoutSplit model', () {
    test('round-trips through toMap/fromMap with nested days and exercises',
        () {
      final original = buildSplit(
        id: 'split-1',
        name: 'Upper / Lower',
        color: 0xFF00E5FF,
        iconCodePoint: 0xe4ee,
        isActive: true,
        days: [
          WorkoutSplitDay(
            id: 'day-1',
            name: 'Day 1 — Upper',
            focus: 'Chest / Back',
            exercises: [
              WorkoutSplitExercise(
                id: 'ex-1',
                exerciseId: 'e1',
                exerciseName: 'Bench Press',
                order: 0,
                sets: 4,
                reps: 6,
                rpe: 8,
                restSeconds: 120,
                tempo: '2-1-1',
              ),
              WorkoutSplitExercise(
                id: 'ex-2',
                exerciseId: 'e2',
                exerciseName: 'Barbell Row',
                order: 1,
                sets: 3,
                reps: 8,
              ),
            ],
          ),
          WorkoutSplitDay(id: 'day-2', name: 'Rest', isRestDay: true),
        ],
      );

      final restored = WorkoutSplit.fromMap(original.toMap());
      expect(restored, original);
      expect(restored.days, hasLength(2));
      expect(restored.days[0].exercises[0].exerciseName, 'Bench Press');
      expect(restored.days[0].exercises[0].rpe, 8);
      expect(restored.days[1].isRestDay, isTrue);
    });

    test('defaults are sensible', () {
      final split = buildSplit();
      expect(split.color, 0xFF7C4DFF);
      expect(split.isActive, isFalse);
      expect(split.days, isEmpty);
      expect(split.trainingDayCount, 0);
      expect(split.exerciseCount, 0);
    });

    test('copyWith replaces only the given fields', () {
      final split = buildSplit(name: 'PPL');
      final updated = split.copyWith(name: 'Full Body', isActive: true);

      expect(updated.name, 'Full Body');
      expect(updated.isActive, isTrue);
      expect(updated.days, isEmpty);
    });
  });

  group('WorkoutSplitRepository', () {
    late HiveTestEnv env;
    late WorkoutSplitRepository repository;

    setUp(() async {
      env = await HiveTestEnv.create();
      repository = HiveWorkoutSplitRepository(env.databaseService.splitBox);
    });

    tearDown(() => env.dispose());

    test('activeSplit returns null on a fresh install', () {
      expect(repository.activeSplit, isNull);
    });

    test('activate deactivates the previous active split', () async {
      await repository.saveAll([
        buildSplit(id: 'a', name: 'Split A', isActive: true),
        buildSplit(id: 'b', name: 'Split B'),
      ]);

      await repository.activate('b');

      expect(repository.byId('a')!.isActive, isFalse);
      expect(repository.byId('b')!.isActive, isTrue);
      expect(repository.activeSplit!.id, 'b');
    });

    test('deactivateAll clears every active flag', () async {
      await repository.saveAll([
        buildSplit(id: 'a', isActive: true),
        buildSplit(id: 'b', isActive: true),
      ]);

      await repository.deactivateAll();

      expect(repository.all().every((s) => !s.isActive), isTrue);
    });

    test('sorted returns newest first by updatedAt', () async {
      await repository.saveAll([
        buildSplit(id: 'old', name: 'Old'),
        buildSplit(id: 'new', name: 'New'),
      ]);
      await Future.delayed(const Duration(milliseconds: 5));
      await repository.save(repository.byId('old')!.copyWith(name: 'Old v2'));

      expect(repository.sorted().first.id, 'old');
    });
  });
}
