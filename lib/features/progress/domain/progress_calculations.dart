// Progress analytics calculations for the Forge application.
//
// Turns the raw repositories into the read models the Progress tab renders.
// A single pass over the session history computes every aggregate at once —
// overview totals and deltas, volume buckets, the frequency grid, weight
// trend, per-exercise analytics and estimated-1RM trajectories — so even
// histories with 100,000+ sets stay fast. Pure functions only, no Flutter
// or Riverpod imports.
library;

import '../../../core/utils/dates.dart';
import '../../../models/exercise.dart';
import '../../../models/personal_record.dart';
import '../../../models/weight_entry.dart';
import '../../../models/workout_session.dart';
import '../../prs/data/pr_event.dart';
import '../../prs/domain/one_rep_max.dart';
import 'analytics_models.dart';
import 'analytics_range.dart';

/// The bucket granularity of the volume chart.
enum _Period { day, week, month }

/// Computes every analytics read model for one [AnalyticsRange].
abstract final class ProgressCalculations {
  ProgressCalculations._();

  /// Builds an [AnalyticsSnapshot] for [range] as of [now].
  ///
  /// [sessions], [weightEntries], [prEvents] and [records] are read from the
  /// repositories; [exercisesById] decorates exercise analytics with names
  /// and muscle groups. [formula] drives the estimated-1RM math.
  static AnalyticsSnapshot compute({
    required List<WorkoutSession> sessions,
    required DateTime now,
    required AnalyticsRange range,
    required List<WeightEntry> weightEntries,
    required List<PrEvent> prEvents,
    required List<PersonalRecord> records,
    required Map<String, Exercise> exercisesById,
    OneRepMaxFormula formula = OneRepMaxFormula.epley,
  }) {
    final today = dateOnly(now);
    final from = _windowStart(sessions, weightEntries, range, today);

    final current = _Window();
    final previous = _Window();

    final currentFrom = from;
    final currentTo = today;
    DateTime? prevFrom;
    DateTime? prevTo;
    if (range != AnalyticsRange.lifetime && from != null) {
      prevTo = from.subtract(const Duration(days: 1));
      prevFrom = prevTo.subtract(Duration(days: range.daySpan - 1));
    }

    final period = _periodFor(range);
    final volumeByBucket = <DateTime, double>{};
    final setsByBucket = <DateTime, int>{};

    for (final session in sessions) {
      if (!_hasCompletedSets(session)) continue;
      final day = dateOnly(session.date);
      final inCurrent = currentFrom != null &&
          !day.isBefore(currentFrom) &&
          !day.isAfter(currentTo);
      final inPrevious = prevFrom != null &&
          prevTo != null &&
          !day.isBefore(prevFrom) &&
          !day.isAfter(prevTo);
      if (!inCurrent && !inPrevious) continue;

      if (inCurrent) {
        current.workouts += 1;
        current.minutes += session.durationMinutes;
        current.activeDays.add(day);
      }
      if (inPrevious) {
        previous.workouts += 1;
        previous.minutes += session.durationMinutes;
      }

      for (final performed in session.exercises) {
        for (final set in performed.sets) {
          if (!set.completed) continue;
          final tonnage = set.weight * set.reps;
          if (inPrevious) {
            previous.sets += 1;
            previous.reps += set.reps;
            previous.volume += tonnage;
            continue;
          }
          current.sets += 1;
          current.reps += set.reps;
          current.volume += tonnage;
          current.setsByDay[day] = (current.setsByDay[day] ?? 0) + 1;

          final bucket = _bucketStart(day, period);
          volumeByBucket[bucket] = (volumeByBucket[bucket] ?? 0) + tonnage;
          setsByBucket[bucket] = (setsByBucket[bucket] ?? 0) + 1;

          final aggregate = current.exercises[performed.exerciseId] ??
              (_ExerciseAgg()..exerciseName = performed.exerciseName);
          if (aggregate.sessionIds.add(session.id)) aggregate.sessions += 1;
          aggregate.sets += 1;
          aggregate.volume += tonnage;
          if (!set.isWarmup) {
            final estimate = OneRepMax.estimate(set.weight, set.reps,
                formula: formula);
            if (estimate > 0) {
              final existing = aggregate.oneRmByDay[day];
              if (existing == null || estimate > existing) {
                aggregate.oneRmByDay[day] = estimate;
              }
            }
          }
          current.exercises[performed.exerciseId] = aggregate;
        }
      }
    }

    final volumeBuckets = _buildBuckets(
      from: from ?? today,
      to: today,
      period: period,
      volumes: volumeByBucket,
      sets: setsByBucket,
    );

    final heatmap = _buildHeatmap(
      from: from ?? today,
      to: today,
      setsByDay: current.setsByDay,
    );

    final weight = _buildWeight(weightEntries, from, today);

    final inRangePrs = prEvents
        .where((event) =>
            from == null || !dateOnly(event.date).isBefore(from))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final prsByExercise = <String, int>{};
    for (final event in inRangePrs) {
      prsByExercise[event.exerciseId] =
          (prsByExercise[event.exerciseId] ?? 0) + 1;
    }

    final exerciseRows = _buildExerciseRows(
      aggregates: current.exercises,
      exercisesById: exercisesById,
      records: records,
      prsByExercise: prsByExercise,
    );

    final strength = _buildStrength(
      rows: exerciseRows,
      aggregates: current.exercises,
      records: records,
    );

    return AnalyticsSnapshot(
      range: range,
      now: now,
      overview: OverviewStats(
        range: range,
        workouts: current.workouts,
        sets: current.sets,
        reps: current.reps,
        volume: current.volume,
        minutes: current.minutes,
        activeDays: current.activeDays.length,
        prs: inRangePrs.length,
        streak: _streak(sessions, today),
        prevWorkouts: previous.workouts,
        prevSets: previous.sets,
        prevReps: previous.reps,
        prevVolume: previous.volume,
      ),
      volumeBuckets: volumeBuckets,
      heatmap: heatmap,
      weight: weight,
      exercises: exerciseRows,
      strength: strength,
      prEvents: inRangePrs,
    );
  }

