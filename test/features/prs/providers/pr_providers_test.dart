// Tests for the PR feature providers.
//
// Verifies the configured formula provider, the composite strength-score
// provider against a real Hive environment, and the celebration controller
// queue lifecycle.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/prs/data/pr_event.dart';
import 'package:forge/features/prs/domain/one_rep_max.dart';
import 'package:forge/features/prs/domain/pr_types.dart';
import 'package:forge/features/prs/providers/pr_providers.dart';
import 'package:forge/models/personal_record.dart';
import 'package:forge/models/settings_model.dart';
import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_session.dart';
import 'package:forge/models/workout_set.dart';
import 'package:forge/services/providers.dart';
import 'package:forge/services/repositories/personal_record_repository.dart';
import 'package:forge/services/repositories/settings_repository.dart';
import 'package:forge/services/repositories/workout_session_repository.dart';

import '../../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;
  late ProviderContainer container;

  setUp(() async {
    env = await HiveTestEnv.create();
    container = ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(env.databaseService),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() => env.dispose());

  group('prFormulaProvider', () {
    test('defaults to epley on a fresh install', () {
      expect(container.read(prFormulaProvider), OneRepMaxFormula.epley);
    });

    test('reads the configured formula from settings', () async {
      final settings = HiveSettingsRepository(env.databaseService.settingsBox);
      await settings.replace(SettingsModel(oneRepMaxFormula: 'brzycki'));

      expect(container.read(prFormulaProvider), OneRepMaxFormula.brzycki);
    });
  });

  group('strengthScoreProvider', () {
    test('aggregates records and sessions from the repositories', () async {
      final records = HivePersonalRecordRepository(env.databaseService.prBox);
      await records.save(
        PersonalRecord(
          exerciseId: 'bench',
          estimatedOneRM: 116.7,
          highestWeight: 100,
          bestReps: 5,
        ),
      );

      final sessions =
          HiveWorkoutSessionRepository(env.databaseService.sessionBox);
      await sessions.save(
        WorkoutSession(
          date: DateTime.now(),
          exercises: [
            WorkoutExercise(
              exerciseId: 'bench',
              exerciseName: 'Bench Press',
              sets: [
                WorkoutSet(weight: 100, reps: 5, completed: true),
              ],
            ),
          ],
        ),
      );

      final score = container.read(strengthScoreProvider);
      expect(score.hasData, isTrue);
      expect(score.exercises, 1);
      expect(score.totalOneRM, closeTo(116.7, 0.001));
      expect(score.bestOneRM, closeTo(116.7, 0.001));
      // No body weight recorded -> no ratio and no DOTS / Wilks.
      expect(score.bodyweightRatio, 0);
      expect(score.dots, isNull);
      expect(score.wilks, isNull);
    });

    test('reports no data before any training exists', () {
      final score = container.read(strengthScoreProvider);
      expect(score.hasData, isFalse);
    });
  });

  group('prCelebrationProvider', () {
    PrEvent event() => PrEvent(
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          type: PrType.heaviestWeight.name,
          value: 100,
        );

    test('queues the events of a finished session', () {
      final notifier = container.read(prCelebrationProvider.notifier);
      expect(container.read(prCelebrationProvider), isEmpty);

      notifier.celebrate([event(), event()]);
      expect(container.read(prCelebrationProvider), hasLength(2));

      notifier.celebrate([event()]);
      expect(container.read(prCelebrationProvider), hasLength(1));
    });

    test('an empty result replaces the queue rather than keeping stale events',
        () {
      final notifier = container.read(prCelebrationProvider.notifier);
      notifier.celebrate([event()]);
      notifier.celebrate(const []);
      expect(container.read(prCelebrationProvider), isEmpty);
    });

    test('dismiss clears the queue', () {
      final notifier = container.read(prCelebrationProvider.notifier);
      notifier.celebrate([event()]);
      notifier.dismiss();
      expect(container.read(prCelebrationProvider), isEmpty);
    });
  });
}
