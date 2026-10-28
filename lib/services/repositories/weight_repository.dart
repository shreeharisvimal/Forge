// Weight repository for the Forge application.
//
// Persistence and queries for [WeightEntry] daily weigh-ins.
library;

import '../../core/utils/dates.dart';
import '../../models/weight_entry.dart';
import 'base_repository.dart';

/// Query surface for [WeightEntry] weigh-ins.
abstract class WeightRepository extends BaseRepository<WeightEntry> {
  /// Creates a repository backed by [box].
  WeightRepository(super.box);

  /// The entry for [date] (day precision), or null.
  WeightEntry? onDate(DateTime date) {
    for (final entry in all()) {
      if (isSameDay(entry.date, date)) return entry;
    }
    return null;
  }

  /// All entries within the inclusive day range [from]..[to], oldest first.
  List<WeightEntry> between(DateTime from, DateTime to) {
    final result = all()
        .where((entry) => isBetweenInclusive(entry.date, from, to))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// The most recent weigh-in, or null if none.
  WeightEntry? latest() {
    var newest = null as WeightEntry?;
    for (final entry in all()) {
      if (newest == null || entry.date.isAfter(newest.date)) newest = entry;
    }
    return newest;
  }
}

/// Hive-backed [WeightRepository].
class HiveWeightRepository extends WeightRepository {
  /// Creates a repository backed by [box].
  HiveWeightRepository(super.box);
}
