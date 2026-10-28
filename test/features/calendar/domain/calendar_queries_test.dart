// Unit tests for the pure calendar query helpers.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/utils/dates.dart';
import 'package:forge/features/calendar/domain/calendar_models.dart';
import 'package:forge/features/calendar/domain/calendar_queries.dart';
import 'package:forge/models/body_measurement.dart';
import 'package:forge/models/calendar_day.dart';
import 'package:forge/models/weight_entry.dart';
import 'package:forge/models/workout_session.dart';

void main() {
  group('visibleMonthRange', () {
    test('spans a whole week grid around February 2026', () {
      final range = visibleMonthRange(DateTime(2026, 2, 15));

      expect(range.from, DateTime(2026, 1, 26));
      expect(range.to, DateTime(2026, 3, 1));
      expect(range.dayCount % 7, 0);
      expect(range.dayCount, 35);
      expect(range.from.weekday, DateTime.monday);
      expect(range.to.weekday, DateTime.sunday);
    });

    test('bounds are inclusive', () {
      final range = visibleMonthRange(DateTime(2026, 2, 15));
      expect(range.contains(range.from), isTrue);
      expect(range.contains(range.to), isTrue);
      expect(range.contains(DateTime(2026, 1, 25)), isFalse);
      expect(range.contains(DateTime(2026, 3, 2)), isFalse);
    });
  });

  group('visibleWeekRange', () {
    test('returns the Monday-to-Sunday week around any day', () {
      final range = visibleWeekRange(DateTime(2026, 2, 5));

      expect(range.from, DateTime(2026, 2, 2));
      expect(range.to, DateTime(2026, 2, 8));
      expect(range.dayCount, 7);
    });

    test('handles weeks crossing a month boundary', () {
      final range = visibleWeekRange(DateTime(2026, 3, 1));

      expect(range.from, DateTime(2026, 2, 23));
      expect(range.to, DateTime(2026, 3, 1));
    });
  });

  group('loadWindow', () {
    test('pads the month range by 6 days on both sides', () {
      final range = loadWindow(DateTime(2026, 2, 15));

      expect(range.from, DateTime(2026, 1, 20));
      expect(range.to, DateTime(2026, 3, 7));
    });
  });

  group('label formatters', () {
    test('formats the month title', () {
      expect(formatMonthTitle(DateTime(2026, 2, 4)), 'February 2026');
    });

    test('formats compact and full day labels', () {
      expect(formatDayLabel(DateTime(2026, 2, 3)), 'Tue, Feb 3');
      expect(
        formatFullDayLabel(DateTime(2026, 2, 3)),
        'Tuesday, February 3, 2026',
      );
    });
  });

  group('mood helpers', () {
    test('maps ratings to emoji', () {
      expect(moodEmoji(1), '😞');
      expect(moodEmoji(2), '😴');
      expect(moodEmoji(3), '😐');
      expect(moodEmoji(4), '🙂');
      expect(moodEmoji(5), '😀');
      expect(moodEmoji(null), isNull);
      expect(moodEmoji(9), isNull);
    });

    test('maps ratings to labels', () {
      expect(moodLabel(1), 'Bad');
      expect(moodLabel(2), 'Tired');
      expect(moodLabel(3), 'Okay');
      expect(moodLabel(4), 'Good');
      expect(moodLabel(5), 'Excellent');
      expect(moodLabel(null), '—');
      expect(moodLabel(0), '—');
    });
  });

  group('isAllTimeLow', () {
    test('flags only the day holding the lowest weigh-in', () {
      final entries = [
        WeightEntry(id: 'a', date: DateTime(2026, 2, 2), weight: 80.5),
        WeightEntry(id: 'b', date: DateTime(2026, 2, 3), weight: 79.5),
        WeightEntry(id: 'c', date: DateTime(2026, 2, 4), weight: 80.0),
      ];

      expect(isAllTimeLow(DateTime(2026, 2, 3), entries), isTrue);
      expect(isAllTimeLow(DateTime(2026, 2, 2), entries), isFalse);
      expect(isAllTimeLow(DateTime(2026, 2, 9), entries), isFalse);
    });
  });

  group('measurementSummary', () {
    test('describes which measurements were logged', () {
      final measurement = BodyMeasurement(
        date: DateTime(2026, 2, 4),
        weight: 82,
        waist: 80,
        bodyFat: 18,
      );

      expect(
        measurementSummary(measurement),
        'Weight · Waist · Body fat',
      );
    });

    test('falls back for null and empty records', () {
      expect(measurementSummary(null), '');
      expect(
        measurementSummary(BodyMeasurement(date: DateTime(2026, 2, 4))),
        'Measurements',
      );
    });
  });

  group('buildDayView', () {
    test('row weight wins over the weight-history entry', () {
      final view = buildDayView(
        day: DateTime(2026, 2, 4),
        row: CalendarDay(date: DateTime(2026, 2, 4), weight: 82.0),
        weight: WeightEntry(date: DateTime(2026, 2, 4), weight: 83.0),
      );

      expect(view.weight, 82.0);
    });

    test('falls back to the weight entry without a row', () {
      final view = buildDayView(
        day: DateTime(2026, 2, 4),
        weight: WeightEntry(date: DateTime(2026, 2, 4), weight: 83.0),
      );

      expect(view.weight, 83.0);
    });

    test('carries photos and sessions through', () {
      final session = WorkoutSession(
        id: 's1',
        date: DateTime(2026, 2, 4, 8),
        completed: true,
      );
      final view = buildDayView(
        day: DateTime(2026, 2, 4),
        row: CalendarDay(
          date: DateTime(2026, 2, 4),
          photos: ['photos/a.jpg'],
          photoThumbs: ['photos/a_thumb.jpg'],
        ),
        sessions: [session],
      );

      expect(view.photoCount, 1);
      expect(view.photoThumbs, ['photos/a_thumb.jpg']);
      expect(view.sessions, [session]);
    });
  });

  group('CalendarDayView', () {
    test('markers render in display order', () {
      final view = CalendarDayView(
        date: DateTime(2026, 2, 4),
        weight: 82,
        workoutCompleted: true,
        sleepHours: 7.5,
        waterLitres: 2.5,
        mood: 4,
        notes: 'Great session',
        photos: const ['photos/a.jpg'],
        measurement: BodyMeasurement(
          date: DateTime(2026, 2, 4),
          waist: 80,
        ),
      );

      expect(view.markers, [
        CalendarDayMarker.workout,
        CalendarDayMarker.weight,
        CalendarDayMarker.measurement,
        CalendarDayMarker.sleep,
        CalendarDayMarker.water,
        CalendarDayMarker.mood,
        CalendarDayMarker.photo,
        CalendarDayMarker.notes,
      ]);
    });

    test('workedOut derives from either source', () {
      expect(
        CalendarDayView(date: DateTime(2026, 2, 4), workoutCompleted: true)
            .workedOut,
        isTrue,
      );
      expect(
        CalendarDayView(
          date: DateTime(2026, 2, 4),
          sessions: [
            WorkoutSession(
              date: DateTime(2026, 2, 4),
              completed: true,
            ),
          ],
        ).workedOut,
        isTrue,
      );
      expect(
        CalendarDayView(date: DateTime(2026, 2, 4)).workedOut,
        isFalse,
      );
    });

    test('hasData reflects any recorded content', () {
      expect(CalendarDayView(date: DateTime(2026, 2, 4)).hasData, isFalse);
      expect(
        CalendarDayView(
          date: DateTime(2026, 2, 4),
          durationMinutes: 45,
        ).hasData,
        isTrue,
      );
    });
  });

  group('CalendarReadModel', () {
    test('viewFor normalizes the lookup key', () {
      final model = CalendarReadModel(
        days: keyViewsByDay([
          CalendarDayView(date: DateTime(2026, 2, 4), weight: 82),
        ]),
      );

      final view = model.viewFor(DateTime(2026, 2, 4, 19, 30));
      expect(view?.weight, 82);
      expect(model.viewFor(DateTime(2026, 2, 5)), isNull);
    });
  });

  group('dateOnly', () {
    test('strips the time component', () {
      expect(dateOnly(DateTime(2026, 2, 4, 19, 30)), DateTime(2026, 2, 4));
    });
  });
}
