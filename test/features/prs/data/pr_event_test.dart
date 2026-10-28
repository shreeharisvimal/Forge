// Tests for the PrEvent model.
//
// Verifies construction defaults, type parsing, copy semantics, map/JSON
// round-trips and value equality. The Hive adapter itself is exercised by the
// repository tests against a real box.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/prs/data/pr_event.dart';
import 'package:forge/features/prs/domain/one_rep_max.dart';
import 'package:forge/features/prs/domain/pr_types.dart';

void main() {
  final date = DateTime(2026, 2, 4, 12, 30);

  PrEvent buildEvent() => PrEvent(
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
        type: PrType.estimatedOneRM.name,
        value: 116.7,
        previousValue: 105,
        date: date,
        workoutId: 'w1',
        formula: OneRepMaxFormula.brzycki.storageKey,
        calculatedOneRM: 116.7,
      );

  test('defaults generate an id, timestamp and safe values', () {
    final event = PrEvent(
      exerciseId: 'bench',
      exerciseName: 'Bench Press',
      type: PrType.heaviestWeight.name,
      value: 100,
    );

    expect(event.id, isNotEmpty);
    expect(event.date, isNotNull);
    expect(event.previousValue, 0);
    expect(event.workoutId, isNull);
    expect(event.notes, isEmpty);
    expect(event.formula, OneRepMaxFormula.epley.storageKey);
    expect(event.calculatedOneRM, 0);
  });

  test('parses the record type and formula', () {
    final event = buildEvent();
    expect(event.prType, PrType.estimatedOneRM);
    expect(event.oneRepMaxFormula, OneRepMaxFormula.brzycki);
    expect(event.difference, closeTo(11.7, 0.001));
  });

  test('unknown type falls back to heaviest weight', () {
    final event = buildEvent().copyWith(type: 'bogus');
    expect(event.prType, PrType.heaviestWeight);
  });

  test('copyWith replaces only the given fields', () {
    final event = buildEvent();
    final updated = event.copyWith(
      value: 120,
      workoutId: () => null,
      notes: 'paused set',
    );

    expect(updated.value, 120);
    expect(updated.workoutId, isNull);
    expect(updated.notes, 'paused set');
    expect(updated.id, event.id);
    expect(updated.exerciseName, event.exerciseName);
    expect(updated.type, event.type);
  });

  test('map and JSON round-trips preserve every field', () {
    final event = buildEvent();

    final fromMap = PrEvent.fromMap(event.toMap());
    expect(fromMap, event);

    final fromJson = PrEvent.fromJson(event.toJson());
    expect(fromJson, event);
  });

  test('equality is value based', () {
    final a = buildEvent();
    final b = buildEvent().copyWith(id: a.id);
    final c = buildEvent().copyWith(id: a.id, value: 999);

    expect(a, b);
    expect(a, isNot(c));
    expect(a.hashCode, b.hashCode);
  });
}