  /// The inclusive start of the window, or `null` when nothing exists yet.
  static DateTime? _windowStart(
    List<WorkoutSession> sessions,
    List<WeightEntry> weightEntries,
    AnalyticsRange range,
    DateTime today,
  ) {
    final fixed = range.startDate(today);
    if (fixed != null) return fixed;
    DateTime? earliest;
    for (final session in sessions) {
      if (!_hasCompletedSets(session)) continue;
      final day = dateOnly(session.date);
      if (earliest == null || day.isBefore(earliest)) earliest = day;
    }
    for (final entry in weightEntries) {
      final day = dateOnly(entry.date);
      if (earliest == null || day.isBefore(earliest)) earliest = day;
    }
    return earliest;
  }

  static List<VolumeBucket> _buildBuckets({
    required DateTime from,
    required DateTime to,
    required _Period period,
    required Map<DateTime, double> volumes,
    required Map<DateTime, int> sets,
  }) {
    final buckets = <VolumeBucket>[];
    var start = _bucketStart(from, period);
    final last = _bucketStart(to, period);
    while (!start.isAfter(last)) {
      buckets.add(VolumeBucket(
        label: _bucketLabel(start, period),
        start: start,
        volume: volumes[start] ?? 0,
        sets: sets[start] ?? 0,
      ));
      start = _addPeriod(start, period);
      if (buckets.length > 60) buckets.removeAt(0);
    }
    return buckets;
  }

  static FrequencyHeatmapData _buildHeatmap({
    required DateTime from,
    required DateTime to,
    required Map<DateTime, int> setsByDay,
  }) {
    var maxSets = 0;
    for (final count in setsByDay.values) {
      if (count > maxSets) maxSets = count;
    }

    final weeks = <List<FrequencyDay?>>[];
    var weekStart = _mondayOf(from);
    var totalWorkouts = 0;
    while (!weekStart.isAfter(to) && weeks.length < 52) {
      final week = <FrequencyDay?>[];
      for (var i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        if (day.isAfter(to)) {
          week.add(null);
          continue;
        }
        final sets = setsByDay[day] ?? 0;
        if (sets > 0) totalWorkouts += 1;
        week.add(FrequencyDay(
          date: day,
          sets: sets,
          intensity: maxSets == 0
              ? 0
              : (sets / maxSets).clamp(0.0, 1.0).toDouble(),
        ));
      }
      weeks.add(week);
      weekStart = weekStart.add(const Duration(days: 7));
    }
    return FrequencyHeatmapData(
      weeks: weeks,
      maxSets: maxSets,
      totalWorkouts: totalWorkouts,
    );
  }

