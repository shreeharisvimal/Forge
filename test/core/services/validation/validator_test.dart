// Tests for the Validator facade.
//
// Covers valid and invalid inputs for every method, including boundary
// values and the file name / extension rules.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/services/validation/validator.dart';

void main() {
  const validator = Validator();

  group('name rules', () {
    test('valid names pass', () {
      expect(validator.name('Bench'), isNull);
      expect(validator.workoutName('Leg Day'), isNull);
      expect(validator.exerciseName('Squat'), isNull);
    });

    test('rejects null, empty and over-length names', () {
      expect(validator.name(null), isNotNull);
      expect(validator.workoutName('   '), isNotNull);
      expect(validator.exerciseName('x' * 61), isNotNull);
      expect(validator.name('x' * 60), isNull);
    });

    test('trims surrounding whitespace', () {
      expect(validator.name('  Bench  '), isNull);
    });
  });

  group('numeric rules', () {
    test('weight', () {
      expect(validator.weight(45.5), isNull);
      expect(validator.weight(null), isNotNull);
      expect(validator.weight(0), isNotNull);
      expect(validator.weight(-1), isNotNull);
    });

    test('reps bounds are 1..1000', () {
      expect(validator.reps(12), isNull);
      expect(validator.reps(null), isNotNull);
      expect(validator.reps(0), isNotNull);
      expect(validator.reps(1001), isNotNull);
      expect(validator.reps(1), isNull);
      expect(validator.reps(1000), isNull);
    });

    test('restTimer bounds are 0..3600', () {
      expect(validator.restTimer(90), isNull);
      expect(validator.restTimer(null), isNotNull);
      expect(validator.restTimer(-1), isNotNull);
      expect(validator.restTimer(3601), isNotNull);
      expect(validator.restTimer(0), isNull);
      expect(validator.restTimer(3600), isNull);
    });

    test('weekday accepts null and 1..7', () {
      expect(validator.weekday(null), isNull);
      expect(validator.weekday(1), isNull);
      expect(validator.weekday(7), isNull);
      expect(validator.weekday(0), isNotNull);
      expect(validator.weekday(8), isNotNull);
    });

    test('measurement requires a positive number', () {
      expect(validator.measurement(100.0), isNull);
      expect(validator.measurement(null), 'Measurement is required.');
      expect(
        validator.measurement(0),
        'Measurement must be greater than zero.',
      );
      expect(validator.measurement(-5), isNotNull);
    });

    test('durationMinutes bounds are 1..1440', () {
      expect(validator.durationMinutes(60), isNull);
      expect(validator.durationMinutes(1), isNull);
      expect(validator.durationMinutes(1440), isNull);
      expect(validator.durationMinutes(null), isNotNull);
      expect(validator.durationMinutes(0), isNotNull);
      expect(validator.durationMinutes(1441), isNotNull);
    });
  });

  group('date rules', () {
    test('date rejects null', () {
      expect(validator.date(DateTime(2026, 8, 5)), isNull);
      expect(validator.date(null), isNotNull);
    });

    test('optionalDate always accepts', () {
      expect(validator.optionalDate(null), isNull);
      expect(validator.optionalDate(DateTime(2026, 8, 5)), isNull);
    });
  });

  group('file rules', () {
    test('fileName accepts normal and boundary-length names', () {
      expect(validator.fileName('backup_2026-08-05.json'), isNull);
      expect(validator.fileName('a' * 120), isNull);
    });

    test('fileName rejects empty, illegal characters and over-length', () {
      expect(validator.fileName(null), isNotNull);
      expect(validator.fileName(''), isNotNull);
      expect(validator.fileName('a/b'), isNotNull);
      expect(validator.fileName(r'a\b'), isNotNull);
      expect(validator.fileName('a\u0000b'), isNotNull);
      expect(validator.fileName('a' * 121), isNotNull);
    });

    test('fileExtension requires a non-empty extension', () {
      expect(validator.fileExtension('report.json'), isNull);
      expect(validator.fileExtension('archive.tar.gz'), isNull);
      expect(validator.fileExtension('.hidden'), isNull);
      expect(validator.fileExtension('report'), isNotNull);
      expect(validator.fileExtension('report.'), isNotNull);
      expect(validator.fileExtension(''), isNotNull);
      expect(validator.fileExtension(null), isNotNull);
    });
  });

  group('unit and numeric helpers', () {
    test('unit and theme delegates', () {
      expect(validator.isValidWeightUnit('kg'), isTrue);
      expect(validator.isValidWeightUnit('stone'), isFalse);
      expect(validator.isValidLengthUnit('cm'), isTrue);
      expect(validator.isValidLengthUnit('m'), isFalse);
      expect(validator.isValidThemeMode('dark'), isTrue);
      expect(validator.isValidThemeMode('blue'), isFalse);
    });

    test('isNumeric', () {
      expect(validator.isNumeric('123'), isTrue);
      expect(validator.isNumeric('12.5'), isTrue);
      expect(validator.isNumeric('-3'), isTrue);
      expect(validator.isNumeric('1e3'), isTrue);
      expect(validator.isNumeric('abc'), isFalse);
      expect(validator.isNumeric(''), isFalse);
    });
  });
}
