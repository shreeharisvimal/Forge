// Tests for the active session store.
//
// Verifies the two-half persistence (content record + UI-state JSON) survives
// a round trip, is cleared correctly, and degrades gracefully on corruption.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/workout_session/data/active_session_store.dart';
import 'package:forge/features/workout_session/domain/session_models.dart';
import 'package:forge/features/workout_session/domain/session_preparation.dart';

import '../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;
  late ActiveSessionStore store;

  setUp(() async {
    env = await HiveTestEnv.create();
    store = ActiveSessionStore(env.databaseService);
  });

  tearDown(() => env.dispose());

  final now = DateTime(2026, 2, 4, 12, 0);

  ActiveSession buildSession() => ActiveSessionBuilder.fromPlans(
        name: 'Push day',
        now: now,
        plans: [
          ActiveExercisePlan(
            exerciseId: 'e1',
            exerciseName: 'Bench Press',
            targetSets: 2,
            targetReps: 8,
            prefillWeight: 60,
          ),
        ],
      );

  test('save/load round-trips the content and UI state', () async {
    final session = buildSession().startRest(const Duration(seconds: 90), now);
    await store.save(session);

    final loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.name, 'Push day');
    expect(loaded.content.exercises.first.exerciseName, 'Bench Press');
    expect(loaded.ui.stage, SessionStage.preparation);
    expect(loaded.ui.restEndsAt, session.ui.restEndsAt);
    expect(loaded.ui.restTotalMs, 90 * 1000);
  });

  test('load returns null when no session is in progress', () async {
    expect(await store.load(), isNull);
  });

  test('peek returns the stored content without the UI state', () async {
    await store.save(buildSession());
    expect(store.peek()?.name, 'Push day');
  });

  test('clear removes both halves', () async {
    await store.save(buildSession());
    await store.clear();
    expect(await store.load(), isNull);
    expect(store.peek(), isNull);
  });

  test('a corrupt UI-state document falls back to a fresh preparation state',
      () async {
    await store.save(buildSession());
    await env.databaseService.metaBox.put(ActiveSessionStore.uiStateKey, '{oops');
    final loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.content.exercises, hasLength(1));
    expect(loaded.ui.stage, SessionStage.preparation);
    expect(loaded.ui.restEndsAt, 0);
  });

  test('writes are observable through the same box wiring', () async {
    await store.save(buildSession());
    final box = env.databaseService.activeSessionBox;
    expect(box.get(ActiveSessionStore.activeSessionKey), isNotNull);
  });
}
