// Calendar providers for the Forge application.
//
// Composes the repositories into the read models the grid and the day-detail
// sheet render. Every provider watches the relevant box-change stream so the
// calendar stays live after any save, and reads a generous load window so
// week/two-week views never show blank cells at month boundaries.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;
import 'package:table_calendar/table_calendar.dart';

import '../../../core/services/file/file_service.dart';
import '../../../core/services/images/image_service.dart';
import '../../../core/utils/dates.dart';
import '../../../models/body_measurement.dart';
import '../../../models/calendar_day.dart';
import '../../../models/weight_entry.dart';
import '../../../models/workout_session.dart';
import '../../../services/providers.dart';
import '../../dashboard/domain/dashboard_calculations.dart';
import '../data/calendar_box_watchers.dart';
import '../data/calendar_day_editor.dart';
import '../data/calendar_photo_service.dart';
import '../domain/calendar_models.dart';
import '../domain/calendar_queries.dart';

/// The calendar's notion of "now". Overridden in tests to pin a date.
final calendarNowProvider = Provider<DateTime>((_) => DateTime.now());

/// The month currently in view.
final calendarFocusedDayProvider = legacy.StateProvider<DateTime>(
  (ref) => dateOnly(ref.watch(calendarNowProvider)),
);

/// The selected day, opened by the day-detail sheet.
final calendarSelectedDayProvider = legacy.StateProvider<DateTime>(
  (ref) => dateOnly(ref.watch(calendarNowProvider)),
);

/// The active grid format.
final calendarFormatProvider = legacy.StateProvider<CalendarFormat>(
  (_) => CalendarFormat.month,
);

/// Writes day-detail edits back to storage.
final calendarDayEditorProvider = Provider<CalendarDayEditor>((ref) {
  return CalendarDayEditor(
    calendar: ref.watch(calendarRepositoryProvider),
    weights: ref.watch(weightRepositoryProvider),
    measurements: ref.watch(measurementRepositoryProvider),
  );
});

/// Picks and stores progress photos for a day.
///
/// Override in tests with a fake; the device-backed implementation resolves
/// the documents directory lazily and needs path_provider.
final calendarPhotoServiceProvider = Provider<CalendarPhotoService>((ref) {
  return DeviceCalendarPhotoService(
    imageService: ref.watch(imageServiceProvider),
    fileService: FileService(),
  );
});

/// The whole visible-grid dataset keyed by calendar day.
final calendarReadModelProvider = Provider<CalendarReadModel>((ref) {
  ref.watch(calendarBoxChangesProvider);
  ref.watch(calendarWeightBoxChangesProvider);
  ref.watch(calendarSessionBoxChangesProvider);
  ref.watch(calendarMeasurementBoxChangesProvider);
  ref.watch(calendarPrEventsBoxChangesProvider);
  ref.watch(calendarSplitBoxChangesProvider);

  final calendarRepo = ref.watch(calendarRepositoryProvider);
  final weightRepo = ref.watch(weightRepositoryProvider);
  final measurementRepo = ref.watch(measurementRepositoryProvider);
  final sessionRepo = ref.watch(workoutSessionRepositoryProvider);

  final window = loadWindow(ref.watch(calendarFocusedDayProvider));

  final allSessions = sessionRepo.all();
  final rows = calendarRepo.between(window.from, window.to);
  final weights = weightRepo.between(window.from, window.to);
  final measurements = measurementRepo.between(window.from, window.to);
  final sessions = [
    for (final session in allSessions)
      if (window.contains(session.date)) session
  ];

  final rowByDay = <DateTime, CalendarDay>{
    for (final row in rows) dateOnly(row.date): row,
  };
  final weightByDay = <DateTime, WeightEntry>{
    for (final entry in weights) dateOnly(entry.date): entry,
  };
  final measurementByDay = <DateTime, BodyMeasurement>{
    for (final entry in measurements) dateOnly(entry.date): entry,
  };
  final sessionsByDay = <DateTime, List<WorkoutSession>>{};
  for (final session in sessions) {
    sessionsByDay.putIfAbsent(dateOnly(session.date), () => []).add(session);
  }

  final schedule = _activeSchedule(ref);
  final prDays = _prDaysFor(ref);
  final streak = DashboardCalculations.streakDays(
    DashboardCalculations.completedSessions(allSessions),
    now: ref.watch(calendarNowProvider),
  );

  final views = <DateTime, CalendarDayView>{};
  for (var day = window.from; !day.isAfter(window.to); day = day.add(const Duration(days: 1))) {
    final key = dateOnly(day);
    final snapshot = schedule?.snapshotFor(key);
    views[key] = buildDayView(
      day: key,
      row: rowByDay[key],
      weight: weightByDay[key],
      measurement: measurementByDay[key],
      sessions: sessionsByDay[key] ?? const [],
      scheduledTraining: snapshot?.day.isRestDay == false,
      scheduledRest: snapshot?.day.isRestDay ?? false,
      hasPr: prDays.contains(key),
      isStreak: streak.contains(key),
    );
  }

  return CalendarReadModel(days: views);
});

