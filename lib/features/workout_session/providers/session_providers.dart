// Workout session providers for the Forge application.
//
// The [ActiveSessionController] owns the mutable in-progress workout and
// debounce-persists it so every set survives an app restart. Derived
// providers expose the ticking clocks and live stats that the active and
// summary screens render, each watching only the data it needs.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/workout_exercise.dart';
import '../../../models/workout_session.dart';
import '../../../models/workout_set.dart';
import '../../../services/providers.dart';
import '../data/active_session_store.dart';
import '../data/session_box_watchers.dart';
import '../domain/session_calculations.dart';
import '../domain/session_models.dart';
import '../domain/session_preparation.dart';
import '../services/session_service.dart';
import '../../prs/providers/pr_providers.dart';

/// The session feature's notion of "now" (test-pin-able).
final sessionNowProvider = Provider<DateTime>((_) => DateTime.now());

/// Persists and loads the in-progress workout.
final activeSessionStoreProvider = Provider<ActiveSessionStore>(
  (ref) => ActiveSessionStore(ref.watch(databaseServiceProvider)),
);

/// Performs session lifecycle transitions and derived-write side effects.
final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(
    store: ref.watch(activeSessionStoreProvider),
    workoutSessionRepository: ref.watch(workoutSessionRepositoryProvider),
    exerciseHistoryRepository: ref.watch(exerciseHistoryRepositoryProvider),
    personalRecordRepository: ref.watch(personalRecordRepositoryProvider),
    calendarRepository: ref.watch(calendarRepositoryProvider),
    exerciseRepository: ref.watch(exerciseRepositoryProvider),
    prEngine: ref.watch(prEngineProvider),
    formula: ref.watch(prFormulaProvider),
  );
});

/// Emits a new value every second so timers re-render.
final sessionTickProvider = StreamProvider<int>(
  (ref) => Stream.periodic(const Duration(seconds: 1), (count) => count),
);

/// The in-progress session, or null once finished/abandoned.
final activeSessionProvider =
    AsyncNotifierProvider<ActiveSessionController, ActiveSession?>(
  ActiveSessionController.new,
);

/// Owns the in-progress workout and applies all state transitions.
///
/// The session is immutable; every mutation returns a new [ActiveSession]
/// that becomes the notifier state. Each mutation also debounces a persist
/// (autosave) so every set survives an app restart.
class ActiveSessionController extends AsyncNotifier<ActiveSession?> {
  Timer? _saveTimer;

  SessionService get _service => ref.read(sessionServiceProvider);

  DateTime get _now => ref.read(sessionNowProvider);

  @override
  Future<ActiveSession?> build() async {
    ref.onDispose(() => _saveTimer?.cancel());
    final session = await _service.load();
    if (session == null) return null;
    final expired = session.expireRestIfElapsed(_now);
    if (expired != session) {
      await _persist(expired);
    }
    return expired;
  }

  // --- Lifecycle ------------------------------------------------------------

  /// Restores a persisted session or builds a fresh preparation session.
  ///
  /// When no session is in progress a preparation session is built from
  /// [plans] (usually today's split day, possibly empty).
  Future<void> openSession({
    required String name,
    required List<ActiveExercisePlan> plans,
    DateTime? now,
  }) async {
    if (state.value != null) return;
    final timestamp = now ?? _now;
    final session = ActiveSessionBuilder.fromPlans(
      name: name,
      now: timestamp,
      plans: plans,
    );
    await _persist(session);
    state = AsyncData(session);
  }

  /// Transitions the preparation session into an active workout.
  Future<void> start({DateTime? now}) async {
    final session = state.value;
    if (session == null || session.content.startedAt != null) return;
    final timestamp = now ?? _now;
    var updated = session.insertWarmupSets(timestamp);
    updated = updated
        .copyWith(
          content: updated.content.copyWith(
            startedAt: () => timestamp,
            updatedAt: timestamp,
          ),
          ui: updated.ui.copyWith(stage: SessionStage.active),
        )
        .touch(timestamp);
    await _persist(updated);
    state = AsyncData(updated);
  }

