// Unit tests for the Forge input validation helpers.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/utils/validation.dart';

void main() {
  group('validateName', () {
    test('rejects empty and whitespace-only names', () {
      expect(validateName(''), isNotNull);
      expect(validateName('   '), isNotNull);
      expect(validateName(null), isNotNull);
    });

    test('rejects names over 60 characters', () {
      expect(validateName('x' * 61), isNotNull);
    });

    test('accepts a normal name and trims surrounding whitespace', () {
      expect(validateName('  Bench Press  '), isNull);
    });
  });

  group('validateWeight', () {
    test('rejects null and non-positive weights', () {
      expect(validateWeight(null), isNotNull);
      expect(validateWeight(0), isNotNull);
      expect(validateWeight(-5), isNotNull);
    });

    test('accepts positive weights', () {
      expect(validateWeight(20.5), isNull);
    });
  });

  group('validateReps', () {
    test('rejects null, zero and out-of-range reps', () {
      expect(validateReps(null), isNotNull);
      expect(validateReps(0), isNotNull);
      expect(validateReps(1001), isNotNull);
    });

    test('accepts reps between 1 and 1000', () {
      expect(validateReps(1), isNull);
      expect(validateReps(1000), isNull);
    });
  });

  group('validateRestTimer', () {
    test('rejects values outside 0-3600', () {
      expect(validateRestTimer(-1), isNotNull);
      expect(validateRestTimer(3601), isNotNull);
    });

    test('accepts boundary values', () {
      expect(validateRestTimer(0), isNull);
      expect(validateRestTimer(90), isNull);
      expect(validateRestTimer(3600), isNull);
    });
  });

  group('validateWeekday', () {
    test('allows null (no weekday assigned)', () {
      expect(validateWeekday(null), isNull);
    });

    test('rejects out-of-range weekdays', () {
      expect(validateWeekday(0), isNotNull);
      expect(validateWeekday(8), isNotNull);
    });

    test('accepts 1-7', () {
      for (var day = 1; day <= 7; day++) {
        expect(validateWeekday(day), isNull);
      }
    });
  });

  group('unit and theme validators', () {
    test('accepts only known units and modes', () {
      expect(isValidWeightUnit('kg'), isTrue);
      expect(isValidWeightUnit('lb'), isTrue);
      expect(isValidWeightUnit('stones'), isFalse);

      expect(isValidLengthUnit('cm'), isTrue);
      expect(isValidLengthUnit('in'), isTrue);
      expect(isValidLengthUnit('m'), isFalse);

      expect(isValidThemeMode('system'), isTrue);
      expect(isValidThemeMode('dark'), isTrue);
      expect(isValidThemeMode('neon'), isFalse);
    });
  });
}
