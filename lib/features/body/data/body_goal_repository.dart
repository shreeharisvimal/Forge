// Body goal repository for the Forge application.
//
// Persistence and queries for [BodyGoal] records.
library;

import '../../../services/repositories/base_repository.dart';
import '../domain/body_goals.dart';
import '../domain/body_measurement_fields.dart';

/// Query surface for [BodyGoal] records.
abstract class BodyGoalRepository extends BaseRepository<BodyGoal> {
  /// Creates a repository backed by [box].
  BodyGoalRepository(super.box);

  /// The goal for [field], or null when none is set.
  BodyGoal? forField(BodyField field) {
    for (final goal in all()) {
      if (goal.field == field) return goal;
    }
    return null;
  }

  /// All goals sorted by creation time, oldest first.
  List<BodyGoal> allByDate() {
    final result = all()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }
}

/// Hive-backed [BodyGoalRepository].
class HiveBodyGoalRepository extends BodyGoalRepository {
  /// Creates a repository backed by [box].
  HiveBodyGoalRepository(super.box);
}
