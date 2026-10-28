// Workout session domain models for the Forge application.
//
// The active (in-progress) workout is an immutable [ActiveSession] pairing
// the persistent [WorkoutSession] content with a small immutable
// [SessionUiState] carrying the transient UI state (stage, focused exercise,
// rest timer, session-timer pause). Every mutation returns a new
// [ActiveSession] via the copyWith pattern, which keeps the Riverpod
// notifier's state transitions explicit and predictable. Kept free of
// Flutter imports so the whole engine is unit-testable without a widget tree.
library;

import 'package:equatable/equatable.dart';

import '../../../core/utils/ids.dart';
import '../../../models/workout_exercise.dart';
import '../../../models/workout_session.dart';
import '../../../models/workout_set.dart';

/// The lifecycle stage of a workout session.
enum SessionStage {
  /// User is still building/confirming the workout before starting.
  preparation,

  /// The workout has started and is being performed.
  active,

  /// The workout has been finished and the summary is shown.
  summary,
}

/// Transient UI state of an active session.
///
/// Persisted as JSON (alongside the [WorkoutSession] content record) so a
/// session survives app restarts mid-workout — including a running rest
/// timer, which keeps counting while the app is closed.
class SessionUiState extends Equatable {
  /// Creates a default (preparation-stage) UI state.
  const SessionUiState({
    this.stage = SessionStage.preparation,
    this.currentExerciseIndex = 0,
    this.restEndsAt = 0,
    this.restPaused = false,
    this.restRemainingMs = 0,
    this.restTotalMs = 0,
    this.isTimerPaused = false,
    this.pausedMs = 0,
    this.pausedElapsedMs = 0,
    this.lastTouchedMs = 0,
    this.warmupExerciseIds = const [],
  });

  /// Current lifecycle stage.
  final SessionStage stage;

  /// Index into [ActiveSession.content.exercises] currently in focus.
  final int currentExerciseIndex;

  /// Absolute epoch-millis when the rest timer should end; 0 when idle.
  final int restEndsAt;

  /// Whether the rest timer is paused.
  final bool restPaused;

  /// Remaining rest in millis (meaningful while [restPaused]).
  final int restRemainingMs;

  /// Full rest duration in millis (for progress display).
  final int restTotalMs;

  /// Whether the session timer is paused.
  final bool isTimerPaused;

  /// Accumulated session-timer pause in millis.
  final int pausedMs;

  /// The frozen elapsed value captured when the session timer was paused.
  final int pausedElapsedMs;

  /// Epoch-millis of the last state mutation (drives autosave throttling).
  final int lastTouchedMs;

  /// Exercise instance ids that should start with warm-up sets.
  final List<String> warmupExerciseIds;

  /// The clock the rest timer will ring at, or null when idle.
  DateTime? get restDeadline =>
      !restPaused && restEndsAt > 0
          ? DateTime.fromMillisecondsSinceEpoch(restEndsAt)
          : null;

  /// Returns a copy with the given fields replaced.
  SessionUiState copyWith({
    SessionStage? stage,
    int? currentExerciseIndex,
    int? restEndsAt,
    bool? restPaused,
    int? restRemainingMs,
    int? restTotalMs,
    bool? isTimerPaused,
    int? pausedMs,
    int? pausedElapsedMs,
    int? lastTouchedMs,
    List<String>? warmupExerciseIds,
  }) {
    return SessionUiState(
      stage: stage ?? this.stage,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      restEndsAt: restEndsAt ?? this.restEndsAt,
      restPaused: restPaused ?? this.restPaused,
      restRemainingMs: restRemainingMs ?? this.restRemainingMs,
      restTotalMs: restTotalMs ?? this.restTotalMs,
      isTimerPaused: isTimerPaused ?? this.isTimerPaused,
      pausedMs: pausedMs ?? this.pausedMs,
      pausedElapsedMs: pausedElapsedMs ?? this.pausedElapsedMs,
      lastTouchedMs: lastTouchedMs ?? this.lastTouchedMs,
      warmupExerciseIds: warmupExerciseIds ?? this.warmupExerciseIds,
    );
  }

  /// Serializes to a JSON-safe map.
  Map<String, dynamic> toMap() => {
        'stage': stage.name,
        'currentExerciseIndex': currentExerciseIndex,
        'restEndsAt': restEndsAt,
        'restPaused': restPaused,
        'restRemainingMs': restRemainingMs,
        'restTotalMs': restTotalMs,
        'isTimerPaused': isTimerPaused,
        'pausedMs': pausedMs,
        'pausedElapsedMs': pausedElapsedMs,
        'lastTouchedMs': lastTouchedMs,
        'warmupExerciseIds': warmupExerciseIds,
      };

