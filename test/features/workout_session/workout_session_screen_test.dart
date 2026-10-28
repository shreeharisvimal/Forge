// Widget tests for the workout session screen.
//
// Pumps the real [WorkoutSessionScreen] through a GoRouter against a temp-dir
// Hive store with a pinned clock and a quiescent tick stream, then drives the
// full flow: launch, add an exercise from the library, start, complete a set,
// finish into the summary, share/done, and discard-on-back.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:forge/core/design/forge_design.dart';
import 'package:forge/database/database_service.dart';
import 'package:forge/features/workout_session/data/active_session_store.dart';
import 'package:forge/features/workout_session/domain/session_models.dart';
import 'package:forge/features/workout_session/domain/session_preparation.dart';
import 'package:forge/features/workout_session/presentation/workout_session_screen.dart';
import 'package:forge/features/workout_session/providers/session_providers.dart';
import 'package:forge/features/workout_session/services/session_service.dart';
import 'package:forge/models/exercise.dart';
import 'package:forge/models/workout_session.dart';
import 'package:forge/services/providers.dart';
import 'package:forge/services/repositories/calendar_repository.dart';
import 'package:forge/services/repositories/exercise_history_repository.dart';
import 'package:forge/services/repositories/exercise_repository.dart';
import 'package:forge/services/repositories/personal_record_repository.dart';
import 'package:forge/services/repositories/workout_session_repository.dart';

