// Tests for the PrEvent repository.
//
// Exercises the append-only event timeline against a real Hive box: per
// exercise and per workout queries, recency ordering and deletion.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/prs/data/pr_event.dart';
import 'package:forge/features/prs/data/pr_event_repository.dart';
import 'package:forge/features/prs/domain/pr_types.dart';

import '../../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;
  late PrEventRepository repo;

  final day1 = DateTime(2026, 1, 10);
  final day2 = DateTime(2026, 2, 4);
  final day3 = DateTime(2026, 2, 20);

  setUp(() async {
    env = await HiveTestEnv.create();
    repo = HivePrEventRepository(env.databaseService.prEventsBox);
  });

  tearDown(() => env.dispose());

  PrEvent event({
    String exerciseId = 'bench',
    PrType type = PrType.heaviestWeight,
    double value = 100,
    DateTime? date,
    String? workoutId,
  }) {
    return PrEvent(
      exerciseId: exerciseId,
      exerciseName: 'Bench Press',
      type: type.name,
      value: value,
      date: date ?? day2,
      workoutId: workoutId,
    );
  }

  test('save persists events to the box', () async {
    await repo.save(event());
    expect(repo.count, 1);
    expect(repo.all().single.exerciseId, 'bench');
  });

  test('forExercise filters and sorts newest first', () async {
    await repo.save(event(exerciseId: 'bench', date: day1));
    await repo.save(event(exerciseId: 'squat', date: day1));
    await repo.save(event(exerciseId: 'bench', date: day3));
    await repo.save(event(exerciseId: 'bench', date: day2));

    final bench = repo.forExercise('bench');
    expect(bench, hasLength(3));
    expect(bench.first.date, day3);
    expect(bench.last.date, day1);
  });

  test('forWorkout groups events produced by one workout', () async {
    await repo.save(event(workoutId: 'w1', value: 100));
    await repo.save(event(workoutId: 'w1', value: 110));
    await repo.save(event(workoutId: 'w2', value: 120));

    final forWorkout = repo.forWorkout('w1');
    expect(forWorkout, hasLength(2));
    expect(forWorkout.map((e) => e.value), containsAll([100, 110]));
  });

  test('recent returns the newest events capped at the limit', () async {
    for (var i = 1; i <= 5; i++) {
      await repo.save(event(date: day1.add(Duration(days: i))));
    }

    final recent = repo.recent(3);
    expect(recent, hasLength(3));
    expect(recent.first.date, day1.add(const Duration(days: 5)));
  });

  test('countForExercise counts only matching rows', () async {
    await repo.save(event(exerciseId: 'bench'));
    await repo.save(event(exerciseId: 'bench'));
    await repo.save(event(exerciseId: 'squat'));

    expect(repo.countForExercise('bench'), 2);
    expect(repo.countForExercise('deadlift'), 0);
  });

  test('delete removes a row', () async {
    final saved = event();
    await repo.save(saved);
    await repo.delete(saved.id);
    expect(repo.count, 0);
  });

  test('events survive a round-trip through the box unchanged', () async {
    final original = event(
      type: PrType.estimatedOneRM,
      value: 116.7,
      date: day2,
      workoutId: 'w9',
    );
    await repo.save(original);
    final loaded = repo.byId(original.id);
    expect(loaded, original);
  });
}
