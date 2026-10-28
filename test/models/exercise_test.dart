// Unit tests for the Exercise model.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/models/exercise.dart';

void main() {
  group('Exercise', () {
    test('requires a name but defaults compound and notes', () {
      final exercise = Exercise(
        name: 'Back Squat',
        muscleGroup: 'Legs',
        equipment: 'Barbell',
      );
      expect(exercise.isCompound, isFalse);
      expect(exercise.notes, isEmpty);
    });

    test('round-trips through toMap/fromMap', () {
      final original = Exercise(
        id: 'exercise-1',
        name: 'Bench Press',
        muscleGroup: 'Chest',
        equipment: 'Barbell',
        isCompound: true,
        notes: 'Grip shoulder-width',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 2, 1),
      );

      final restored = Exercise.fromMap(original.toMap());
      expect(restored, original);
      expect(restored.muscleGroup, 'Chest');
      expect(restored.isCompound, isTrue);
    });

    test('library fields round-trip and keep their defaults', () {
      final original = Exercise(
        name: 'Lateral Raise',
        muscleGroup: 'Side Delts',
        equipment: 'Dumbbell',
        instructions: 'Raise to shoulder height.',
        defaultRestSeconds: 60,
        defaultSets: 4,
        defaultReps: 15,
        defaultRpe: 8.5,
        tempo: '2-1-1',
        tags: ['isolation'],
        secondaryMuscles: ['Rear Delts'],
        favorite: true,
        source: ExerciseSource.seed,
        archived: false,
        usageCount: 3,
        lastUsedAt: DateTime(2026, 3, 1),
      );

      final restored = Exercise.fromMap(original.toMap());
      expect(restored, original);
      expect(restored.defaultRpe, 8.5);
      expect(restored.usageCount, 3);
      expect(restored.source, ExerciseSource.seed);

      final minimal = Exercise(
        name: 'Plank',
        muscleGroup: 'Abs',
        equipment: 'Bodyweight',
      );
      expect(minimal.defaultRestSeconds, 90);
      expect(minimal.defaultSets, 3);
      expect(minimal.defaultReps, 10);
      expect(minimal.defaultRpe, isNull);
      expect(minimal.tags, isEmpty);
      expect(minimal.secondaryMuscles, isEmpty);
      expect(minimal.favorite, isFalse);
      expect(minimal.source, ExerciseSource.user);
      expect(minimal.archived, isFalse);
      expect(minimal.usageCount, 0);
      expect(minimal.lastUsedAt, isNull);
    });

    test('copyWith replaces only the given fields', () {
      final original = Exercise(
        name: 'Squat',
        muscleGroup: 'Legs',
        equipment: 'Barbell',
      );
      final updated = original.copyWith(muscleGroup: 'Glutes');

      expect(updated.name, 'Squat');
      expect(updated.muscleGroup, 'Glutes');
      expect(updated.equipment, 'Barbell');
    });
  });
}