  /// Finalizes the session into permanent history and enters the summary.
  Future<WorkoutSession?> finish({DateTime? now}) async {
    final session = state.value;
    if (session == null) return null;
    final timestamp = now ?? _now;
    final result = await _service.finishWithRecords(session, timestamp);
    ref.read(prCelebrationProvider.notifier).celebrate(result.records);
    final summary = session
        .copyWith(
          content: result.session,
          ui: session.ui.copyWith(stage: SessionStage.summary),
        )
        .touch(timestamp);
    state = AsyncData(summary);
    return result.session;
  }

  /// Discards the in-progress session without recording it.
  Future<void> abandon() async {
    ref.read(prCelebrationProvider.notifier).dismiss();
    await _service.abandon();
    state = const AsyncData(null);
  }

  /// Writes the current session immediately (used by tests and app pauses).
  Future<void> flushSave() async {
    final session = state.value;
    if (session == null) return;
    await _persist(session);
  }

  // --- Session timer ---------------------------------------------------------

  /// Pauses the session timer, freezing the elapsed time.
  void pauseTimer({DateTime? now}) =>
      _apply((session) => session.pauseTimer(now ?? _now));

  /// Resumes a paused session timer.
  void resumeTimer({DateTime? now}) =>
      _apply((session) => session.resumeTimer(now ?? _now));

  // --- Rest timer ------------------------------------------------------------

  /// Starts the rest timer for [duration] (defaults to the settings rest).
  void startRest({Duration? duration, DateTime? now}) {
    final rest =
        duration ?? Duration(seconds: ref.read(settingsProvider).restTimer);
    _apply((session) => session.startRest(rest, now ?? _now));
  }

  /// Pauses the running rest timer.
  void pauseRest({DateTime? now}) =>
      _apply((session) => session.pauseRest(now ?? _now));

  /// Resumes a paused rest timer.
  void resumeRest({DateTime? now}) =>
      _apply((session) => session.resumeRest(now ?? _now));

  /// Cancels the rest timer.
  void skipRest({DateTime? now}) =>
      _apply((session) => session.skipRest(now: now ?? _now));

  // --- Exercise navigation -----------------------------------------------------

  /// Moves focus to the exercise at [index], cancelling rest.
  void focusExercise(int index, {DateTime? now}) =>
      _apply((session) => session.focusExercise(index, now: now ?? _now));

  /// Advances to the next exercise (no-op on the last one).
  void nextExercise({DateTime? now}) {
    final session = state.value;
    if (session == null) return;
    final next = session.ui.currentExerciseIndex + 1;
    if (next >= session.content.exercises.length) return;
    _apply((current) => current.focusExercise(next, now: now ?? _now));
  }

  // --- Sets ---------------------------------------------------------------------

  /// Replaces a set wholesale (used by the set editor and completion).
  ///
  /// Completing a non-final set auto-starts the rest timer; un-completing a
  /// set cancels any running rest timer.
  void updateSet(
    int exerciseIndex,
    int setIndex,
    WorkoutSet set, {
    DateTime? now,
  }) {
    final session = state.value;
    if (session == null) return;
    final timestamp = now ?? _now;
    final wasCompleted =
        session.content.exercises[exerciseIndex].sets[setIndex].completed;
    var updated = session.updateSet(exerciseIndex, setIndex, set, timestamp);
    if (!set.completed && wasCompleted) {
      updated = updated.skipRest(now: timestamp);
    } else {
      final sets = updated.content.exercises[exerciseIndex].sets;
      if (set.completed &&
          !wasCompleted &&
          setIndex < sets.length - 1 &&
          set.restSeconds > 0) {
        updated = updated.startRest(
          Duration(seconds: set.restSeconds),
          timestamp,
        );
      }
    }
    _scheduleSave(updated);
    state = AsyncData(updated);
  }

