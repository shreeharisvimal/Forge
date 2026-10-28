// Domain tests for the workout session engine.
//
// Covers the immutable [ActiveSession] model: building the preparation
// session, warm-up insertion, set/exercise mutations, the rest and session
// timers, and finalization. Pure Dart — no Hive or widgets.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/workout_session/domain/session_models.dart';
import 'package:forge/features/workout_session/domain/session_preparation.dart';
import 'package:forge/models/workout_set.dart';

final _now = DateTime(2026, 2, 4, 12, 0);

ActiveExercisePlan _plan({
  String id = 'e1',
  String name = 'Bench Press',
  int targetSets = 3,
  int targetReps = 8,
  int restSeconds = 90,
  double prefillWeight = 60,
  bool warmup = false,
}) =>
    ActiveExercisePlan(
      exerciseId: id,
      exerciseName: name,
      targetSets: targetSets,
      targetReps: targetReps,
      restSeconds: restSeconds,
      prefillWeight: prefillWeight,
      warmup: warmup,
    );

ActiveSession _preparationSession() =>
    ActiveSessionBuilder.fromPlans(
      name: 'Push day',
      now: _now,
      plans: [
        _plan(),
        _plan(id: 'e2', name: 'Overhead Press', targetSets: 2, prefillWeight: 40),
      ],
    );

