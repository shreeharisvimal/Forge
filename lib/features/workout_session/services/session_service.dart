// Session lifecycle service for the Forge application.
//
// Orchestrates the transition of an in-progress [ActiveSession] into a
// permanent record: finishing moves the content from the active-session box
// into the session history, stamps day aggregates (exercise history,
// personal records, calendar row) and marks the exercises as used.
// Abandoning discards the workout without touching history.
library;

import '../../../core/utils/dates.dart';
import '../../../core/utils/stats.dart';
import '../../../models/calendar_day.dart';
import '../../../models/exercise_history.dart';
import '../../../models/personal_record.dart';
import '../../../models/workout_exercise.dart';
import '../../../models/workout_session.dart';
import '../../../services/repositories/calendar_repository.dart';
import '../../../services/repositories/exercise_history_repository.dart';
import '../../../services/repositories/exercise_repository.dart';
import '../../../services/repositories/personal_record_repository.dart';
import '../../../services/repositories/workout_session_repository.dart';
import '../../prs/data/pr_event.dart';
import '../../prs/domain/one_rep_max.dart';
import '../../prs/domain/pr_engine.dart';
import '../data/active_session_store.dart';
import '../domain/session_models.dart';

/// The outcome of finalizing a session: the permanent record plus the
/// personal-record events the session produced.
class SessionFinishResult {
  /// Creates a finish result.
  const SessionFinishResult({required this.session, required this.records});

  /// The finalized [WorkoutSession].
  final WorkoutSession session;

  /// The new [PrEvent]s this session minted, in exercise order.
  final List<PrEvent> records;
}

/// Performs the lifecycle transitions of a workout session.
class SessionService {
  /// Creates the service with its repositories.
  SessionService({
    required this.store,
    required this.workoutSessionRepository,
    required this.exerciseHistoryRepository,
    required this.personalRecordRepository,
    required this.calendarRepository,
    required this.exerciseRepository,
    this.prEngine,
    this.formula = OneRepMaxFormula.epley,
  });

  /// Persists the active session's content and UI state.
  final ActiveSessionStore store;

  /// Repository for permanent session records.
  final WorkoutSessionRepository workoutSessionRepository;

  /// Repository for daily per-exercise aggregates.
  final ExerciseHistoryRepository exerciseHistoryRepository;

  /// Repository for lifetime personal bests.
  final PersonalRecordRepository personalRecordRepository;

  /// Repository for calendar day rows.
  final CalendarRepository calendarRepository;

  /// Repository for the exercise library (usage tracking).
  final ExerciseRepository exerciseRepository;

  /// Detects the personal records a finished session produced. When null the
  /// session is finalized without emitting PR events (test convenience).
  final PrEngine? prEngine;

  /// The one-rep-max formula used for record detection.
  final OneRepMaxFormula formula;

  /// Persists [session] so it survives an app restart.
  Future<void> save(ActiveSession session) => store.save(session);

  /// Loads the in-progress session, or null when none exists.
  Future<ActiveSession?> load() => store.load();

  /// Moves [session] into permanent history and updates derived aggregates.
  ///
  /// When the session contains no completed sets it is still recorded (as an
  /// incomplete session) but history, records and the calendar are untouched.
  /// Returns the finalized [WorkoutSession].
  Future<WorkoutSession> finish(ActiveSession session, DateTime now) async {
    return (await _finish(session, now)).session;
  }

  /// Moves [session] into permanent history and returns the created PR events.
  ///
  /// Equivalent to [finish] but also surfaces the [PrEvent]s that were
  /// detected and persisted, so callers can drive the celebration flow.
  Future<SessionFinishResult> finishWithRecords(
    ActiveSession session,
    DateTime now,
  ) async {
    return _finish(session, now);
  }

  Future<SessionFinishResult> _finish(
    ActiveSession session,
    DateTime now,
  ) async {
    final finalSession = session.toFinalSession(now);
    var records = const <PrEvent>[];

    if (finalSession.completed) {
      final engine = prEngine;
      if (engine != null) {
        records = engine.evaluateSession(finalSession, formula: formula);
        for (final event in records) {
          await engine.prEventRepository.save(event);
        }
      }
      await _updateHistoryAndRecords(finalSession);
      await _recordExerciseUsage(finalSession);
    }

    await workoutSessionRepository.save(finalSession);
    await store.clear();
    return SessionFinishResult(session: finalSession, records: records);
  }