  /// Adds a new empty set to an exercise.
  void addSet(int exerciseIndex, {int? beforeIndex}) {
    final session = state.value;
    if (session == null) return;
    final exercise = session.content.exercises[exerciseIndex];
    final last = exercise.sets.isEmpty
        ? null
        : exercise.sets[exercise.sets.length - 1];
    _apply(
      (current) => current.addSet(
        exerciseIndex,
        WorkoutSet(
          weight: last?.weight ?? 0,
          reps: last?.reps ?? 0,
          restSeconds: last?.restSeconds ?? 90,
          completed: false,
        ),
        beforeIndex: beforeIndex,
        now: _now,
      ),
    );
  }

  /// Duplicates the set at [setIndex].
  void duplicateSet(int exerciseIndex, int setIndex) =>
      _apply((session) => session.duplicateSet(exerciseIndex, setIndex, _now));

  /// Deletes the set at [setIndex].
  void deleteSet(int exerciseIndex, int setIndex) =>
      _apply((session) => session.removeSet(exerciseIndex, setIndex, now: _now));

  /// Moves the set at [from] to [to].
  void reorderSet(int exerciseIndex, int from, int to) =>
      _apply((session) => session.reorderSet(exerciseIndex, from, to, _now));

  // --- Exercises -----------------------------------------------------------------

  /// Adds a manually chosen exercise to the session.
  void addExercise(WorkoutExercise exercise) =>
      _apply((session) => session.addExercise(exercise, now: _now));

  /// Removes the exercise at [index].
  void removeExercise(int index) =>
      _apply((session) => session.removeExercise(index, now: _now));

  /// Moves the exercise at [from] to [to].
  void reorderExercise(int from, int to) =>
      _apply((session) => session.reorderExercise(from, to, _now));

  // --- Notes / name / warm-up -------------------------------------------------------

  /// Updates the session notes (autosaved).
  void updateSessionNotes(String notes) {
    final session = state.value;
    if (session == null || session.content.notes == notes) return;
    _apply((current) => current.updateNotes(notes, _now));
  }

  /// Updates the session display name.
  void updateSessionName(String name) {
    final session = state.value;
    if (session == null || session.content.name == name) return;
    _apply((current) => current.updateName(name, _now));
  }

  /// Toggles the warm-up reminder for an exercise during preparation.
  void toggleWarmup(String exerciseId) =>
      _apply((session) => session.toggleWarmup(exerciseId, now: _now));

  // --- Persistence ------------------------------------------------------------------

  /// Applies a mutation and notifies when the session actually changed.
  void _apply(ActiveSession Function(ActiveSession session) mutate) {
    final session = state.value;
    if (session == null) return;
    final updated = mutate(session);
    if (updated == session) return;
    _scheduleSave(updated);
    state = AsyncData(updated);
  }

  void _scheduleSave(ActiveSession session) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      _saveTimer = null;
      unawaited(_persist(session));
    });
  }

  Future<void> _persist(ActiveSession session) async {
    if (!ref.mounted) return;
    _saveTimer?.cancel();
    _saveTimer = null;
    await _service.save(session);
  }
}

/// Snapshot of the rest timer for rendering.
class RestTimerState {
  /// Creates the rest timer read model.
  const RestTimerState({
    required this.active,
    required this.paused,
    required this.remaining,
    required this.total,
  });

  /// Whether a rest timer is running or paused.
  final bool active;

  /// Whether the timer is paused.
  final bool paused;

  /// Time left.
  final Duration remaining;

  /// Full configured duration.
  final Duration total;

  /// Idle state (no timer).
  static const RestTimerState idle = RestTimerState(
    active: false,
    paused: false,
    remaining: Duration.zero,
    total: Duration.zero,
  );

  /// Whether the timer has just elapsed.
  bool get finished => active && remaining == Duration.zero;
}

/// The rest timer read model, ticking every second.
final restTimerProvider = Provider<RestTimerState>((ref) {
  final session = ref.watch(activeSessionProvider).value;
  if (session == null || !session.isRestActive) return RestTimerState.idle;
  ref.watch(sessionTickProvider);
  final now = ref.watch(sessionNowProvider);
  return RestTimerState(
    active: true,
    paused: session.ui.restPaused,
    remaining: Duration(milliseconds: session.restRemainingMsAt(now)),
    total: Duration(milliseconds: session.ui.restTotalMs),
  );
});

