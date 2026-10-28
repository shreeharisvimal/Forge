// Tests for the ActiveSessionController provider.
//
// Exercises the full controller API against a real temp-dir Hive store with a
// pinned clock: lifecycle, set completion auto-rest, debounced autosave and
// finalization side effects.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/workout_session/data/active_session_store.dart';
import 'package:forge/features/workout_session/domain/session_models.dart';
import 'package:forge/features/workout_session/domain/session_preparation.dart';
import 'package:forge/features/workout_session/providers/session_providers.dart';
import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_set.dart';
import 'package:forge/services/providers.dart';
import 'package:forge/services/repositories/workout_session_repository.dart';

import '../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;
  late ProviderContainer container;
  var now = DateTime(2026, 2, 4, 12, 0);

  setUp(() async {
    env = await HiveTestEnv.create();
    now = DateTime(2026, 2, 4, 12, 0);
    container = ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(env.databaseService),
        sessionNowProvider.overrideWith((ref) => now),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() => env.dispose());

  ActiveSessionController controller() =>
      container.read(activeSessionProvider.notifier);

  ActiveSession? currentSession() => container.read(activeSessionProvider).value;

  Future<void> open() => controller().openSession(
        name: 'Push day',
        plans: [
          ActiveExercisePlan(
            exerciseId: 'bench',
            exerciseName: 'Bench Press',
            targetSets: 3,
            targetReps: 8,
            prefillWeight: 60,
            restSeconds: 90,
          ),
        ],
      );

  Future<ActiveSessionStore> freshStore() async => ActiveSessionStore(
        env.databaseService,
      );

  group('lifecycle', () {
    test('opens a preparation session and persists it', () async {
      expect(await container.read(activeSessionProvider.future), isNull);
      await open();

      expect(currentSession(), isNotNull);
      expect(currentSession()!.stage, SessionStage.preparation);
      expect(currentSession()!.content.exercises, hasLength(1));
      expect(currentSession()!.content.startedAt, isNull);

      await controller().flushSave();
      expect((await (await freshStore()).load())!.name, 'Push day');
    });

    test('openSession is a no-op when a session already exists', () async {
      await open();
      final current = currentSession();
      await controller().openSession(
        name: 'Ignored',
        plans: const [],
      );
      expect(currentSession(), current);
    });

    test('start transitions to active and stamps startedAt', () async {
      await open();
      await controller().start();

      expect(currentSession()!.stage, SessionStage.active);
      expect(currentSession()!.content.startedAt, isNotNull);
    });

    test('finish finalizes, persists history and enters the summary stage',
        () async {
      await open();
      await controller().start();
      controller().updateSet(
        0,
        0,
        currentSession()!.content.exercises[0].sets[0].copyWith(
          completed: true,
          timestamp: now,
        ),
      );

      final finalized = await controller().finish();
      expect(finalized, isNotNull);
      expect(finalized!.completed, isTrue);
      expect(currentSession()!.stage, SessionStage.summary);

      final store = await freshStore();
      expect(store.peek(), isNull);
      final sessions = HiveWorkoutSessionRepository(env.databaseService.sessionBox);
      expect(sessions.recent(10), hasLength(1));
    });

    test('abandon discards the session and store', () async {
      await open();
      await controller().abandon();

      expect(currentSession(), isNull);
      expect((await freshStore()).peek(), isNull);
    });
  });

  group('sets and rest', () {
    test('completing a non-final set auto-starts the rest timer', () async {
      await open();
      await controller().start();
      controller().updateSet(
        0,
        0,
        currentSession()!.content.exercises[0].sets[0].copyWith(
          completed: true,
          reps: 8,
          timestamp: now,
        ),
      );

      expect(currentSession()!.completedSets, 1);
      expect(currentSession()!.isRestActive, isTrue);
      expect(currentSession()!.ui.restTotalMs, 90 * 1000);
    });

    test('completing the final set does not start rest', () async {
      await open();
      await controller().start();
      controller().updateSet(
        0,
        2,
        currentSession()!.content.exercises[0].sets[2].copyWith(
          completed: true,
          timestamp: now,
        ),
      );
      expect(currentSession()!.isRestActive, isFalse);
    });

    test('un-completing a set cancels the rest timer', () async {
      await open();
      await controller().start();
      final original = currentSession()!.content.exercises[0].sets[0];
      final completed = original.copyWith(
        completed: true,
        timestamp: now,
      );
      controller().updateSet(0, 0, completed);
      expect(currentSession()!.isRestActive, isTrue);

      controller().updateSet(0, 0, original);
      expect(currentSession()!.isRestActive, isFalse);
    });

    test('rest timer controls pause/resume/skip', () async {
      await open();
      await controller().start();
      controller().updateSet(
        0,
        0,
        currentSession()!.content.exercises[0].sets[0].copyWith(
          completed: true,
          timestamp: now,
        ),
      );
      controller().pauseRest();
      expect(currentSession()!.ui.restPaused, isTrue);
      controller().resumeRest();
      expect(currentSession()!.ui.restPaused, isFalse);
      controller().skipRest();
      expect(currentSession()!.isRestActive, isFalse);
    });

    test('mutations autosave after the debounce window', () async {
      await open();
      await controller().start();
      controller().updateSet(
        0,
        0,
        currentSession()!.content.exercises[0].sets[0].copyWith(
          completed: true,
          timestamp: now,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 600));
      final loaded = (await (await freshStore()).load())!;
      expect(loaded.completedSets, 1);
      expect(loaded.content.startedAt, isNotNull);
    });
  });

  group('exercises and metadata', () {
    test('add/focus/next exercise navigates the session', () async {
      await open();
      await controller().start();
      controller().addExercise(
        WorkoutExercise(
          exerciseId: 'row',
          exerciseName: 'Barbell Row',
          sets: [
            WorkoutSet(weight: 50, reps: 10, restSeconds: 90),
          ],
        ),
      );
      expect(currentSession()!.content.exercises, hasLength(2));

      controller().focusExercise(1);
      expect(currentSession()!.ui.currentExerciseIndex, 1);
      expect(currentSession()!.isLastExercise, isTrue);

      controller().nextExercise();
      expect(currentSession()!.ui.currentExerciseIndex, 1);
    });

    test('updateSessionName and updateSessionNotes persist', () async {
      await open();
      controller().updateSessionName('Renamed');
      controller().updateSessionNotes('Feeling strong');

      expect(currentSession()!.name, 'Renamed');
      expect(currentSession()!.content.notes, 'Feeling strong');

      await controller().flushSave();
      final loaded = (await (await freshStore()).load())!;
      expect(loaded.name, 'Renamed');
      expect(loaded.content.notes, 'Feeling strong');
    });

    test('toggleWarmup then start inserts warm-up sets', () async {
      await open();
      final exerciseId = currentSession()!.content.exercises[0].id;
      controller().toggleWarmup(exerciseId);
      expect(currentSession()!.warmupEnabled(exerciseId), isTrue);

      await controller().start();
      final sets = currentSession()!.content.exercises[0].sets;
      expect(sets.where((set) => set.isWarmup), hasLength(2));
      expect(sets.first.isWarmup, isTrue);
    });

    test('deleteSet and duplicateSet change the set count', () async {
      await open();
      controller().duplicateSet(0, 0);
      expect(currentSession()!.content.exercises[0].sets, hasLength(4));
      controller().deleteSet(0, 0);
      expect(currentSession()!.content.exercises[0].sets, hasLength(3));
    });

    test('restored session keeps an elapsed rest timer until expiry', () async {
      await open();
      await controller().start();
      controller().updateSet(
        0,
        0,
        currentSession()!.content.exercises[0].sets[0].copyWith(
          completed: true,
          timestamp: now,
        ),
      );
      await controller().flushSave();

      // A fresh container simulates an app restart; the clock has advanced
      // past the deadline, so the timer is cleared on load.
      now = now.add(const Duration(minutes: 2));
      final restarted = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(env.databaseService),
          sessionNowProvider.overrideWith((ref) => now),
        ],
      );
      addTearDown(restarted.dispose);
      final restored = await restarted.read(activeSessionProvider.future);
      expect(restored, isNotNull);
      expect(restored!.stage, SessionStage.active);
      expect(restored.isRestActive, isFalse);
    });
  });
}
