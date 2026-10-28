// Calendar domain models for the Forge application.
//
// Read-only views assembled by the calendar providers from the underlying
// repositories. Widgets never touch Hive boxes or repositories directly;
// they consume these models so the grid can render a whole month from a
// single in-memory snapshot.
library;

import '../../../models/body_measurement.dart';
import '../../../models/workout_session.dart';

/// Maximum length of the daily notes field.
const int maxNotesLength = 500;

/// The editable body-measurement fields on the day-detail sheet.
enum MeasurementField {
  /// Waist circumference.
  waist,

  /// Neck circumference.
  neck,

  /// Chest circumference.
  chest,

  /// Shoulder circumference.
  shoulders,

  /// Left upper arm.
  leftArm,

  /// Right upper arm.
  rightArm,

  /// Left forearm.
  leftForearm,

  /// Right forearm.
  rightForearm,

  /// Left thigh.
  leftThigh,

  /// Right thigh.
  rightThigh,

  /// Left calf.
  leftCalf,

  /// Right calf.
  rightCalf,

  /// Body-fat percentage.
  bodyFat,
}

/// A personal record achieved on a calendar day.
class CalendarPrEntry {
  /// Creates a personal-record entry.
  const CalendarPrEntry({
    required this.exerciseId,
    required this.exerciseName,
    required this.highestWeight,
    required this.bestReps,
    required this.estimatedOneRM,
    required this.bestVolume,
  });

  /// The exercise these records belong to.
  final String exerciseId;

  /// The exercise display name.
  final String exerciseName;

  /// Heaviest single working weight.
  final double highestWeight;

  /// Most reps in a single set.
  final int bestReps;

  /// Highest estimated one-rep max.
  final double estimatedOneRM;

  /// Highest total session volume.
  final double bestVolume;
}

/// Marker categories rendered as small badges on calendar day cells.
enum CalendarDayMarker {
  /// A workout was completed that day.
  workout,

  /// A personal record was achieved that day.
  pr,

  /// The day belongs to the current training streak.
  streak,

  /// The active split schedules a training session that day.
  scheduled,

  /// The active split marks this day as rest.
  rest,

  /// A daily weigh-in was recorded.
  weight,

  /// Body measurements were logged.
  measurement,

  /// Sleep hours were logged.
  sleep,

  /// Water intake was logged.
  water,

  /// A mood rating was recorded.
  mood,

  /// Progress photos were captured.
  photo,

  /// Free-form notes were added.
  notes,
}

/// Read-only view of everything stored for one calendar day.
class CalendarDayView {
  /// Creates a day view.
  const CalendarDayView({
    required this.date,
    this.weight,
    this.workoutCompleted = false,
    this.sleepHours,
    this.waterLitres,
    this.mood,
    this.notes = '',
    this.durationMinutes = 0,
    this.photos = const [],
    this.photoThumbs = const [],
    this.sessions = const [],
    this.measurement,
    this.scheduledTraining = false,
    this.scheduledRest = false,
    this.hasPr = false,
    this.isStreak = false,
  });

  /// The calendar date (day precision).
  final DateTime date;

  /// The day's weigh-in, if any.
  final double? weight;

  /// Whether a workout was marked complete that day.
  final bool workoutCompleted;

  /// Hours slept, if logged.
  final double? sleepHours;

  /// Litres of water consumed, if logged.
  final double? waterLitres;

  /// Subjective mood rating (1-5), if logged.
  final int? mood;

  /// Free-form daily notes.
  final String notes;

  /// Minutes trained that day.
  final int durationMinutes;

  /// Local file paths of the day's progress photos.
  final List<String> photos;

  /// Local file paths of the small thumbnails for [photos].
  final List<String> photoThumbs;

  /// Number of progress photos for the day.
  int get photoCount => photos.length;

  /// Performed workout sessions started that day.
  final List<WorkoutSession> sessions;

  /// The day's body measurements, if any.
  final BodyMeasurement? measurement;

  /// Whether the active split schedules a training session this day.
  final bool scheduledTraining;

  /// Whether the active split marks this day as rest.
  final bool scheduledRest;

  /// Whether a personal record was achieved this day.
  final bool hasPr;

  /// Whether the day belongs to the current training streak.
  final bool isStreak;

  /// Whether any content is recorded for this day.
  bool get hasData =>
      weight != null ||
      workoutCompleted ||
      sleepHours != null ||
      waterLitres != null ||
      mood != null ||
      notes.isNotEmpty ||
      durationMinutes > 0 ||
      photoCount > 0 ||
      sessions.isNotEmpty ||
      measurement != null;

  /// Whether the day counts as "worked out".
  bool get workedOut =>
      workoutCompleted || sessions.any((session) => session.completed);

  /// The compact marker set shown on the calendar cell, in display order.
  List<CalendarDayMarker> get markers {
    final result = <CalendarDayMarker>[];
    if (workedOut) result.add(CalendarDayMarker.workout);
    if (hasPr) result.add(CalendarDayMarker.pr);
    if (isStreak) result.add(CalendarDayMarker.streak);
    if (scheduledTraining && !workedOut) {
      result.add(CalendarDayMarker.scheduled);
    }
    if (scheduledRest && !workedOut && !scheduledTraining) {
      result.add(CalendarDayMarker.rest);
    }
    if (weight != null) result.add(CalendarDayMarker.weight);
    if (measurement != null) result.add(CalendarDayMarker.measurement);
    if (sleepHours != null) result.add(CalendarDayMarker.sleep);
    if (waterLitres != null) result.add(CalendarDayMarker.water);
    if (mood != null) result.add(CalendarDayMarker.mood);
    if (photoCount > 0) result.add(CalendarDayMarker.photo);
    if (notes.isNotEmpty) result.add(CalendarDayMarker.notes);
    return result;
  }
}

/// The inclusive day range covered by the visible calendar grid.
class CalendarRange {
  /// Creates a range.
  const CalendarRange({required this.from, required this.to});

  /// First visible day.
  final DateTime from;

  /// Last visible day.
  final DateTime to;

  /// Number of days in the range (inclusive).
  int get dayCount => to.difference(from).inDays + 1;

  /// Whether [day] falls inside the range.
  bool contains(DateTime day) =>
      !day.isBefore(from) && !day.isAfter(to);
}

/// The full snapshot the calendar grid reads from.
///
/// Built once per data change by the providers; cells look days up by
/// normalized calendar-day key.
class CalendarReadModel {
  /// Creates a read model.
  const CalendarReadModel({required this.days});

  /// Views keyed by normalized calendar day.
  final Map<DateTime, CalendarDayView> days;

  /// The view for [day], or null when nothing was recorded.
  CalendarDayView? viewFor(DateTime day) =>
      days[DateTime(day.year, day.month, day.day)];
}
