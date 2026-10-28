// Workout repository for the Forge application.
//
// Persistence and queries for [Workout] plans.
library;

import '../../core/utils/dates.dart';
import '../../models/workout.dart';
import 'base_repository.dart';

/// Query surface for [Workout] plans.
abstract class WorkoutRepository extends BaseRepository<Workout> {
  /// Creates a repository backed by [box].
  WorkoutRepository(super.box);

  /// All workouts scheduled for [date] (day precision).
  List<Workout> onDate(DateTime date) => all()
      .where((workout) => isSameDay(workout.date, date))
      .toList();

  /// All workouts within the inclusive day range [from]..[to].
  List<Workout> between(DateTime from, DateTime to) => all()
      .where((workout) => isBetweenInclusive(workout.date, from, to))
      .toList();

  /// The [limit] most recently scheduled workouts, newest first.
  List<Workout> recent(int limit) {
    final sorted = [...all()]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }
}

/// Hive-backed [WorkoutRepository].
class HiveWorkoutRepository extends WorkoutRepository {
  /// Creates a repository backed by [box].
  HiveWorkoutRepository(super.box);
}