  /// Deserializes from a map produced by [toMap].
  factory SessionUiState.fromMap(Map<String, dynamic> map) {
    return SessionUiState(
      stage: SessionStage.values.asNameMap()[map['stage']] ??
          SessionStage.preparation,
      currentExerciseIndex: (map['currentExerciseIndex'] as num?)?.toInt() ?? 0,
      restEndsAt: (map['restEndsAt'] as num?)?.toInt() ?? 0,
      restPaused: map['restPaused'] as bool? ?? false,
      restRemainingMs: (map['restRemainingMs'] as num?)?.toInt() ?? 0,
      restTotalMs: (map['restTotalMs'] as num?)?.toInt() ?? 0,
      isTimerPaused: map['isTimerPaused'] as bool? ?? false,
      pausedMs: (map['pausedMs'] as num?)?.toInt() ?? 0,
      pausedElapsedMs: (map['pausedElapsedMs'] as num?)?.toInt() ?? 0,
      lastTouchedMs: (map['lastTouchedMs'] as num?)?.toInt() ?? 0,
      warmupExerciseIds:
          (map['warmupExerciseIds'] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  List<Object?> get props => [
        stage,
        currentExerciseIndex,
        restEndsAt,
        restPaused,
        restRemainingMs,
        restTotalMs,
        isTimerPaused,
        pausedMs,
        pausedElapsedMs,
        lastTouchedMs,
        warmupExerciseIds,
      ];
}

/// The in-progress workout: persistent content plus transient UI state.
class ActiveSession extends Equatable {
  /// Creates a session from its two persistence halves.
  const ActiveSession({required this.content, required this.ui});

  /// The workout content (name, notes, exercises, sets).
  final WorkoutSession content;

  /// The transient UI state.
  final SessionUiState ui;

  /// Current lifecycle stage.
  SessionStage get stage => ui.stage;

  /// Display name of the session.
  String get name => content.name;

  /// The exercise currently in focus (clamped to a valid index).
  WorkoutExercise get currentExercise =>
      content.exercises[_safeExerciseIndex];

  /// The current exercise index, clamped to the exercise list.
  int get _safeExerciseIndex {
    if (content.exercises.isEmpty) return 0;
    return ui.currentExerciseIndex.clamp(0, content.exercises.length - 1);
  }

  /// Whether the session has any recorded sets.
  bool get hasSets =>
      content.exercises.any((exercise) => exercise.sets.isNotEmpty);

  /// Number of completed sets across the whole session.
  int get completedSets {
    var count = 0;
    for (final exercise in content.exercises) {
      for (final set in exercise.sets) {
        if (set.completed) count++;
      }
    }
    return count;
  }

  /// Number of repetitions in completed sets.
  int get totalReps {
    var count = 0;
    for (final exercise in content.exercises) {
      for (final set in exercise.sets) {
        if (set.completed) count += set.reps;
      }
    }
    return count;
  }

  /// Total volume (weight x reps) of completed sets, in kg.
  double get volume {
    var sum = 0.0;
    for (final exercise in content.exercises) {
      for (final set in exercise.sets) {
        if (set.completed) sum += set.weight * set.reps;
      }
    }
    return sum;
  }

  /// Weighted average RPE across completed sets with an RPE recorded.
  double? get averageRpe {
    var sum = 0.0;
    var count = 0;
    for (final exercise in content.exercises) {
      for (final set in exercise.sets) {
        final rpe = set.rpe;
        if (set.completed && rpe != null) {
          sum += rpe;
          count++;
        }
      }
    }
    return count == 0 ? null : sum / count;
  }

  /// Whether the session timer is currently paused.
  bool get isTimerPaused => ui.isTimerPaused;

  /// Whether the focused exercise is the last one in the session.
  bool get isLastExercise =>
      content.exercises.isEmpty ||
      ui.currentExerciseIndex >= content.exercises.length - 1;

  /// Elapsed session time in milliseconds as of [now].
  ///
  /// When the timer is paused the frozen value is returned unchanged; the
  /// wall-clock start is [WorkoutSession.startedAt].
  int elapsedMsAt(DateTime now) {
    if (ui.isTimerPaused) return ui.pausedElapsedMs;
    final started = content.startedAt;
    if (started == null) return 0;
    return now.difference(started).inMilliseconds - ui.pausedMs;
  }

  /// Elapsed session time as a [Duration].
  Duration elapsedAt(DateTime now) => Duration(milliseconds: elapsedMsAt(now));

  /// Remaining rest time in milliseconds as of [now]; 0 when idle/finished.
  int restRemainingMsAt(DateTime now) {
    if (ui.restEndsAt <= 0) return 0;
    if (ui.restPaused) return ui.restRemainingMs;
    return (ui.restEndsAt - now.millisecondsSinceEpoch)
        .clamp(0, 1 << 32)
        .toInt();
  }

  /// Whether the rest timer is currently running or paused.
  bool get isRestActive => ui.restEndsAt > 0;

  /// Whether the rest timer has elapsed (or was skipped) and is idle.
  bool get isRestComplete => !isRestActive;

  /// Whether the session has at least one completed set.
  bool get hasCompletedSets => completedSets > 0;

  /// Snapshot of the session content suitable for Hive persistence.
  WorkoutSession get snapshot => content;

  /// Number of warm-up sets added before an exercise's working sets.
  static const int warmupSetCount = 2;

  /// Returns a copy with the given halves replaced.
  ActiveSession copyWith({WorkoutSession? content, SessionUiState? ui}) =>
      ActiveSession(
        content: content ?? this.content,
        ui: ui ?? this.ui,
      );

  // --- Mutations (all return a new [ActiveSession]) -------------------------

  /// Marks [now] as the last touch time.
  ActiveSession touch(DateTime now) =>
      copyWith(ui: ui.copyWith(lastTouchedMs: now.millisecondsSinceEpoch));

  /// Moves focus to [index] and cancels any running rest timer.
  ActiveSession focusExercise(int index, {DateTime? now}) {
    final next = content.exercises.isEmpty
        ? 0
        : index.clamp(0, content.exercises.length - 1);
    var updated = copyWith(ui: ui.copyWith(currentExerciseIndex: next));
    if (ui.restEndsAt > 0) updated = updated.skipRest();
    return now == null ? updated : updated.touch(now);
  }

  /// Starts the rest timer for [duration].
  ActiveSession startRest(Duration duration, DateTime now) {
    final millis = duration.inMilliseconds;
    return copyWith(
      ui: ui.copyWith(
        restEndsAt: now.millisecondsSinceEpoch + millis,
        restRemainingMs: millis,
        restTotalMs: millis,
        restPaused: false,
      ),
    ).touch(now);
  }

  /// Pauses the rest timer, freezing the remaining time.
  ActiveSession pauseRest(DateTime now) {
    if (!isRestActive || ui.restPaused) return this;
    return copyWith(
      ui: ui.copyWith(restRemainingMs: restRemainingMsAt(now), restPaused: true),
    ).touch(now);
  }

  /// Resumes a paused rest timer.
  ActiveSession resumeRest(DateTime now) {
    if (!ui.restPaused || ui.restEndsAt <= 0) return this;
    return copyWith(
      ui: ui.copyWith(
        restEndsAt: now.millisecondsSinceEpoch + ui.restRemainingMs,
        restPaused: false,
      ),
    ).touch(now);
  }

  /// Cancels the rest timer entirely.
  ActiveSession skipRest({DateTime? now}) {
    var updated = copyWith(
      ui: ui.copyWith(restEndsAt: 0, restRemainingMs: 0, restPaused: false),
    );
    return now == null ? updated : updated.touch(now);
  }

  /// Pauses the session timer, freezing the elapsed time.
  ActiveSession pauseTimer(DateTime now) {
    if (ui.isTimerPaused) return this;
    return copyWith(
      ui: ui.copyWith(pausedElapsedMs: elapsedMsAt(now), isTimerPaused: true),
    ).touch(now);
  }

  /// Resumes the session timer.
  ActiveSession resumeTimer(DateTime now) {
    if (!ui.isTimerPaused) return this;
    final started = content.startedAt;
    final anchor = started?.millisecondsSinceEpoch ?? now.millisecondsSinceEpoch;
    return copyWith(
      ui: ui.copyWith(
        pausedMs:
            ui.pausedMs + (now.millisecondsSinceEpoch - anchor) - ui.pausedElapsedMs,
        isTimerPaused: false,
      ),
    ).touch(now);
  }

  /// Replaces a set within an exercise.
  ActiveSession updateSet(
    int exerciseIndex,
    int setIndex,
    WorkoutSet set,
    DateTime now,
  ) {
    if (exerciseIndex < 0 || exerciseIndex >= content.exercises.length) {
      return this;
    }
    final exercise = content.exercises[exerciseIndex];
    final sets = List<WorkoutSet>.of(exercise.sets);
    if (setIndex < 0 || setIndex >= sets.length) return this;
    sets[setIndex] = set;
    return copyWith(
      content: content.copyWith(
        exercises: _replaceExercise(
          exerciseIndex,
          exercise.copyWith(sets: sets),
        ),
      ),
    ).touch(now);
  }

  /// Adds a set to an exercise, optionally reordering to before [beforeIndex].
  ActiveSession addSet(
    int exerciseIndex,
    WorkoutSet set, {
    int? beforeIndex,
    DateTime? now,
  }) {
    if (exerciseIndex < 0 || exerciseIndex >= content.exercises.length) {
      return this;
    }
    final exercise = content.exercises[exerciseIndex];
    final sets = List<WorkoutSet>.of(exercise.sets);
    final index = beforeIndex == null || beforeIndex >= sets.length
        ? sets.length
        : beforeIndex.clamp(0, sets.length);
    sets.insert(index, set);
    var updated = copyWith(
      content: content.copyWith(
        exercises: _replaceExercise(exerciseIndex, exercise.copyWith(sets: sets)),
      ),
    );
    return now == null ? updated : updated.touch(now);
  }

  /// Removes a set from an exercise.
  ActiveSession removeSet(int exerciseIndex, int setIndex, {DateTime? now}) {
    if (exerciseIndex < 0 || exerciseIndex >= content.exercises.length) {
      return this;
    }
    final exercise = content.exercises[exerciseIndex];
    final sets = List<WorkoutSet>.of(exercise.sets);
    if (setIndex < 0 || setIndex >= sets.length) return this;
    sets.removeAt(setIndex);
    var updated = copyWith(
      content: content.copyWith(
        exercises: _replaceExercise(exerciseIndex, exercise.copyWith(sets: sets)),
      ),
    );
    return now == null ? updated : updated.touch(now);
  }

  /// Duplicates the set at [setIndex] in [exerciseIndex], inserted after it.
  ActiveSession duplicateSet(int exerciseIndex, int setIndex, DateTime now) {
    if (exerciseIndex < 0 || exerciseIndex >= content.exercises.length) {
      return this;
    }
    final exercise = content.exercises[exerciseIndex];
    final sets = List<WorkoutSet>.of(exercise.sets);
    if (setIndex < 0 || setIndex >= sets.length) return this;
    final source = sets[setIndex];
    sets.insert(
      setIndex + 1,
      source.copyWith(id: generateId(), completed: false, timestamp: null),
    );
    return copyWith(
      content: content.copyWith(
        exercises: _replaceExercise(exerciseIndex, exercise.copyWith(sets: sets)),
      ),
    ).touch(now);
  }

  /// Moves the set at [from] so it sits at [to].
  ActiveSession reorderSet(int exerciseIndex, int from, int to, DateTime now) {
    if (exerciseIndex < 0 || exerciseIndex >= content.exercises.length) {
      return this;
    }
    final exercise = content.exercises[exerciseIndex];
    final sets = List<WorkoutSet>.of(exercise.sets);
    if (from < 0 || from >= sets.length || to < 0 || to >= sets.length) {
      return this;
    }
    final moved = sets.removeAt(from);
    sets.insert(to, moved);
    return copyWith(
      content: content.copyWith(
        exercises: _replaceExercise(exerciseIndex, exercise.copyWith(sets: sets)),
      ),
    ).touch(now);
  }

  /// Adds a new exercise to the session.
  ActiveSession addExercise(WorkoutExercise exercise, {DateTime? now}) {
    final updated = copyWith(
      content: content.copyWith(
        exercises: [
          ...content.exercises,
          exercise.copyWith(order: content.exercises.length),
        ],
      ),
    );
    return now == null ? updated : updated.touch(now);
  }

  /// Removes an exercise from the session.
  ActiveSession removeExercise(int exerciseIndex, {DateTime? now}) {
    if (exerciseIndex < 0 || exerciseIndex >= content.exercises.length) {
      return this;
    }
    final remaining = List.of(content.exercises)..removeAt(exerciseIndex);
    final reordered = [
      for (var i = 0; i < remaining.length; i++)
        remaining[i].copyWith(order: i),
    ];
    final focusIndex = reordered.isEmpty
        ? 0
        : ui.currentExerciseIndex.clamp(0, reordered.length - 1);
    var updated = copyWith(
      content: content.copyWith(exercises: reordered),
      ui: ui.copyWith(currentExerciseIndex: focusIndex),
    );
    if (ui.restEndsAt > 0) updated = updated.skipRest();
    return now == null ? updated : updated.touch(now);
  }

  /// Moves an exercise to a new position within the session.
  ActiveSession reorderExercise(int from, int to, DateTime now) {
    if (from < 0 || from >= content.exercises.length) return this;
    if (to < 0 || to >= content.exercises.length) return this;
    final exercises = List.of(content.exercises);
    final moved = exercises.removeAt(from);
    exercises.insert(to, moved);
    return copyWith(
      content: content.copyWith(
        exercises: [
          for (var i = 0; i < exercises.length; i++)
            exercises[i].copyWith(order: i),
        ],
      ),
    ).touch(now);
  }

  /// Updates session notes.
  ActiveSession updateNotes(String notes, DateTime now) {
    return copyWith(
      content: content.copyWith(notes: notes, updatedAt: now),
    ).touch(now);
  }

  /// Updates the session display name.
  ActiveSession updateName(String name, DateTime now) {
    return copyWith(
      content: content.copyWith(name: name, updatedAt: now),
    ).touch(now);
  }

  /// Marks the rest timer as finished when it has elapsed.
  ///
  /// Called after restoring a session so an expired rest timer does not keep
  /// the UI in the "resting" state.
  ActiveSession expireRestIfElapsed(DateTime now) {
    if (ui.restEndsAt > 0 &&
        !ui.restPaused &&
        now.millisecondsSinceEpoch >= ui.restEndsAt) {
      return skipRest();
    }
    return this;
  }

  /// Toggles the warm-up reminder flag for the exercise instance [id].
  ActiveSession toggleWarmup(String id, {DateTime? now}) {
    final ids = List.of(ui.warmupExerciseIds);
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    var updated = copyWith(ui: ui.copyWith(warmupExerciseIds: ids));
    return now == null ? updated : updated.touch(now);
  }

  /// Whether the exercise instance [id] is flagged for warm-up sets.
  bool warmupEnabled(String id) => ui.warmupExerciseIds.contains(id);

  /// Inserts two warm-up sets before the working sets of every exercise that
  /// was flagged during preparation.
  ActiveSession insertWarmupSets(DateTime now) {
    final flagged = Set.of(ui.warmupExerciseIds);
    if (flagged.isEmpty) return this;
    final exercises = <WorkoutExercise>[];
    for (final exercise in content.exercises) {
      if (!flagged.contains(exercise.id) || exercise.sets.isEmpty) {
        exercises.add(exercise);
        continue;
      }
      final first = exercise.sets.first;
      final warmups = [
        for (var i = 0; i < warmupSetCount; i++)
          WorkoutSet(
            weight: (first.weight * 0.5).roundToDouble(),
            reps: 8,
            restSeconds: 60,
            completed: false,
            isWarmup: true,
            tempo: first.tempo,
            notes: 'Warm-up',
          ),
      ];
      exercises.add(exercise.copyWith(sets: [...warmups, ...exercise.sets]));
    }
    return copyWith(
      content: content.copyWith(exercises: exercises),
      ui: ui.copyWith(warmupExerciseIds: const []),
    ).touch(now);
  }

  /// Builds the final, completed [WorkoutSession] record as of [now].
  ///
  /// Renumbers exercise order, stamps the duration and volume, and marks the
  /// session completed only when at least one set was actually performed.
  WorkoutSession toFinalSession(DateTime now) {
    final exercises = [
      for (var i = 0; i < content.exercises.length; i++)
        content.exercises[i].copyWith(order: i),
    ];
    return content.copyWith(
      exercises: exercises,
      completed: hasCompletedSets,
      volume: volume,
      durationMinutes: elapsedAt(now).inMinutes,
      updatedAt: now,
    );
  }

  List<WorkoutExercise> _replaceExercise(int index, WorkoutExercise replacement) {
    final list = List<WorkoutExercise>.of(content.exercises);
    list[index] = replacement;
    return list;
  }

  @override
  List<Object?> get props => [content, ui];
}
