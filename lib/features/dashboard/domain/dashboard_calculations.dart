// Pure calculations for the Forge dashboard.
//
// Weekly aggregates, streaks, split-day scheduling and PR baselines, all
// free of Flutter and Riverpod dependencies so they are trivially testable.
library;

import '../../../core/utils/dates.dart';
import '../../../models/exercise_history.dart';
import '../../../models/workout_session.dart';
import '../../../models/workout_split.dart';
import '../../../models/workout_split_day.dart';
import 'dashboard_models.dart';

/// Pure dashboard math used by the providers.
abstract final class DashboardCalculations {
  DashboardCalculations._();

  /// The Monday of the week containing [day].
  static DateTime mondayOf(DateTime day) {
    final date = dateOnly(day);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Index into a split's day list for [date].
  ///
  /// The weekly plan is anchored to the Monday on or before the split was
  /// created, so the same weekday always maps to the same training day.
  static int dayIndex({
    required DateTime date,
    required DateTime splitCreatedAt,
    required int dayCount,
  }) {
    if (dayCount <= 0) return 0;
    final anchor = mondayOf(splitCreatedAt);
    final diff = dateOnly(date).difference(anchor).inDays;
    return diff % dayCount;
  }

  /// The next non-rest day after [from], or null when the plan is all rest.
  static SplitDaySnapshot? nextTrainingDay({
    required List<WorkoutSplitDay> days,
    required DateTime splitCreatedAt,
    required DateTime from,
  }) {
    if (days.isEmpty) return null;
    final start = dayIndex(
      date: from,
      splitCreatedAt: splitCreatedAt,
      dayCount: days.length,
    );
    for (var step = 1; step <= days.length; step++) {
      final index = (start + step) % days.length;
      final day = days[index];
      if (!day.isRestDay) {
        return SplitDaySnapshot(
          date: from.add(Duration(days: step)),
          day: day,
          isToday: false,
        );
      }
    }
    return null;
  }

  /// Sessions that contain at least one completed set.
  static List<WorkoutSession> completedSessions(List<WorkoutSession> sessions) {
    return sessions
        .where((session) => session.exercises.any(
              (performed) => performed.sets.any((set) => set.completed),
            ))
        .toList();
  }

  /// Aggregates the week (Monday..[now]) across [sessions].
  static WeeklySummaryData weeklySummary({
    required List<WorkoutSession> sessions,
    required DateTime now,
  }) {
    final completed = completedSessions(sessions);
    final monday = mondayOf(now);

    var workouts = 0;
    var sets = 0;
    var reps = 0;
    var volume = 0.0;
    var minutes = 0;

    for (final session in completed) {
      if (session.date.isBefore(monday)) continue;
      workouts += 1;
      minutes += session.durationMinutes;
      for (final performed in session.exercises) {
        for (final set in performed.sets) {
          if (!set.completed) continue;
          sets += 1;
          reps += set.reps;
          volume += set.weight * set.reps;
        }
      }
    }

    return WeeklySummaryData(
      streak: streakDays(completed, now: now).length,
      workouts: workouts,
      sets: sets,
      reps: reps,
      volume: volume,
      minutes: minutes,
    );
  }

  /// The days that make up the current training streak.
  ///
  /// Consecutive days with at least one completed session, ending today or
  /// yesterday when today is still empty (the streak only breaks overnight).
  static Set<DateTime> streakDays(
    List<WorkoutSession> completed, {
    required DateTime now,
  }) {
    final days = <DateTime>{};
    var day = dateOnly(now);
    if (!_hasSessionOn(completed, day)) {
      day = day.subtract(const Duration(days: 1));
    }
    while (_hasSessionOn(completed, day)) {
      days.add(day);
      day = day.subtract(const Duration(days: 1));
    }
    return days;
  }

  static bool _hasSessionOn(List<WorkoutSession> sessions, DateTime day) {
    for (final session in sessions) {
      if (isSameDay(session.date, day)) return true;
    }
    return false;
  }

  /// Best estimated one-rep max recorded strictly before [before], or null.
  static double? previousBest({
    required List<ExerciseHistory> history,
    required DateTime before,
  }) {
    double? best;
    final cutoff = dateOnly(before);
    for (final row in history) {
      if (dateOnly(row.date).isBefore(cutoff)) {
        if (best == null || row.estimatedOneRM > best) {
          best = row.estimatedOneRM;
        }
      }
    }
    return best;
  }

  /// The weekday label for a 0-based index (0 = Monday).
  static String weekdayLabel(int weekday) {
    const labels = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return labels[weekday.clamp(0, 6)];
  }
}

/// A resolved weekly split schedule for a given date.
class WeeklySplitSchedule {
  /// Creates a schedule.
  WeeklySplitSchedule({
    required this.split,
    required this.days,
    required this.createdAt,
  });

  /// The active split.
  final WorkoutSplit split;

  /// The split's ordered days.
  final List<WorkoutSplitDay> days;

  /// The anchor used for the weekly cycle.
  final DateTime createdAt;

  /// The split day scheduled for [date].
  SplitDaySnapshot snapshotFor(DateTime date) {
    final index = DashboardCalculations.dayIndex(
      date: date,
      splitCreatedAt: createdAt,
      dayCount: days.length,
    );
    return SplitDaySnapshot(
      date: date,
      day: days[index],
      isToday: true,
    );
  }
}
