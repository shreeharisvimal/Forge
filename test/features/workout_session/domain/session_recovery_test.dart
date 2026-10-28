// Domain tests for post-session recovery recommendations and share text.
//
// Pure derivation: recovery buckets from muscle groups and the clipboard
// share summary text.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/workout_session/domain/session_formatters.dart';
import 'package:forge/features/workout_session/domain/session_recovery.dart';
import 'package:forge/features/workout_session/domain/session_share.dart';

void main() {
  group('SessionRecoveryCalculator.compute', () {
    test('maps trained muscle groups to recovery buckets', () {
      final recovery = SessionRecoveryCalculator.compute(['Chest', 'Triceps']);
      expect(recovery, isNotEmpty);
      final labels = recovery.map((entry) => entry.label).toList();
      expect(labels.join(), contains('Chest'));
      expect(labels.join(), contains('rest'));
    });

    test('deduplicates overlapping muscle groups', () {
      final recovery = SessionRecoveryCalculator.compute(['Chest', 'Chest']);
      expect(recovery, hasLength(1));
    });

    test('ignores non-strength groups', () {
      final recovery = SessionRecoveryCalculator.compute(['Cardio']);
      expect(recovery, isEmpty);
    });

    test('orders buckets as RecoveryGroup.values', () {
      final recovery = SessionRecoveryCalculator.compute(['Back', 'Chest']);
      final first = recovery.first.group.index;
      final last = recovery.last.group.index;
      expect(first, lessThan(last));
    });
  });

  group('SessionShareText.build', () {
    test('produces a readable plain-text summary', () {
      final text = SessionShareText.build(
        sessionName: 'Push day',
        date: DateTime(2026, 2, 4),
        duration: const Duration(minutes: 45),
        exerciseCount: 4,
        setCount: 12,
        volumeKg: 5000,
        repCount: 120,
        calories: 350,
        unit: SessionWeightUnit.kg,
      );
      expect(text, contains('#Forge Workout — Push day'));
      expect(text, contains('2026-02-04'));
      expect(text, contains('4 exercises · 12 sets · 120 reps'));
      expect(text, contains('5,000 kg'));
      expect(text, contains('45m'));
      expect(text, contains('350 kcal'));
      expect(text, contains('#ForgeApp #TrainHard'));
    });

    test('omits calories when unknown', () {
      final text = SessionShareText.build(
        sessionName: 'Push',
        date: DateTime(2026, 2, 4),
        duration: const Duration(minutes: 10),
        exerciseCount: 1,
        setCount: 1,
        volumeKg: 100,
        repCount: 5,
        calories: 0,
        unit: SessionWeightUnit.kg,
      );
      expect(text, isNot(contains('kcal')));
    });
  });
}
