// Tests for the DateService.
//
// Uses a fixed clock so every date query, relative label and streak scenario
// is deterministic regardless of when the suite runs.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/services/date_time/date_service.dart';
import 'package:forge/core/utils/ids.dart';

void main() {
  group('today and day comparisons', () {
    final service = DateService(clock: () => DateTime(2026, 8, 5, 14, 30));

    test('today normalizes the clock to midnight', () {
      expect(service.today(), DateTime(2026, 8, 5));
    });

    test('isToday compares calendar days', () {
      expect(service.isToday(DateTime(2026, 8, 5, 23, 59)), isTrue);
      expect(service.isToday(DateTime(2026, 8, 4, 23, 59)), isFalse);
    });

    test('isSameDay ignores the time component', () {
      expect(
        service.isSameDay(DateTime(2026, 8, 5, 1), DateTime(2026, 8, 5, 22)),
        isTrue,
      );
      expect(
        service.isSameDay(DateTime(2026, 8, 5), DateTime(2026, 8, 6)),
        isFalse,
      );
    });

    test('isInRange is inclusive on both bounds', () {
      final from = DateTime(2026, 8, 3);
      final to = DateTime(2026, 8, 7);
      expect(service.isInRange(DateTime(2026, 8, 3), from, to), isTrue);
      expect(service.isInRange(DateTime(2026, 8, 7), from, to), isTrue);
      expect(service.isInRange(DateTime(2026, 8, 2), from, to), isFalse);
      expect(service.isInRange(DateTime(2026, 8, 8), from, to), isFalse);
    });
  });

  group('week and month math', () {
    final service = DateService(clock: () => DateTime(2026, 8, 5));

    test('startOfWeek and endOfWeek are Monday-first', () {
      expect(service.startOfWeek(DateTime(2026, 8, 5)), DateTime(2026, 8, 3));
      expect(service.endOfWeek(DateTime(2026, 8, 5)), DateTime(2026, 8, 9));
    });

    test('startOfWeek on a Monday returns that day', () {
      expect(service.startOfWeek(DateTime(2026, 8, 3)), DateTime(2026, 8, 3));
    });

    test('daysInWeek returns the seven Monday-first days', () {
      final days = service.daysInWeek(DateTime(2026, 8, 5));
      expect(days, hasLength(7));
      expect(days.first, DateTime(2026, 8, 3));
      expect(days.last, DateTime(2026, 8, 9));
    });

    test('startOfMonth and endOfMonth', () {
      expect(service.startOfMonth(DateTime(2026, 8, 15)), DateTime(2026, 8, 1));
      expect(service.endOfMonth(DateTime(2026, 8, 15)), DateTime(2026, 8, 31));
      expect(service.endOfMonth(DateTime(2026, 2, 5)), DateTime(2026, 2, 28));
      expect(service.endOfMonth(DateTime(2024, 2, 5)), DateTime(2024, 2, 29));
    });

    test('daysInMonthOf counts calendar days', () {
      expect(service.daysInMonthOf(DateTime(2026, 2, 10)), 28);
      expect(service.daysInMonthOf(DateTime(2024, 2, 10)), 29);
      expect(service.daysInMonthOf(DateTime(2026, 8, 10)), 31);
    });

    test('daysInMonth returns a complete 42-cell grid with spillover', () {
      // August 2026: the 1st is a Saturday, so the grid opens on Mon Jul 27.
      final days = service.daysInMonth(DateTime(2026, 8, 15));
      expect(days, hasLength(42));
      expect(days.first, DateTime(2026, 7, 27));
      expect(days.last, DateTime(2026, 9, 6));
      expect(days.contains(DateTime(2026, 8, 1)), isTrue);
      expect(days.contains(DateTime(2026, 8, 31)), isTrue);
    });

    test('weekOfMonth counts calendar grid rows', () {
      expect(service.weekOfMonth(DateTime(2026, 8, 1)), 1);
      expect(service.weekOfMonth(DateTime(2026, 8, 5)), 2);
      expect(service.weekOfMonth(DateTime(2026, 8, 31)), 6);
    });

    test('dayOfWeekMondayFirst is Monday-first', () {
      expect(service.dayOfWeekMondayFirst(DateTime(2026, 8, 3)), 1);
      expect(service.dayOfWeekMondayFirst(DateTime(2026, 8, 5)), 3);
      expect(service.dayOfWeekMondayFirst(DateTime(2026, 8, 9)), 7);
    });

    test(
      'nextWeekday returns the upcoming matching day strictly after from',
      () {
        final wednesday = DateTime(2026, 8, 5);
        expect(service.nextWeekday(wednesday, 1), DateTime(2026, 8, 10));
        expect(service.nextWeekday(wednesday, 2), DateTime(2026, 8, 11));
        expect(service.nextWeekday(wednesday, 3), DateTime(2026, 8, 12));
        expect(service.nextWeekday(wednesday, 7), DateTime(2026, 8, 9));
      },
    );

    test('nextWeekday returns null for out-of-range weekdays', () {
      expect(service.nextWeekday(DateTime(2026, 8, 5), 0), isNull);
      expect(service.nextWeekday(DateTime(2026, 8, 5), 8), isNull);
    });
  });

  group('formatting', () {
    final service = DateService(clock: () => DateTime(2026, 8, 5));

    test('format uses the default MMM d, yyyy pattern', () {
      expect(service.format(DateTime(2026, 8, 5)), 'Aug 5, 2026');
    });

    test('format honors an injected formatter hook', () {
      final custom = DateService(
        dateFormatter: (date) => '${date.year}/${date.month}/${date.day}',
      );
      expect(custom.format(DateTime(2026, 8, 5)), '2026/8/5');
    });

    test('formatShort and formatTime', () {
      expect(service.formatShort(DateTime(2026, 8, 5)), 'Aug 5');
      expect(service.formatTime(DateTime(2026, 8, 5, 9, 5)), '9:05 AM');
    });

    test('formatIso round-trips through parseIsoDate', () {
      final date = DateTime(2026, 8, 5, 14, 30, 15);
      expect(parseIsoDate(service.formatIso(date)), date);
    });
  });

  group('relative', () {
    final service = DateService(clock: () => DateTime(2026, 8, 5, 12, 0, 0));

    test('under a minute is just now', () {
      expect(service.relative(DateTime(2026, 8, 5, 11, 59, 40)), 'just now');
    });

    test('minutes use the m ago bucket', () {
      expect(service.relative(DateTime(2026, 8, 5, 11, 55, 0)), '5m ago');
      expect(service.relative(DateTime(2026, 8, 5, 11, 59, 0)), '1m ago');
    });

    test('hours apply while still today', () {
      expect(service.relative(DateTime(2026, 8, 5, 10, 0, 0)), '2h ago');
    });

    test('yesterday takes precedence over elapsed hours', () {
      expect(service.relative(DateTime(2026, 8, 4, 23, 0, 0)), 'yesterday');
    });

    test('days use the d ago bucket', () {
      expect(service.relative(DateTime(2026, 8, 2, 12, 0, 0)), '3d ago');
    });

    test('weeks use the w ago bucket', () {
      expect(service.relative(DateTime(2026, 7, 26, 12, 0, 0)), '1w ago');
      expect(service.relative(DateTime(2026, 7, 12, 12, 0, 0)), '3w ago');
    });

    test('older dates fall back to the formatted date', () {
      expect(service.relative(DateTime(2026, 7, 8, 12, 0, 0)), 'Jul 8, 2026');
    });
  });

  group('currentStreak', () {
    final service = DateService(clock: () => DateTime(2026, 8, 5, 9, 0, 0));
    final today = DateTime(2026, 8, 5);
    final yesterday = DateTime(2026, 8, 4);

    test('empty input yields zero', () {
      expect(service.currentStreak([]), 0);
    });

    test('a most recent day older than yesterday yields zero', () {
      expect(service.currentStreak([DateTime(2026, 8, 2)]), 0);
      expect(service.currentStreak([DateTime(2026, 8, 2), today]), 1);
    });

    test('a single day on today or yesterday counts as one', () {
      expect(service.currentStreak([today]), 1);
      expect(service.currentStreak([yesterday]), 1);
    });

    test('a consecutive run ending today is fully counted', () {
      expect(
        service.currentStreak([
          DateTime(2026, 8, 3),
          DateTime(2026, 8, 4),
          today,
        ]),
        3,
      );
    });

    test('a run ending yesterday is fully counted', () {
      expect(
        service.currentStreak([
          DateTime(2026, 8, 2),
          DateTime(2026, 8, 3),
          yesterday,
        ]),
        3,
      );
    });

    test('a gap on the day before the most recent breaks the streak', () {
      expect(service.currentStreak([DateTime(2026, 8, 3), today]), 1);
      expect(
        service.currentStreak([
          DateTime(2026, 8, 2),
          DateTime(2026, 8, 4),
          today,
        ]),
        2,
      );
    });

    test('input order and duplicates do not matter', () {
      expect(
        service.currentStreak([
          today,
          DateTime(2026, 8, 4),
          today,
          DateTime(2026, 8, 3),
        ]),
        3,
      );
    });
  });
}
