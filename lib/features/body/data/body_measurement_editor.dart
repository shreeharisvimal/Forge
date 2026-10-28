// Body measurement persistence for the Forge application.
//
// Upserts whole body-measurement records for a calendar day through the
// [MeasurementRepository]. When a day already has a record (e.g. created
// from the calendar sheet) the stored id is kept so the row is updated, never
// duplicated. Fully empty records are pruned so the box holds no blank rows.
library;

import '../../../core/utils/dates.dart';
import '../../../models/body_measurement.dart';
import '../../../services/repositories/measurement_repository.dart';

/// Writes body-measurement records to the underlying repository.
class BodyMeasurementEditor {
  /// Creates an editor backed by [measurements].
  BodyMeasurementEditor({required this.measurements});

  /// The body-measurement repository.
  final MeasurementRepository measurements;

  /// The stored record for [date], or null.
  BodyMeasurement? onDate(DateTime date) => measurements.onDate(date);

  /// Upserts [measurement] for its date, preserving the stored record's id
  /// and pruning the row when it becomes fully empty.
  Future<void> save(BodyMeasurement measurement) async {
    final existing = measurements.onDate(measurement.date);
    if (existing == null) {
      if (measurement.isEmpty) return;
      await measurements.save(measurement);
      return;
    }
    final updated = measurement.copyWith(id: existing.id);
    if (updated.isEmpty) {
      await measurements.delete(existing.id);
    } else {
      await measurements.save(updated);
    }
  }

  /// Deletes the stored record for [date], if any.
  Future<void> delete(DateTime date) async {
    final existing = measurements.onDate(dateOnly(date));
    if (existing != null) {
      await measurements.delete(existing.id);
    }
  }
}