/// The day view for [day], fetched fresh so the detail sheet stays correct
/// even when the grid has since moved to another month.
final calendarDayViewProvider = Provider.family<CalendarDayView, DateTime>(
  (ref, day) {
    ref.watch(calendarBoxChangesProvider);
    ref.watch(calendarWeightBoxChangesProvider);
    ref.watch(calendarSessionBoxChangesProvider);
    ref.watch(calendarMeasurementBoxChangesProvider);
    ref.watch(calendarPrEventsBoxChangesProvider);
    ref.watch(calendarSplitBoxChangesProvider);

    final key = dateOnly(day);
    final snapshot = _activeSchedule(ref)?.snapshotFor(key);
    final allSessions = ref.watch(workoutSessionRepositoryProvider).all();
    final streak = DashboardCalculations.streakDays(
      DashboardCalculations.completedSessions(allSessions),
      now: ref.watch(calendarNowProvider),
    );
    return buildDayView(
      day: key,
      row: ref.watch(calendarRepositoryProvider).onDate(key),
      weight: ref.watch(weightRepositoryProvider).onDate(key),
      measurement: ref.watch(measurementRepositoryProvider).onDate(key),
      sessions: ref.watch(workoutSessionRepositoryProvider).onDate(key),
      scheduledTraining: snapshot?.day.isRestDay == false,
      scheduledRest: snapshot?.day.isRestDay ?? false,
      hasPr: _prDaysFor(ref).contains(key),
      isStreak: streak.contains(key),
    );
  },
);

/// The personal records tied to the exercises logged on [day].
///
/// Display-only: each distinct exercised muscle a session references and that
/// has a stored record row surfaces as a [CalendarPrEntry], so the day-detail
/// sheet can celebrate the lifetime bests that exercise contributed to.
final calendarPrsForDayProvider =
    Provider.family<List<CalendarPrEntry>, DateTime>((ref, day) {
  ref.watch(calendarPrBoxChangesProvider);
  ref.watch(calendarSessionBoxChangesProvider);

  final key = dateOnly(day);
  final entries = <CalendarPrEntry>[];
  final seen = <String>{};
  final records = ref.watch(personalRecordRepositoryProvider);
  for (final session in ref.watch(workoutSessionRepositoryProvider).onDate(key)) {
    for (final exercise in session.exercises) {
      if (!seen.add(exercise.exerciseId)) continue;
      final record = records.forExercise(exercise.exerciseId);
      if (record == null) continue;
      entries.add(
        CalendarPrEntry(
          exerciseId: exercise.exerciseId,
          exerciseName: exercise.exerciseName,
          highestWeight: record.highestWeight,
          bestReps: record.bestReps,
          estimatedOneRM: record.estimatedOneRM,
          bestVolume: record.bestVolume,
        ),
      );
    }
  }
  entries.sort((a, b) => a.exerciseName.compareTo(b.exerciseName));
  return entries;
});

/// The most recent weigh-in strictly before [day], for trend display.
final calendarPreviousWeightProvider = Provider.family<double?, DateTime>(
  (ref, day) {
    ref.watch(calendarWeightBoxChangesProvider);
    final before = dateOnly(day).subtract(const Duration(days: 1));
    final entries = ref.watch(weightRepositoryProvider).between(
          before.subtract(const Duration(days: 365)),
          before,
        );
    if (entries.isEmpty) return null;
    return entries.last.weight;
  },
);

/// Every day that has any recorded content, newest first. Feeds the date
/// search sheet.
final calendarLoggedDaysProvider = Provider<List<DateTime>>((ref) {
  ref.watch(calendarBoxChangesProvider);
  ref.watch(calendarWeightBoxChangesProvider);
  ref.watch(calendarSessionBoxChangesProvider);
  ref.watch(calendarMeasurementBoxChangesProvider);

  final dates = <DateTime>{};
  for (final row in ref.watch(calendarRepositoryProvider).all()) {
    dates.add(dateOnly(row.date));
  }
  for (final entry in ref.watch(weightRepositoryProvider).all()) {
    dates.add(dateOnly(entry.date));
  }
  for (final entry in ref.watch(measurementRepositoryProvider).all()) {
    dates.add(dateOnly(entry.date));
  }
  for (final session in ref.watch(workoutSessionRepositoryProvider).all()) {
    dates.add(dateOnly(session.date));
  }
  final list = dates.toList()..sort((a, b) => b.compareTo(a));
  return list;
});

/// The weekly schedule of the active split, or null when none is set.
WeeklySplitSchedule? _activeSchedule(Ref ref) {
  final split = ref.watch(workoutSplitRepositoryProvider).activeSplit;
  if (split == null || split.days.isEmpty) return null;
  return WeeklySplitSchedule(
    split: split,
    days: split.days,
    createdAt: split.createdAt,
  );
}

/// The set of days that have at least one recorded [PrEvent].
Set<DateTime> _prDaysFor(Ref ref) => {
      for (final event in ref.watch(prEventRepositoryProvider).all())
        dateOnly(event.date),
    };
