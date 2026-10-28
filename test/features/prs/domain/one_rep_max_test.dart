// Tests for one-rep-max estimation.
//
// Verifies the Epley, Brzycki and Lombardi formulas, the guard rails around
// non-positive inputs and the storage-key parsing used by settings.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:forge/features/prs/domain/one_rep_max.dart';

void main() {
  group('OneRepMaxFormula', () {
    test('parses storage keys and defaults to epley', () {
      expect(OneRepMaxFormula.fromStorageKey('epley'), OneRepMaxFormula.epley);
      expect(
        OneRepMaxFormula.fromStorageKey('brzycki'),
        OneRepMaxFormula.brzycki,
      );
      expect(
        OneRepMaxFormula.fromStorageKey('lombardi'),
        OneRepMaxFormula.lombardi,
      );
      expect(
        OneRepMaxFormula.fromStorageKey('unknown'),
        OneRepMaxFormula.epley,
      );
      expect(OneRepMaxFormula.fromStorageKey(null), OneRepMaxFormula.epley);
    });

    test('exposes distinct storage keys', () {
      final keys = OneRepMaxFormula.values.map((f) => f.storageKey).toSet();
      expect(keys, hasLength(3));
    });
  });

  group('OneRepMax.estimate', () {
    test('Epley: 100kg x 10 = 133.33', () {
      expect(OneRepMax.estimate(100, 10), closeTo(133.333, 0.001));
    });

    test('Epley: single rep equals the weight plus the third', () {
      expect(OneRepMax.estimate(120, 1), closeTo(124.0, 0.001));
    });

    test('Brzycki: 100kg x 10 = 133.33', () {
      expect(
        OneRepMax.estimate(100, 10, formula: OneRepMaxFormula.brzycki),
        closeTo(133.333, 0.001),
      );
    });

    test('Brzycki clamps high rep counts so the denominator stays positive',
        () {
      // 40 reps -> clamped to 36: 100 * 36 / (37 - 36).
      expect(
        OneRepMax.estimate(100, 40, formula: OneRepMaxFormula.brzycki),
        closeTo(3600, 0.001),
      );
    });

    test('Lombardi: 100kg x 10 = 125.89', () {
      expect(
        OneRepMax.estimate(100, 10, formula: OneRepMaxFormula.lombardi),
        closeTo(125.893, 0.001),
      );
    });

    test('returns 0 for non-positive weight or reps', () {
      expect(OneRepMax.estimate(0, 5), 0);
      expect(OneRepMax.estimate(100, 0), 0);
      expect(OneRepMax.estimate(-1, 5), 0);
      expect(OneRepMax.estimate(100, -3), 0);
    });
  });
}
