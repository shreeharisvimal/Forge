// PersonalRecord repository for the Forge application.
//
// Persistence and queries for [PersonalRecord] bests.
library;

import '../../models/personal_record.dart';
import 'base_repository.dart';

/// Query surface for [PersonalRecord] bests.
abstract class PersonalRecordRepository extends BaseRepository<PersonalRecord> {
  /// Creates a repository backed by [box].
  PersonalRecordRepository(super.box);

  /// The record row for [exerciseId], or null.
  PersonalRecord? forExercise(String exerciseId) {
    for (final record in all()) {
      if (record.exerciseId == exerciseId) return record;
    }
    return null;
  }
}

/// Hive-backed [PersonalRecordRepository].
class HivePersonalRecordRepository extends PersonalRecordRepository {
  /// Creates a repository backed by [box].
  HivePersonalRecordRepository(super.box);
}