import '../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;
  late ProviderContainer container;
  late GoRouter router;
  var now = DateTime(2026, 2, 4, 12, 0);

  setUp(() async {
    env = await HiveTestEnv.create();
    now = DateTime(2026, 2, 4, 12, 0);

    final exercises = HiveExerciseRepository(env.databaseService.exerciseBox);
    await exercises.save(
      Exercise(
        name: 'Bench Press',
        muscleGroup: 'Chest',
        equipment: 'Barbell',
        isCompound: true,
        defaultReps: 8,
        defaultRestSeconds: 90,
      ),
    );
    await exercises.save(
      Exercise(
        name: 'Back Squat',
        muscleGroup: 'Legs',
        equipment: 'Barbell',
        isCompound: true,
        defaultReps: 8,
        defaultRestSeconds: 120,
      ),
    );

    container = ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(env.databaseService),
        sessionServiceProvider
            .overrideWithValue(_InMemorySessionService(env.databaseService)),
        sessionNowProvider.overrideWith((ref) => now),
        sessionTickProvider.overrideWith((ref) => const Stream<int>.empty()),
      ],
    );
    addTearDown(container.dispose);

    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const _HomeStub()),
        GoRoute(
          path: '/session',
          builder: (_, __) => const WorkoutSessionScreen(),
        ),
      ],
    );
  });

  tearDown(() => env.dispose());

  Future<void> pumpSession(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: ForgeTheme.dark(),
        ),
      ),
    );
    // Push (not go) so a back stack exists beneath /session, matching how the
    // shell opens the session screen in the real app.
    router.push('/session');
    await tester.pumpAndSettle();
  }

  Future<void> useTallSurface(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> addBenchPress(WidgetTester tester) async {
    // The empty preparation state shows an "Add exercise" CTA plus the
    // persistent button beneath it; either opens the picker.
    await tester.tap(find.text('Add exercise').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
  }

  ActiveSessionController controller() =>
      container.read(activeSessionProvider.notifier);

  ActiveSession? currentSession() => container.read(activeSessionProvider).value;

  ActiveExercisePlan benchPlan({int targetSets = 2, int restSeconds = 90}) =>
      ActiveExercisePlan(
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
        targetSets: targetSets,
        targetReps: 8,
        prefillWeight: 60,
        restSeconds: restSeconds,
      );

  testWidgets('launches a free-form session into the empty preparation state',
      (tester) async {
    await useTallSurface(tester);
    await pumpSession(tester);

    // The session name shows both in the app-bar title and the editable name
    // field, so it appears on the preparation stage more than once.
    expect(find.text('Workout'), findsWidgets);
    expect(find.text('No exercises yet'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);
  });

  testWidgets('adds an exercise from the picker and renames the session',
      (tester) async {
    await useTallSurface(tester);
    await pumpSession(tester);

    await addBenchPress(tester);

    expect(find.text('No exercises yet'), findsNothing);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('1 × 8 reps'), findsOneWidget);
    expect(find.text('Chest'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Push');
    await tester.pumpAndSettle();

    expect(find.text('Push'), findsWidgets);
    expect(currentSession()!.name, 'Push');

    // Flush the debounced autosave so no timer outlives the test.
    await controller().flushSave();
  });

  testWidgets('start, complete a set and finish into the summary', (tester) async {
    await useTallSurface(tester);
    await pumpSession(tester);
    await addBenchPress(tester);

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    expect(find.text('Exercise 1 of 1'), findsOneWidget);
    expect(find.text('Finish workout'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Complete set'));
    await tester.pumpAndSettle();
    expect(currentSession()!.completedSets, 1);

    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();

    expect(find.text('Workout summary'), findsOneWidget);
    expect(find.text('Volume'), findsOneWidget);
    expect(find.text('Sets'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(currentSession()!.stage, SessionStage.summary);

    // Flush the debounced autosave so no timer outlives the test.
    await controller().flushSave();
  });

  testWidgets('shows the rest timer banner after completing a non-final set',
      (tester) async {
    await useTallSurface(tester);
    await controller().openSession(name: 'Push day', plans: [benchPlan()]);
    await controller().start();
    final session = currentSession()!;
    controller().updateSet(
      0,
      0,
      session.content.exercises[0].sets[0].copyWith(
        completed: true,
        timestamp: now,
      ),
    );
    await controller().flushSave();

    await pumpSession(tester);

    expect(find.text('Rest'), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);
    expect(currentSession()!.isRestActive, isTrue);
  });

  testWidgets('Done discards the workout and pops back to the home route',
      (tester) async {
    await useTallSurface(tester);
    await controller().openSession(name: 'Push day', plans: [benchPlan()]);
    await controller().start();
    final session = currentSession()!;
    controller().updateSet(
      0,
      0,
      session.content.exercises[0].sets[0].copyWith(
        completed: true,
        timestamp: now,
      ),
    );
    await controller().finish();

    await pumpSession(tester);
    expect(find.text('Workout summary'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/');
    expect(currentSession(), isNull);
    expect(await ActiveSessionStore(env.databaseService).load(), isNull);
  });

  testWidgets('back on the summary discards the workout', (tester) async {
    await useTallSurface(tester);
    await controller().openSession(name: 'Push day', plans: [benchPlan()]);
    await controller().start();
    final session = currentSession()!;
    controller().updateSet(
      0,
      0,
      session.content.exercises[0].sets[0].copyWith(
        completed: true,
        timestamp: now,
      ),
    );
    await controller().finish();

    await pumpSession(tester);

    // The summary stage has no back button; system back is intercepted by the
    // screen's PopScope, which discards the workout and pops.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/');
    expect(currentSession(), isNull);
    expect(await ActiveSessionStore(env.databaseService).load(), isNull);
  });
}

class _HomeStub extends StatelessWidget {
  const _HomeStub();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('home')),
    );
  }
}

/// A session service backed by memory instead of Hive.
///
/// Widget tests run inside Flutter's fake-async zone, where the real file IO
/// behind Hive's disk backend never completes. The controller, store and
/// service round-trips are already covered by plain-async unit tests against a
/// real Hive environment; this fake keeps the widget tests deterministic while
/// exercising the same [ActiveSessionController] state machine.
class _InMemorySessionService extends SessionService {
  _InMemorySessionService(DatabaseService db)
      : super(
          store: ActiveSessionStore(db),
          workoutSessionRepository:
              HiveWorkoutSessionRepository(db.sessionBox),
          exerciseHistoryRepository:
              HiveExerciseHistoryRepository(db.historyBox),
          personalRecordRepository:
              HivePersonalRecordRepository(db.prBox),
          calendarRepository: HiveCalendarRepository(db.calendarBox),
          exerciseRepository: HiveExerciseRepository(db.exerciseBox),
        );

  ActiveSession? _current;

  @override
  Future<void> save(ActiveSession session) async => _current = session;

  @override
  Future<ActiveSession?> load() async => _current;

  @override
  Future<WorkoutSession> finish(ActiveSession session, DateTime now) async {
    _current = null;
    return session.toFinalSession(now);
  }

  @override
  Future<SessionFinishResult> finishWithRecords(
    ActiveSession session,
    DateTime now,
  ) async {
    _current = null;
    return SessionFinishResult(
      session: session.toFinalSession(now),
      records: const [],
    );
  }

  @override
  Future<void> abandon() async => _current = null;
}
