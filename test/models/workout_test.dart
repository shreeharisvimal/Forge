// Unit tests for the Workout model.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/models/workout.dart';

void main() {
  group('Workout', () {
    test('assigns a unique id and timestamps by default', () {
      final a = Workout(date: DateTime(2026, 8, 4));
      final b = Workout(date: DateTime(2026, 8, 4));
      expect(a.id, isNotEmpty);
      expect(a.id, isNot(b.id));
      expect(a.createdAt, isNotNull);
      expect(a.updatedAt, isNotNull);
    });

    test('round-trips through toMap/fromMap', () {
      final original = Workout(
        id: 'workout-1',
        date: DateTime(2026, 8, 4),
        durationMinutes: 55,
        notes: 'Leg day',
        exerciseIds: const ['e1', 'e2'],
        completed: true,
        volume: 7500,
        createdAt: DateTime(2026, 8, 3, 10),
        updatedAt: DateTime(2026, 8, 4, 20),
      );

      final restored = Workout.fromMap(original.toMap());
      expect(restored, original);
      expect(restored.id, 'workout-1');
      expect(restored.volume, 7500);
    });

    test('copyWith replaces only the given fields', () {
      final original = Workout(
        id: 'workout-1',
        date: DateTime(2026, 8, 4),
        notes: 'Leg day',
      );
      final updated = original.copyWith(notes: 'Push day', completed: true);

      expect(updated.id, original.id);
      expect(updated.date, original.date);
      expect(updated.notes, 'Push day');
      expect(updated.completed, isTrue);
    });

    test('equality follows value semantics', () {
      final date = DateTime(2026, 8, 4);
      final a = Workout(id: '1', date: date);
      final b = Workout(id: '1', date: date);
      final c = Workout(id: '2', date: date);
      expect(a, b);
      expect(a, isNot(c));
    });
  });
}
