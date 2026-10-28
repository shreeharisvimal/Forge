// Tests for the session lifecycle service.
//
// Verifies finishing moves an in-progress workout into permanent history,
// stamps exercise history / personal records / the calendar day and usage,
// and abandoning discards everything without side effects.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/database/database_service.dart';
import 'package:forge/features/workout_session/data/active_session_store.dart';
import 'package:forge/features/workout_session/domain/session_models.dart';
import 'package:forge/features/workout_session/domain/session_preparation.dart';
import 'package:forge/features/workout_session/services/session_service.dart';
import 'package:forge/services/repositories/calendar_repository.dart';
import 'package:forge/services/repositories/exercise_history_repository.dart';
import 'package:forge/services/repositories/exercise_repository.dart';
import 'package:forge/services/repositories/personal_record_repository.dart';
import 'package:forge/services/repositories/workout_session_repository.dart';

import '../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;
  late DatabaseService db;
  late SessionService service;
  late WorkoutSessionRepository sessions;
  late ExerciseHistoryRepository history;
  late PersonalRecordRepository records;
  late CalendarRepository calendar;

  final now = DateTime(2026, 2, 4, 12, 0);

  setUp(() async {
    env = await HiveTestEnv.create();
    db = env.databaseService;
    sessions = HiveWorkoutSessionRepository(db.sessionBox);
    history = HiveExerciseHistoryRepository(db.historyBox);
    records = HivePersonalRecordRepository(db.prBox);
    calendar = HiveCalendarRepository(db.calendarBox);
    service = SessionService(
      store: ActiveSessionStore(db),
      workoutSessionRepository: sessions,
      exerciseHistoryRepository: history,
      personalRecordRepository: records,
      calendarRepository: calendar,
      exerciseRepository: HiveExerciseRepository(db.exerciseBox),
    );
  });

  tearDown(() => env.dispose());

  ActiveSession buildPreparation() => ActiveSessionBuilder.fromPlans(
        name: 'Push day',
        now: now,
        plans: [
          ActiveExercisePlan(
            exerciseId: 'bench',
            exerciseName: 'Bench Press',
            targetSets: 1,
            targetReps: 5,
            prefillWeight: 80,
            restSeconds: 120,
          ),
        ],
      );

  ActiveSession completedSession() {
    final session = buildPreparation().copyWith(
      content: buildPreparation().content.copyWith(startedAt: () => now),
      ui: buildPreparation().ui.copyWith(stage: SessionStage.active),
    );
    return session.updateSet(
      0,
      0,
      session.content.exercises[0].sets[0].copyWith(
        weight: 82.5,
        reps: 6,
        rpe: () => 8,
        completed: true,
        timestamp: now,
      ),
      now.add(const Duration(minutes: 30)),
    );
  }

  test('finish persists the session and stamps history, record and calendar',
      () async {
    final finalized = await service.finish(completedSession(), now.add(const Duration(minutes: 30)));

    expect(finalized.completed, isTrue);
    expect(finalized.volume, 495);
    expect(sessions.recent(1), hasLength(1));

    final day = history.onDate('bench', now);
    expect(day, isNotNull);
    expect(day!.bestWeight, 82.5);
    expect(day.bestReps, 6);
    expect(day.totalVolume, 495);

    final record = records.forExercise('bench');
    expect(record, isNotNull);
    expect(record!.highestWeight, 82.5);
    expect(record.bestReps, 6);
    expect(record.estimatedOneRM, greaterThan(82.5));

    final dayRow = calendar.onDate(now);
    expect(dayRow, isNotNull);
    expect(dayRow!.workoutCompleted, isTrue);
    expect(dayRow.durationMinutes, 30);
  });

  test('finish clears the active-session box', () async {
    final store = ActiveSessionStore(db);
    await store.save(completedSession());
    await service.finish(completedSession(), now.add(const Duration(minutes: 30)));
    expect(store.peek(), isNull);
    expect(await store.load(), isNull);
  });

  test('finishing an empty session records it but touches no aggregates',
      () async {
    final empty = ActiveSessionBuilder.fromPlans(
      name: 'Scratch',
      now: now,
      plans: const [],
    );
    final finalized = await service.finish(empty, now);

    expect(finalized.completed, isFalse);
    expect(sessions.recent(1), hasLength(1));
    expect(history.forExercise('bench'), isEmpty);
    expect(records.forExercise('bench'), isNull);
    expect(calendar.onDate(now), isNull);
  });

  test('finish merges into existing history and calendar rows', () async {
    await service.finish(completedSession(), now.add(const Duration(minutes: 30)));
    await service.finish(completedSession(), now.add(const Duration(minutes: 30)));

    final day = history.onDate('bench', now);
    expect(day!.totalVolume, 990);
    expect(day.bestWeight, 82.5);

    final dayRow = calendar.onDate(now);
    expect(dayRow!.durationMinutes, 30);
  });

  test('abandon clears the active session without recording it', () async {
    final store = ActiveSessionStore(db);
    await store.save(completedSession());

    await service.abandon();

    expect(store.peek(), isNull);
    expect(sessions.recent(1), isEmpty);
    expect(history.forExercise('bench'), isEmpty);
  });

  test('save/load delegates to the store', () async {
    final store = ActiveSessionStore(db);
    await service.save(completedSession());
    final loaded = await service.load();
    expect(loaded, isNotNull);
    expect(loaded!.name, 'Push day');
    await store.clear();
    expect(await service.load(), isNull);
  });
}
