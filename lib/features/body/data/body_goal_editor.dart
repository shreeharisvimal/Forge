// Body goal persistence for the Forge application.
//
// Writes and removes [BodyGoal] targets through the [BodyGoalRepository].
// One goal per field: setting a target for a field that already has a goal
// updates it in place.
library;

import '../domain/body_goals.dart';
import '../domain/body_measurement_fields.dart';
import 'body_goal_repository.dart';

/// Writes body-goal targets to the underlying repository.
class BodyGoalEditor {
  /// Creates an editor backed by [repository].
  BodyGoalEditor({required this.repository});

  /// The goal repository.
  final BodyGoalRepository repository;

  /// The stored goal for [field], or null.
  BodyGoal? forField(BodyField field) => repository.forField(field);

  /// Sets (or updates) the target for [field].
  Future<void> set({
    required BodyField field,
    required double target,
    DateTime? createdAt,
  }) async {
    final existing = repository.forField(field);
    final stamp = createdAt ?? DateTime.now();
    if (existing != null) {
      await repository.save(existing.copyWith(target: target, createdAt: stamp));
    } else {
      await repository.save(
        BodyGoal(field: field, target: target, createdAt: stamp),
      );
    }
  }

  /// Removes the goal for [field], if any.
  Future<void> remove(BodyField field) async {
    final existing = repository.forField(field);
    if (existing != null) {
      await repository.delete(existing.id);
    }
  }
}
