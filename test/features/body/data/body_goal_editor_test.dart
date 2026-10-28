// Tests for the body goal editor.
//
// Verifies that targets upsert per field (one goal per field, updated in
// place), removal deletes the stored goal, and the repository sorts by
// creation time.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/body/data/body_goal_editor.dart';
import 'package:forge/features/body/data/body_goal_repository.dart';
import 'package:forge/features/body/domain/body_measurement_fields.dart';

import '../../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;
  late BodyGoalEditor editor;

  setUp(() async {
    env = await HiveTestEnv.create();
    editor = BodyGoalEditor(
      repository:
          HiveBodyGoalRepository(env.databaseService.bodyGoalsBox),
    );
  });

  tearDown(() => env.dispose());

  test('sets a new goal for a field', () async {
    await editor.set(field: BodyField.waist, target: 85);

    final goal = editor.forField(BodyField.waist);
    expect(goal, isNotNull);
    expect(goal!.target, 85);
    expect(goal.field, BodyField.waist);
  });

  test('re-setting the same field updates in place', () async {
    await editor.set(field: BodyField.waist, target: 85);
    final original = editor.forField(BodyField.waist)!;

    await editor.set(field: BodyField.waist, target: 80);

    final updated = editor.forField(BodyField.waist)!;
    expect(updated.target, 80);
    expect(updated.id, original.id);
    expect(editor.repository.count, 1);
  });

  test('removing a goal deletes it', () async {
    await editor.set(field: BodyField.waist, target: 85);

    await editor.remove(BodyField.waist);

    expect(editor.forField(BodyField.waist), isNull);
    expect(editor.repository.count, 0);
  });

  test('removing an unset field is a no-op', () async {
    await editor.remove(BodyField.waist);

    expect(editor.repository.count, 0);
  });

  test('different fields coexist', () async {
    await editor.set(field: BodyField.waist, target: 85);
    await editor.set(field: BodyField.leftArm, target: 40);

    expect(editor.repository.count, 2);
    expect(editor.forField(BodyField.waist)!.target, 85);
    expect(editor.forField(BodyField.leftArm)!.target, 40);
  });

  test('repository sorts goals by creation time', () async {
    await editor.set(
      field: BodyField.waist,
      target: 85,
      createdAt: DateTime(2026, 8, 10),
    );
    await editor.set(
      field: BodyField.leftArm,
      target: 40,
      createdAt: DateTime(2026, 8, 2),
    );

    final ordered = editor.repository.allByDate();
    expect(ordered.map((goal) => goal.field),
        [BodyField.leftArm, BodyField.waist]);
  });
}