  static WeightTrendData _buildWeight(
    List<WeightEntry> entries,
    DateTime? from,
    DateTime to,
  ) {
    final points = <WeightPoint>[];
    for (final entry in entries) {
      final day = dateOnly(entry.date);
      if (from != null && day.isBefore(from)) continue;
      if (day.isAfter(to)) continue;
      points.add(WeightPoint(date: day, weight: entry.weight));
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    if (points.isEmpty) {
      return const WeightTrendData(points: []);
    }
    var min = points.first.weight;
    var max = points.first.weight;
    var sum = 0.0;
    for (final point in points) {
      if (point.weight < min) min = point.weight;
      if (point.weight > max) max = point.weight;
      sum += point.weight;
    }
    return WeightTrendData(
      points: points,
      latest: points.last.weight,
      delta: points.length >= 2
          ? points.last.weight - points.first.weight
          : null,
      min: min,
      max: max,
      average: sum / points.length,
    );
  }

  static List<ExerciseAnalytics> _buildExerciseRows({
    required Map<String, _ExerciseAgg> aggregates,
    required Map<String, Exercise> exercisesById,
    required List<PersonalRecord> records,
    required Map<String, int> prsByExercise,
  }) {
    final recordsById = {for (final record in records) record.exerciseId: record};
    final rows = <ExerciseAnalytics>[];
    for (final entry in aggregates.entries) {
      final aggregate = entry.value;
      final exercise = exercisesById[entry.key];
      final trajectory = aggregate.oneRmByDay.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final start =
          trajectory.isEmpty ? 0.0 : trajectory.first.value;
      final end = trajectory.isEmpty ? 0.0 : trajectory.last.value;
      final current = recordsById[entry.key]?.estimatedOneRM ?? end;
      rows.add(ExerciseAnalytics(
        exerciseId: entry.key,
        exerciseName: aggregate.exerciseName.isEmpty
            ? (exercise?.name ?? 'Exercise')
            : aggregate.exerciseName,
        muscleGroup: exercise?.muscleGroup ?? '',
        isCompound: exercise?.isCompound ?? false,
        sessions: aggregate.sessions,
        sets: aggregate.sets,
        volume: aggregate.volume,
        volumePerSession:
            aggregate.sessions == 0 ? 0 : aggregate.volume / aggregate.sessions,
        estimatedOneRM: current,
        estOneRMStart: start,
        estOneRMEnd: end,
        estOneRMDelta: end - start,
        prs: prsByExercise[entry.key] ?? 0,
      ));
    }
    rows.sort((a, b) => b.volume.compareTo(a.volume));
    return rows;
  }

  static StrengthTrendData _buildStrength({
    required List<ExerciseAnalytics> rows,
    required Map<String, _ExerciseAgg> aggregates,
    required List<PersonalRecord> records,
  }) {
    var totalOneRM = 0.0;
    var bestOneRM = 0.0;
    for (final record in records) {
      totalOneRM += record.estimatedOneRM;
      if (record.estimatedOneRM > bestOneRM) bestOneRM = record.estimatedOneRM;
    }
    final trajectories = <OneRmTrajectory>[];
    for (final row in rows.take(3)) {
      final aggregate = aggregates[row.exerciseId];
      if (aggregate == null) continue;
      final points = [
        for (final entry in aggregate.oneRmByDay.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
          OneRmPoint(date: entry.key, value: entry.value),
      ];
      if (points.isEmpty) continue;
      trajectories.add(OneRmTrajectory(
        exerciseId: row.exerciseId,
        exerciseName: row.exerciseName,
        points: points,
      ));
    }
    return StrengthTrendData(
      totalOneRM: totalOneRM,
      bestOneRM: bestOneRM,
      trajectories: trajectories,
    );
  }

  static bool _hasCompletedSets(WorkoutSession session) {
    for (final exercise in session.exercises) {
      for (final set in exercise.sets) {
        if (set.completed) return true;
      }
    }
    return false;
  }

  /// The current consecutive-day streak, counting back from [today].
  static int _streak(List<WorkoutSession> sessions, DateTime today) {
    final completed = [
      for (final session in sessions)
        if (_hasCompletedSets(session)) session,
    ];
    var day = today;
    if (!_hasSessionOn(completed, day)) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (_hasSessionOn(completed, day)) {
      streak += 1;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static bool _hasSessionOn(List<WorkoutSession> sessions, DateTime day) {
    for (final session in sessions) {
      if (isSameDay(session.date, day)) return true;
    }
    return false;
  }

  static DateTime _mondayOf(DateTime day) {
    final date = dateOnly(day);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static _Period _periodFor(AnalyticsRange range) => switch (range) {
        AnalyticsRange.last7Days => _Period.day,
        AnalyticsRange.last30Days => _Period.day,
        AnalyticsRange.last90Days => _Period.week,
        AnalyticsRange.last6Months => _Period.week,
        AnalyticsRange.lastYear => _Period.week,
        AnalyticsRange.lifetime => _Period.month,
      };

  static DateTime _bucketStart(DateTime day, _Period period) => switch (period) {
        _Period.day => dateOnly(day),
        _Period.week => _mondayOf(day),
        _Period.month => DateTime(day.year, day.month, 1),
      };

  static DateTime _addPeriod(DateTime start, _Period period) => switch (period) {
        _Period.day => start.add(const Duration(days: 1)),
        _Period.week => start.add(const Duration(days: 7)),
        _Period.month => DateTime(start.year, start.month + 1, 1),
      };

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _bucketLabel(DateTime start, _Period period) =>
      period == _Period.month
          ? _months[start.month - 1]
          : '${_months[start.month - 1]} ${start.day}';
}

/// Accumulators for one window of the session scan.
class _Window {
  int workouts = 0;
  int sets = 0;
  int reps = 0;
  double volume = 0;
  int minutes = 0;
  final Set<DateTime> activeDays = {};
  final Map<DateTime, int> setsByDay = {};
  final Map<String, _ExerciseAgg> exercises = {};
}

/// Per-exercise aggregates for one window.
class _ExerciseAgg {
  String exerciseName = '';
  int sessions = 0;
  int sets = 0;
  double volume = 0;
  final Set<String> sessionIds = {};
  final Map<DateTime, double> oneRmByDay = {};
}
