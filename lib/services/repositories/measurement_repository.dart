// Measurement repository for the Forge application.
//
// Persistence and queries for [BodyMeasurement] records.
library;

import '../../core/utils/dates.dart';
import '../../models/body_measurement.dart';
import 'base_repository.dart';

/// Query surface for [BodyMeasurement] records.
abstract class MeasurementRepository extends BaseRepository<BodyMeasurement> {
  /// Creates a repository backed by [box].
  MeasurementRepository(super.box);

  /// The measurement for [date] (day precision), or null.
  BodyMeasurement? onDate(DateTime date) {
    for (final measurement in all()) {
      if (isSameDay(measurement.date, date)) return measurement;
    }
    return null;
  }

  /// All measurements within the inclusive day range [from]..[to], oldest first.
  List<BodyMeasurement> between(DateTime from, DateTime to) {
    final result = all()
        .where((measurement) => isBetweenInclusive(measurement.date, from, to))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// The most recent measurement, or null if none.
  BodyMeasurement? latest() {
    var newest = null as BodyMeasurement?;
    for (final measurement in all()) {
      if (newest == null || measurement.date.isAfter(newest.date)) {
        newest = measurement;
      }
    }
    return newest;
  }
}

/// Hive-backed [MeasurementRepository].
class HiveMeasurementRepository extends MeasurementRepository {
  /// Creates a repository backed by [box].
  HiveMeasurementRepository(super.box);
}
