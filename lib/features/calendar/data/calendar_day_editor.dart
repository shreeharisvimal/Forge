// Calendar day persistence for the Forge application.
//
// Writes day-detail edits back to storage. Every mutation is an upsert that
// keeps the calendar box, weight box and measurement box consistent, and
// prunes rows that become fully empty so the grid never shows stale badges.
library;

import '../../../core/utils/dates.dart';
import '../../../models/body_measurement.dart';
import '../../../models/calendar_day.dart';
import '../../../models/weight_entry.dart';
import '../../../services/repositories/calendar_repository.dart';
import '../../../services/repositories/measurement_repository.dart';
import '../../../services/repositories/weight_repository.dart';
import '../domain/calendar_models.dart';

/// Writes day-detail edits to the underlying repositories.
class CalendarDayEditor {
  /// Creates an editor backed by the given repositories.
  CalendarDayEditor({
    required this.calendar,
    required this.weights,
    required this.measurements,
  });

  /// Calendar-day rows.
  final CalendarRepository calendar;

  /// Daily weigh-ins.
  final WeightRepository weights;

  /// Body measurements.
  final MeasurementRepository measurements;

  /// The stored row for [date], or null.
  CalendarDay? rowOn(DateTime date) => calendar.onDate(date);

  /// The weigh-in entry for [date], or null.
  WeightEntry? weightOn(DateTime date) => weights.onDate(date);

  /// The measurement record for [date], or null.
  BodyMeasurement? measurementOn(DateTime date) => measurements.onDate(date);

  /// Sets (or, when [value] is null, clears) the day's weigh-in.
  ///
  /// The value is written to both the calendar row (for grid markers) and a
  /// [WeightEntry] (for the weight history the dashboard charts).
  Future<void> setWeight(DateTime date, double? value) async {
    final day = dateOnly(date);
    final row = rowOn(day);
    final entry = weightOn(day);

    if (value == null) {
      if (row != null && row.weight != null) {
        await calendar.save(row.copyWith(weight: () => null));
      }
      if (entry != null) {
        await weights.delete(entry.id);
      }
      await _pruneRow(day);
      return;
    }

    if (row != null) {
      await calendar.save(row.copyWith(weight: () => value));
    } else {
      await calendar.save(CalendarDay(date: day, weight: value));
    }
    if (entry != null) {
      await weights.save(entry.copyWith(weight: value));
    } else {
      await weights.save(WeightEntry(date: day, weight: value));
    }
  }

  /// Saves the lifestyle fields for [date] in one row.
  Future<void> setDaily({
    required DateTime date,
    double? Function()? sleepHours,
    double? Function()? waterLitres,
    int? Function()? mood,
    String? notes,
    int? durationMinutes,
    bool? workoutCompleted,
  }) async {
    final day = dateOnly(date);
    final row = rowOn(day) ?? CalendarDay(date: day);
    final updated = row.copyWith(
      sleepHours: sleepHours,
      waterLitres: waterLitres,
      mood: mood,
      notes: notes,
      durationMinutes: durationMinutes,
      workoutCompleted: workoutCompleted,
    );
    await calendar.save(updated);
    await _pruneRow(day);
  }

  /// Merges the editable measurement fields for [date].
  ///
  /// Only the fields present in [fields] are written; absent fields keep their
  /// stored value, so callers may save a full form or a single field.
  Future<void> setMeasurement({
    required DateTime date,
    Map<MeasurementField, double?> fields = const {},
  }) async {
    final day = dateOnly(date);
    final existing = measurementOn(day);
    final base = existing ?? BodyMeasurement(date: day);
    double? merged(MeasurementField field, double? stored) =>
        fields.containsKey(field) ? fields[field] : stored;
    final updated = BodyMeasurement(
      id: base.id,
      date: day,
      weight: base.weight,
      waist: merged(MeasurementField.waist, base.waist),
      neck: merged(MeasurementField.neck, base.neck),
      chest: merged(MeasurementField.chest, base.chest),
      shoulders: merged(MeasurementField.shoulders, base.shoulders),
      leftArm: merged(MeasurementField.leftArm, base.leftArm),
      rightArm: merged(MeasurementField.rightArm, base.rightArm),
      leftForearm: merged(MeasurementField.leftForearm, base.leftForearm),
      rightForearm: merged(MeasurementField.rightForearm, base.rightForearm),
      leftThigh: merged(MeasurementField.leftThigh, base.leftThigh),
      rightThigh: merged(MeasurementField.rightThigh, base.rightThigh),
      leftCalf: merged(MeasurementField.leftCalf, base.leftCalf),
      rightCalf: merged(MeasurementField.rightCalf, base.rightCalf),
      bodyFat: merged(MeasurementField.bodyFat, base.bodyFat),
      hip: base.hip,
      notes: base.notes,
      photos: base.photos,
      photoThumbs: base.photoThumbs,
    );
    if (updated.isEmpty) {
      if (existing != null) {
        await measurements.delete(existing.id);
      }
    } else {
      await measurements.save(updated);
    }
  }

  /// Stores the progress-photo paths for [date].
  Future<void> setPhotos(
    DateTime date,
    List<String> photos,
    List<String> photoThumbs,
  ) async {
    final day = dateOnly(date);
    final row = rowOn(day) ?? CalendarDay(date: day);
    await calendar.save(
      row.copyWith(photos: photos, photoThumbs: photoThumbs),
    );
    await _pruneRow(day);
  }

  /// Deletes the row for [date] once no content remains.
  Future<void> _pruneRow(DateTime day) async {
    final row = rowOn(day);
    if (row == null) return;
    final isEmpty = row.weight == null &&
        !row.workoutCompleted &&
        row.sleepHours == null &&
        row.waterLitres == null &&
        row.mood == null &&
        row.notes.isEmpty &&
        row.durationMinutes == 0 &&
        row.photos.isEmpty;
    if (isEmpty) await calendar.delete(row.id);
  }
}
