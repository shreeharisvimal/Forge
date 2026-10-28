// Tests for the PR engine.
//
// Verifies detection of the records a finished session produced: first-ever
// events, lifetime beats with previous values, no-op sessions and the
// guarantee that evaluation never mutates the event timeline by itself.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/prs/data/pr_event_repository.dart';
import 'package:forge/features/prs/domain/one_rep_max.dart';
import 'package:forge/features/prs/domain/pr_engine.dart';
import 'package:forge/features/prs/domain/pr_types.dart';
import 'package:forge/models/personal_record.dart';
import 'package:forge/models/workout_exercise.dart';
import 'package:forge/models/workout_session.dart';
import 'package:forge/models/workout_set.dart';
import 'package:forge/services/repositories/personal_record_repository.dart';

import '../../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;
  late PrEngine engine;
  late PersonalRecordRepository records;
  late PrEventRepository events;

  final date = DateTime(2026, 2, 4, 12);

  setUp(() async {
    env = await HiveTestEnv.create();
    records = HivePersonalRecordRepository(env.databaseService.prBox);
    events = HivePrEventRepository(env.databaseService.prEventsBox);
    engine = PrEngine(
      personalRecordRepository: records,
      prEventRepository: events,
    );
  });

  tearDown(() => env.dispose());
  WorkoutSession session({
    DateTime? at,
    List<WorkoutSet>? sets,
  }) {
    return WorkoutSession(
      date: at ?? date,
      exercises: [
        WorkoutExercise(
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          sets: sets ??
              [
                WorkoutSet(weight: 100, reps: 5, completed: true),
              ],
        ),
      ],
    );
  }

  test('a fresh session produces first-ever events for every record type', () {
    final performed = session();
    final result = engine.evaluateSession(performed);

    final types = result.map((e) => e.prType).toSet();
    expect(types, {
      PrType.heaviestWeight,
      PrType.mostReps,
      PrType.estimatedOneRM,
      PrType.bestVolume,
    });

    final event = result.firstWhere((e) => e.prType == PrType.heaviestWeight);
    expect(event.exerciseId, 'bench');
    expect(event.exerciseName, 'Bench Press');
    expect(event.previousValue, 0);
    expect(event.date, date);
    expect(event.workoutId, performed.id);
    expect(event.formula, OneRepMaxFormula.epley.storageKey);
    expect(event.calculatedOneRM, closeTo(116.667, 0.001));
  });

  test('evaluation never writes to the event timeline', () {
    engine.evaluateSession(session());
    expect(events.count, 0);
  });

  test('beating the stored record emits lifetime events with previous values',
      () async {
    await records.save(
      PersonalRecord(
        exerciseId: 'bench',
        highestWeight: 90,
        bestReps: 5,
        estimatedOneRM: 108,
        bestVolume: 450,
      ),
    );

    final result = engine.evaluateSession(session());

    final heaviest =
        result.firstWhere((e) => e.prType == PrType.heaviestWeight);
    expect(heaviest.value, 100);
    expect(heaviest.previousValue, 90);

    final volume = result.firstWhere((e) => e.prType == PrType.bestVolume);
    expect(volume.previousValue, 450);
  });

  test('matching the stored record is not a new PR', () async {
    await records.save(
      PersonalRecord(
        exerciseId: 'bench',
        highestWeight: 100,
        bestReps: 5,
        estimatedOneRM: 116.667,
        bestVolume: 500,
      ),
    );

    final result = engine.evaluateSession(session());
    expect(result, isEmpty);
  });

  test('a session without completed sets produces nothing', () {
    final result = engine.evaluateSession(
      session(sets: [WorkoutSet(weight: 100, reps: 5)]),
    );
    expect(result, isEmpty);
  });

  test('the formula changes the estimated one-rep-max events', () {
    final epley = engine.evaluateSession(session());
    final brzycki = engine.evaluateSession(
      session(),
      formula: OneRepMaxFormula.brzycki,
    );

    final epleyRM = epley.firstWhere((e) => e.prType == PrType.estimatedOneRM);
    final brzyckiRM =
        brzycki.firstWhere((e) => e.prType == PrType.estimatedOneRM);
    // 100kg x 5: Epley = 116.67, Brzycki = 112.5.
    expect(epleyRM.value, closeTo(116.667, 0.001));
    expect(brzyckiRM.value, closeTo(112.5, 0.001));
    expect(epleyRM.formula, OneRepMaxFormula.epley.storageKey);
    expect(brzyckiRM.formula, OneRepMaxFormula.brzycki.storageKey);
  });
}