void main() {
  group('ActiveSessionBuilder', () {
    test('builds a preparation-stage session from plans', () {
      final session = _preparationSession();
      expect(session.stage, SessionStage.preparation);
      expect(session.content.startedAt, isNull);
      expect(session.name, 'Push day');
      expect(session.content.exercises, hasLength(2));
      expect(session.content.exercises.first.sets, hasLength(3));
      expect(session.content.exercises.first.sets.first.weight, 60);
      expect(session.content.exercises.last.sets, hasLength(2));
      expect(session.hasSets, isTrue);
    });

    test('records warm-up flags without creating warm-up sets yet', () {
      final session = ActiveSessionBuilder.fromPlans(
        name: 'Warm',
        now: _now,
        plans: [_plan(warmup: true)],
      );
      expect(session.warmupEnabled(session.content.exercises.first.id), isTrue);
      expect(session.content.exercises.first.sets.every((s) => !s.isWarmup), isTrue);
    });

    test('an empty plan list yields an empty free-form workout', () {
      final session = ActiveSessionBuilder.fromPlans(
        name: 'Free',
        now: _now,
        plans: const [],
      );
      expect(session.content.exercises, isEmpty);
      expect(session.hasSets, isFalse);
    });
  });

  group('warm-up insertion', () {
    test('inserts two warm-up sets before the working sets on start', () {
      final session = ActiveSessionBuilder.fromPlans(
        name: 'Warm',
        now: _now,
        plans: [_plan(prefillWeight: 100, targetReps: 5, warmup: true)],
      );
      final started = session.insertWarmupSets(_now);
      final sets = started.content.exercises.first.sets;
      expect(sets, hasLength(5));
      expect(sets[0].isWarmup, isTrue);
      expect(sets[1].isWarmup, isTrue);
      expect(sets[0].weight, 50);
      expect(sets[0].reps, 8);
      expect(sets[2].isWarmup, isFalse);
      expect(sets[2].weight, 100);
      expect(started.ui.warmupExerciseIds, isEmpty);
    });

    test('is a no-op when no exercise is flagged', () {
      final session = _preparationSession();
      expect(identical(session.insertWarmupSets(_now), session), isTrue);
    });
  });

  group('rest timer', () {
    test('start/pause/resume/skip updates the deadline and remaining', () {
      var session = _preparationSession();
      final deadline = _now.add(const Duration(seconds: 90));
      session = session.startRest(const Duration(seconds: 90), _now);
      expect(session.isRestActive, isTrue);
      expect(session.ui.restDeadline, deadline);
      expect(session.restRemainingMsAt(_now), 90 * 1000);

      session = session.pauseRest(_now.add(const Duration(seconds: 30)));
      expect(session.ui.restPaused, isTrue);
      expect(session.restRemainingMsAt(_now.add(const Duration(seconds: 999))),
          60 * 1000);

      session = session.resumeRest(_now.add(const Duration(seconds: 45)));
      expect(session.ui.restPaused, isFalse);
      expect(session.ui.restEndsAt, _now.add(const Duration(seconds: 105)).millisecondsSinceEpoch);

      session = session.skipRest();
      expect(session.isRestActive, isFalse);
    });

    test('expireRestIfElapsed clears an elapsed rest timer', () {
      var session = _preparationSession().startRest(
        const Duration(seconds: 30),
        _now,
      );
      session = session.expireRestIfElapsed(_now.add(const Duration(seconds: 31)));
      expect(session.isRestActive, isFalse);
    });

    test('expireRestIfElapsed keeps a running timer unchanged', () {
      final session = _preparationSession().startRest(
        const Duration(seconds: 30),
        _now,
      );
      final before = session.restRemainingMsAt(_now);
      final kept = session.expireRestIfElapsed(_now.add(const Duration(seconds: 5)));
      expect(kept, same(session));
      expect(kept.restRemainingMsAt(_now), before);
    });
  });

  group('session timer', () {
    test('pause freezes elapsed time and resume keeps counting', () {
      final start = DateTime(2026, 2, 4, 12, 0);
      var session = _preparationSession()
          .copyWith(
            content: _preparationSession().content.copyWith(
                  startedAt: () => start,
                ),
            ui: _preparationSession()
                .ui.copyWith(stage: SessionStage.active),
          )
          .startRest(const Duration(seconds: 30), start);

      expect(session.elapsedMsAt(start.add(const Duration(seconds: 10))), 10 * 1000);

      session = session.pauseTimer(start.add(const Duration(seconds: 20)));
      expect(session.isTimerPaused, isTrue);
      expect(session.elapsedMsAt(start.add(const Duration(hours: 1))), 20 * 1000);

      session = session.resumeTimer(start.add(const Duration(seconds: 50)));
      expect(session.isTimerPaused, isFalse);
      expect(session.elapsedMsAt(start.add(const Duration(seconds: 60))), 30 * 1000);
    });
  });

  group('set mutations', () {
    test('updateSet replaces a set and touch stamps the session', () {
      var session = _preparationSession();
      final updatedSet = session.content.exercises[0].sets[0].copyWith(
        weight: 70,
        reps: 6,
        completed: true,
      );
      session = session.updateSet(0, 0, updatedSet, _now);
      expect(session.content.exercises[0].sets[0].weight, 70);
      expect(session.completedSets, 1);
      expect(session.totalReps, 6);
      expect(session.volume, 420);
    });

    test('add/duplicate/delete/reorder sets operate on the right exercise', () {
      var session = _preparationSession();
      session = session.addSet(
        1,
        WorkoutSet(weight: 30, reps: 12, restSeconds: 60),
        now: _now,
      );
      expect(session.content.exercises[1].sets, hasLength(3));
      expect(session.content.exercises[0].sets, hasLength(3));

      session = session.duplicateSet(1, 0, _now);
      expect(session.content.exercises[1].sets, hasLength(4));

      session = session.reorderSet(1, 0, 2, _now);
      expect(session.content.exercises[1].sets.first.weight, 40);

      session = session.removeSet(1, 0, now: _now);
      expect(session.content.exercises[1].sets, hasLength(3));
    });

    test('out-of-range set ops are ignored', () {
      final session = _preparationSession();
      expect(identical(session.updateSet(9, 0, session.content.exercises[0].sets[0], _now), session), isTrue);
      expect(identical(session.removeSet(0, 99, now: _now), session), isTrue);
    });
  });

  group('exercise mutations', () {
    test('add/remove/reorder exercises maintains order metadata', () {
      var session = _preparationSession();
      session = session.addExercise(
        _preparationSession().content.exercises.first,
        now: _now,
      );
      expect(session.content.exercises, hasLength(3));
      expect(session.content.exercises.last.order, 2);

      session = session.reorderExercise(0, 2, _now);
      expect(session.content.exercises[2].exerciseName, 'Bench Press');
      expect(session.content.exercises.every((e) => e.order >= 0), isTrue);

      session = session.removeExercise(2, now: _now);
      expect(session.content.exercises, hasLength(2));
      expect(session.ui.currentExerciseIndex, 0);
    });
  });

  group('finalization', () {
    test('toFinalSession stamps completion, volume and duration', () {
      var session = _preparationSession();
      session = session
          .copyWith(
            content: session.content.copyWith(startedAt: () => _now),
            ui: session.ui.copyWith(stage: SessionStage.active),
          )
          .updateSet(
            0,
            0,
            session.content.exercises[0].sets[0].copyWith(
              weight: 80,
              reps: 5,
              completed: true,
            ),
            _now.add(const Duration(minutes: 40)),
          );
      final finalSession = session.toFinalSession(_now.add(const Duration(minutes: 45)));
      expect(finalSession.completed, isTrue);
      expect(finalSession.volume, 400);
      expect(finalSession.durationMinutes, 45);
      expect(finalSession.exercises.first.order, 0);
    });

    test('a session without completed sets finalizes as incomplete', () {
      final finalSession = _preparationSession().toFinalSession(_now);
      expect(finalSession.completed, isFalse);
    });
  });

  group('SessionUiState serialization', () {
    test('toMap/fromMap round-trips every field', () {
      final ui = SessionUiState(
        stage: SessionStage.active,
        currentExerciseIndex: 2,
        restEndsAt: 12345,
        restPaused: true,
        restRemainingMs: 9000,
        restTotalMs: 90000,
        isTimerPaused: true,
        pausedMs: 5000,
        pausedElapsedMs: 30000,
        lastTouchedMs: 42,
        warmupExerciseIds: ['a', 'b'],
      );
      expect(SessionUiState.fromMap(ui.toMap()), ui);
    });

    test('unknown stage falls back to preparation', () {
      final ui = SessionUiState.fromMap({'stage': 'not_a_stage'});
      expect(ui.stage, SessionStage.preparation);
    });
  });

  group('navigation', () {
    test('focusExercise clamps to valid range and cancels rest', () {
      var session = _preparationSession().startRest(
        const Duration(seconds: 30),
        _now,
      );
      session = session.focusExercise(99, now: _now);
      expect(session.ui.currentExerciseIndex, 1);
      expect(session.isRestActive, isFalse);
    });

    test('isLastExercise reflects the final exercise', () {
      final session = _preparationSession();
      expect(session.isLastExercise, isFalse);
      expect(session.copyWith(ui: session.ui.copyWith(currentExerciseIndex: 1)).isLastExercise, isTrue);
    });
  });
}
