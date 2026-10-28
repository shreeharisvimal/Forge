// WorkoutSession repository for the Forge application.
//
// Persistence and queries for performed [WorkoutSession] records.
library;

import '../../core/utils/dates.dart';
import '../../models/workout_session.dart';
import 'base_repository.dart';

/// Query surface for performed [WorkoutSession] records.
abstract class WorkoutSessionRepository extends BaseRepository<WorkoutSession> {
  /// Creates a repository backed by [box].
  WorkoutSessionRepository(super.box);

  /// All sessions performed on [date] (day precision).
  List<WorkoutSession> onDate(DateTime date) => all()
      .where((session) => isSameDay(session.date, date))
      .toList();

  /// All sessions within the inclusive day range [from]..[to].
  List<WorkoutSession> between(DateTime from, DateTime to) => all()
      .where((session) => isBetweenInclusive(session.date, from, to))
      .toList();

  /// All sessions that originated from the [Workout] with [workoutId].
  List<WorkoutSession> forWorkout(String workoutId) => all()
      .where((session) => session.workoutId == workoutId)
      .toList();

  /// The [limit] most recently performed sessions, newest first.
  List<WorkoutSession> recent(int limit) {
    final sorted = [...all()]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }
}

/// Hive-backed [WorkoutSessionRepository].
class HiveWorkoutSessionRepository extends WorkoutSessionRepository {
  /// Creates a repository backed by [box].
  HiveWorkoutSessionRepository(super.box);
}
