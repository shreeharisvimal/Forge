// Unit tests for the Forge date helpers.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/utils/dates.dart';

void main() {
  group('dateOnly', () {
    test('strips the time component', () {
      final result = dateOnly(DateTime(2026, 8, 4, 23, 59, 59));
      expect(result, DateTime(2026, 8, 4));
    });

    test('preserves the day for late-night timestamps', () {
      expect(dateOnly(DateTime(2026, 8, 4, 0, 30)), DateTime(2026, 8, 4));
    });
  });

  group('isSameDay', () {
    test('true for different times on the same day', () {
      expect(
        isSameDay(DateTime(2026, 8, 4, 6), DateTime(2026, 8, 4, 22)),
        isTrue,
      );
    });

    test('false across days', () {
      expect(
        isSameDay(DateTime(2026, 8, 4), DateTime(2026, 8, 5)),
        isFalse,
      );
    });
  });

  group('isBetweenInclusive', () {
    final from = DateTime(2026, 8, 1);
    final to = DateTime(2026, 8, 10);

    test('accepts the inclusive boundaries', () {
      expect(isBetweenInclusive(DateTime(2026, 8, 1, 12), from, to), isTrue);
      expect(isBetweenInclusive(DateTime(2026, 8, 10, 6), from, to), isTrue);
    });

    test('accepts a middle day', () {
      expect(isBetweenInclusive(DateTime(2026, 8, 5), from, to), isTrue);
    });

    test('rejects days outside the range', () {
      expect(isBetweenInclusive(DateTime(2026, 7, 31), from, to), isFalse);
      expect(isBetweenInclusive(DateTime(2026, 8, 11), from, to), isFalse);
    });
  });
}