  /// Discards the in-progress workout without recording it.
  Future<void> abandon() => store.clear();

  /// Whether the session has at least one completed set.
  bool hasCompletedSets(ActiveSession session) => session.hasCompletedSets;

  Future<void> _updateHistoryAndRecords(WorkoutSession session) async {
    final day = dateOnly(session.date);
    for (final performed in session.exercises) {
      final aggregate = _aggregate(performed);
      if (aggregate.completedSets == 0) continue;

      await _mergeHistory(performed.exerciseId, day, aggregate);
      await _mergeRecord(performed.exerciseId, day, aggregate, session.durationMinutes);
    }
    await _mergeCalendarDay(session);
  }

  Future<void> _mergeHistory(
    String exerciseId,
    DateTime day,
    _PerExerciseAggregate aggregate,
  ) async {
    final existing = exerciseHistoryRepository.onDate(exerciseId, day);
    await exerciseHistoryRepository.save(
      ExerciseHistory(
        id: existing?.id,
        exerciseId: exerciseId,
        date: day,
        bestWeight: _max(existing?.bestWeight, aggregate.bestWeight),
        bestReps: _maxInt(existing?.bestReps, aggregate.bestReps),
        estimatedOneRM: _max(existing?.estimatedOneRM, aggregate.estimatedOneRM),
        totalVolume: (existing?.totalVolume ?? 0) + aggregate.volume,
      ),
    );
  }

  Future<void> _mergeRecord(
    String exerciseId,
    DateTime day,
    _PerExerciseAggregate aggregate,
    int sessionMinutes,
  ) async {
    final existing = personalRecordRepository.forExercise(exerciseId);
    final merged = PersonalRecord(
      id: existing?.id,
      exerciseId: exerciseId,
      highestWeight: _max(existing?.highestWeight, aggregate.bestWeight),
      bestReps: _maxInt(existing?.bestReps, aggregate.bestReps),
      estimatedOneRM: _max(existing?.estimatedOneRM, aggregate.estimatedOneRM),
      bestVolume: _max(existing?.bestVolume, aggregate.volume),
      lastUpdated: day,
    );
    await personalRecordRepository.save(merged);
  }

  Future<void> _mergeCalendarDay(WorkoutSession session) async {
    final day = dateOnly(session.date);
    final existing = calendarRepository.onDate(day);
    await calendarRepository.save(
      (existing ?? CalendarDay(date: day)).copyWith(
        workoutCompleted: true,
        durationMinutes: _maxInt(existing?.durationMinutes, session.durationMinutes),
      ),
    );
  }

  Future<void> _recordExerciseUsage(WorkoutSession session) async {
    for (final performed in session.exercises) {
      final exercise = exerciseRepository.byId(performed.exerciseId);
      if (exercise != null) {
        await exerciseRepository.recordUsage(exercise);
      }
    }
  }

  static double _max(double? a, double b) =>
      (a ?? 0) > b ? a! : b;

  static int _maxInt(int? a, int b) => (a ?? 0) > b ? a! : b;

  _PerExerciseAggregate _aggregate(WorkoutExercise performed) {
    var completedSets = 0;
    var bestWeight = 0.0;
    var bestReps = 0;
    var bestOneRM = 0.0;
    var volume = 0.0;
    for (final set in performed.sets) {
      if (!set.completed) continue;
      completedSets++;
      bestWeight = _max(bestWeight, set.weight);
      bestReps = _maxInt(bestReps, set.reps);
      bestOneRM = _max(bestOneRM, estimateOneRM(set.weight, set.reps));
      volume += setVolume(set);
    }
    return _PerExerciseAggregate(
      completedSets: completedSets,
      bestWeight: bestWeight,
      bestReps: bestReps,
      estimatedOneRM: bestOneRM,
      volume: volume,
    );
  }
}

class _PerExerciseAggregate {
  const _PerExerciseAggregate({
    required this.completedSets,
    required this.bestWeight,
    required this.bestReps,
    required this.estimatedOneRM,
    required this.volume,
  });

  final int completedSets;
  final double bestWeight;
  final int bestReps;
  final double estimatedOneRM;
  final double volume;
}
