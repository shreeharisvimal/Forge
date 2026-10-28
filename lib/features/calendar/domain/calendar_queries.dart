// Calendar query helpers for the Forge application.
//
// Pure functions that derive the visible grid range and human-readable
// labels. No I/O and no Flutter dependencies live here, keeping them
// trivially unit-testable.
library;

import 'package:intl/intl.dart';

import '../../../core/utils/dates.dart';
import '../../../models/body_measurement.dart';
import '../../../models/calendar_day.dart';
import '../../../models/weight_entry.dart';
import '../../../models/workout_session.dart';
import 'calendar_models.dart';

/// The 6-week grid range surrounding the month of [focused], padded with
/// leading/trailing days from adjacent months so a month view never has
/// ragged rows.
CalendarRange visibleMonthRange(DateTime focused) {
  final first = DateTime(focused.year, focused.month, 1);
  final last = DateTime(focused.year, focused.month + 1, 0);
  final from = first.subtract(Duration(days: first.weekday - 1));
  final to = last.add(Duration(days: 7 - last.weekday));
  return CalendarRange(from: dateOnly(from), to: dateOnly(to));
}

/// The single-week grid range containing [focused].
CalendarRange visibleWeekRange(DateTime focused) {
  final start = dateOnly(focused).subtract(Duration(days: focused.weekday - 1));
  return CalendarRange(from: start, to: start.add(const Duration(days: 6)));
}

/// A generous load window that always covers the visible grid regardless of
/// the active format, so week/two-week views across month boundaries stay
/// populated.
CalendarRange loadWindow(DateTime focused) {
  final month = visibleMonthRange(focused);
  return CalendarRange(
    from: month.from.subtract(const Duration(days: 6)),
    to: month.to.add(const Duration(days: 6)),
  );
}

/// Formats the header title, e.g. "February 2026".
String formatMonthTitle(DateTime focused, {String locale = 'en_US'}) =>
    DateFormat('MMMM y', locale).format(focused);

/// Formats a day like "Mon, Feb 3".
String formatDayLabel(DateTime date, {String locale = 'en_US'}) =>
    DateFormat('EEE, MMM d', locale).format(date);

/// Formats a day like "Monday, February 3, 2026".
String formatFullDayLabel(DateTime date, {String locale = 'en_US'}) =>
    DateFormat('EEEE, MMMM d, y', locale).format(date);

/// Emoji for a 1-5 mood rating; null when unset.
String? moodEmoji(int? mood) => switch (mood) {
      null => null,
      1 => '😞',
      2 => '😴',
      3 => '😐',
      4 => '🙂',
      5 => '😀',
      _ => null,
    };

/// Short label for a 1-5 mood rating.
String moodLabel(int? mood) => switch (mood) {
      null => '—',
      1 => 'Bad',
      2 => 'Tired',
      3 => 'Okay',
      4 => 'Good',
      5 => 'Excellent',
      _ => '—',
    };

/// Whether [day] marks the strongest recorded weigh-in in [entries].
bool isAllTimeLow(DateTime day, List<WeightEntry> entries) {
  final matching = entries.where((entry) => isSameDay(entry.date, day)).toList();
  if (matching.isEmpty) return false;
  final minimum = entries
      .map((entry) => entry.weight)
      .reduce((a, b) => a < b ? a : b);
  return matching.any((entry) => entry.weight == minimum);
}

/// Human-readable summary of which measurements were logged.
String measurementSummary(BodyMeasurement? measurement) {
  if (measurement == null) return '';
  final parts = <String>[];
  if (measurement.weight != null) parts.add('Weight');
  if (measurement.waist != null) parts.add('Waist');
  if (measurement.chest != null) parts.add('Chest');
  if (measurement.shoulders != null) parts.add('Shoulders');
  if (measurement.leftArm != null) parts.add('Arms');
  if (measurement.leftThigh != null) parts.add('Thighs');
  if (measurement.leftCalf != null) parts.add('Calves');
  if (measurement.bodyFat != null) parts.add('Body fat');
  if (parts.isEmpty) return 'Measurements';
  return parts.join(' · ');
}

/// The stored value for a [MeasurementField], or null when not recorded.
double? measurementFieldValue(BodyMeasurement? measurement, MeasurementField field) =>
    switch (field) {
      MeasurementField.waist => measurement?.waist,
      MeasurementField.neck => measurement?.neck,
      MeasurementField.chest => measurement?.chest,
      MeasurementField.shoulders => measurement?.shoulders,
      MeasurementField.leftArm => measurement?.leftArm,
      MeasurementField.rightArm => measurement?.rightArm,
      MeasurementField.leftForearm => measurement?.leftForearm,
      MeasurementField.rightForearm => measurement?.rightForearm,
      MeasurementField.leftThigh => measurement?.leftThigh,
      MeasurementField.rightThigh => measurement?.rightThigh,
      MeasurementField.leftCalf => measurement?.leftCalf,
      MeasurementField.rightCalf => measurement?.rightCalf,
      MeasurementField.bodyFat => measurement?.bodyFat,
    };

/// Builds a [CalendarDayView] for [day] by merging every source of truth.
CalendarDayView buildDayView({
  required DateTime day,
  CalendarDay? row,
  WeightEntry? weight,
  BodyMeasurement? measurement,
  List<WorkoutSession> sessions = const [],
  bool scheduledTraining = false,
  bool scheduledRest = false,
  bool hasPr = false,
  bool isStreak = false,
}) {
  return CalendarDayView(
    date: day,
    weight: row?.weight ?? weight?.weight,
    workoutCompleted: row?.workoutCompleted ?? false,
    sleepHours: row?.sleepHours,
    waterLitres: row?.waterLitres,
    mood: row?.mood,
    notes: row?.notes ?? '',
    durationMinutes: row?.durationMinutes ?? 0,
    photos: row?.photos ?? const [],
    photoThumbs: row?.photoThumbs ?? const [],
    sessions: sessions,
    measurement: measurement,
    scheduledTraining: scheduledTraining,
    scheduledRest: scheduledRest,
    hasPr: hasPr,
    isStreak: isStreak,
  );
}

/// Merges a list of views into a keyed read model.
Map<DateTime, CalendarDayView> keyViewsByDay(Iterable<CalendarDayView> views) => {
      for (final view in views) dateOnly(view.date): view,
    };
