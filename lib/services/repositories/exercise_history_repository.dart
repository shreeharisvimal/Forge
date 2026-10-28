// ExerciseHistory repository for the Forge application.
//
// Persistence and queries for [ExerciseHistory] daily aggregates.
library;

import '../../core/utils/dates.dart';
import '../../models/exercise_history.dart';
import 'base_repository.dart';

/// Query surface for [ExerciseHistory] aggregates.
abstract class ExerciseHistoryRepository extends BaseRepository<ExerciseHistory> {
  /// Creates a repository backed by [box].
  ExerciseHistoryRepository(super.box);

  /// All history rows for [exerciseId], oldest first.
  List<ExerciseHistory> forExercise(String exerciseId) {
    final result = all()
        .where((row) => row.exerciseId == exerciseId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// The history row for [exerciseId] on [date], or null.
  ExerciseHistory? onDate(String exerciseId, DateTime date) {
    for (final row in all()) {
      if (row.exerciseId == exerciseId && isSameDay(row.date, date)) {
        return row;
      }
    }
    return null;
  }

  /// All history rows within the inclusive day range [from]..[to], oldest first.
  List<ExerciseHistory> between(DateTime from, DateTime to) {
    final result = all()
        .where((row) => isBetweenInclusive(row.date, from, to))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }
}

/// Hive-backed [ExerciseHistoryRepository].
class HiveExerciseHistoryRepository extends ExerciseHistoryRepository {
  /// Creates a repository backed by [box].
  HiveExerciseHistoryRepository(super.box);
}