/// Elapsed session time, ticking every second.
final sessionElapsedProvider = Provider<Duration>((ref) {
  final session = ref.watch(activeSessionProvider).value;
  if (session == null || session.content.startedAt == null) {
    return Duration.zero;
  }
  ref.watch(sessionTickProvider);
  final now = ref.watch(sessionNowProvider);
  return session.elapsedAt(now);
});

/// Live aggregate stats, ticking every second.
final liveSessionStatsProvider = Provider<SessionStats>((ref) {
  final session = ref.watch(activeSessionProvider).value;
  if (session == null) {
    return const SessionStats(
      exercises: 0,
      sets: 0,
      reps: 0,
      volume: 0,
      durationSeconds: 0,
      averageRpe: null,
      calories: 0,
      bestWeight: 0,
    );
  }
  ref.watch(sessionTickProvider);
  final now = ref.watch(sessionNowProvider);
  final bodyWeight = ref.watch(weightRepositoryProvider).latest()?.weight ?? 0;
  return SessionCalculations.statsFor(
    session,
    now: now,
    bodyWeightKg: bodyWeight,
  );
});

/// The preparation read model derived from the in-progress session.
final sessionPreparationProvider = Provider<SessionPreparationData>((ref) {
  final session = ref.watch(activeSessionProvider).value;
  if (session == null) {
    return const SessionPreparationData(
      name: '',
      exercises: [],
      estimatedMinutes: 0,
      targetSets: 0,
      targetVolume: 0,
    );
  }
  final exercisesById = {
    for (final exercise in ref.watch(exerciseRepositoryProvider).all())
      exercise.id: exercise,
  };
  final historyRepository = ref.watch(exerciseHistoryRepositoryProvider);
  final recordRepository = ref.watch(personalRecordRepositoryProvider);

  final views = <PlannedExerciseView>[];
  var targetSets = 0;
  var estimatedSeconds = 0;
  var targetVolume = 0.0;
  for (final performed in session.content.exercises) {
    final library = exercisesById[performed.exerciseId];
    final working =
        performed.sets.where((set) => !set.isWarmup).toList();
    final sets = working.isEmpty ? performed.sets.length : working.length;
    final first = working.isEmpty ? null : working.first;
    final targetReps = first != null && first.reps > 0
        ? first.reps
        : (library?.defaultReps ?? 0);
    final restSeconds = first?.restSeconds ?? library?.defaultRestSeconds ?? 90;

    final history = historyRepository.forExercise(performed.exerciseId);
    final lastRow = history.isEmpty ? null : history.last;
    final record = recordRepository.forExercise(performed.exerciseId);

    final prefillWeight =
        first != null && first.weight > 0 ? first.weight : 0.0;
    targetSets += sets;
    estimatedSeconds += sets * (restSeconds + 30);
    targetVolume += sets * prefillWeight * targetReps;

    views.add(PlannedExerciseView(
      exerciseId: performed.exerciseId,
      exerciseName: performed.exerciseName,
      muscleGroup: library?.muscleGroup ?? '',
      targetSets: sets,
      targetReps: targetReps,
      tempo: first?.tempo,
      lastWeight:
          lastRow != null && lastRow.bestWeight > 0 ? lastRow.bestWeight : null,
      lastReps: lastRow != null && lastRow.bestReps > 0 ? lastRow.bestReps : null,
      lastOneRM: lastRow != null && lastRow.estimatedOneRM > 0
          ? lastRow.estimatedOneRM
          : null,
      prOneRM:
          record != null && record.estimatedOneRM > 0 ? record.estimatedOneRM : null,
    ));
  }

  return SessionPreparationData(
    name: session.content.name,
    exercises: views,
    estimatedMinutes: (estimatedSeconds / 60).ceil(),
    targetSets: targetSets,
    targetVolume: targetVolume,
  );
});

/// The most recent performed sessions (summary history list).
final recentSessionsProvider = Provider<List<WorkoutSession>>((ref) {
  ref.watch(sessionBoxChangesProvider);
  return ref.watch(workoutSessionRepositoryProvider).recent(20);
});
