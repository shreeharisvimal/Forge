// Provider tests for the calendar read models.
//
// Boots the calendar providers against a real temp-dir Hive store with a
// pinned clock and verifies the read model covers the whole load window, the
// detail sheet reads a fresh per-day view, and the search feed lists every
// logged day.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/features/calendar/domain/calendar_models.dart';
import 'package:forge/features/calendar/domain/calendar_queries.dart';
import 'package:forge/features/calendar/providers/calendar_providers.dart';
import 'package:forge/models/body_measurement.dart';
import 'package:forge/models/calendar_day.dart';
import 'package:forge/models/weight_entry.dart';
import 'package:forge/models/workout_session.dart';
import 'package:forge/services/providers.dart';
import 'package:forge/services/repositories/calendar_repository.dart';
import 'package:forge/services/repositories/measurement_repository.dart';
import 'package:forge/services/repositories/weight_repository.dart';
import 'package:forge/services/repositories/workout_session_repository.dart';

import '../../helpers/hive_test_env.dart';

void main() {
  late HiveTestEnv env;

  final pinnedNow = DateTime(2026, 2, 4, 9);

  late ProviderContainer container;

  setUp(() async {
    env = await HiveTestEnv.create();

    final calendar = HiveCalendarRepository(env.databaseService.calendarBox);
    final weights = HiveWeightRepository(env.databaseService.weightBox);
    final measurements =
        HiveMeasurementRepository(env.databaseService.measurementBox);
    final sessions =
        HiveWorkoutSessionRepository(env.databaseService.sessionBox);

    await calendar.save(CalendarDay(
      date: DateTime(2026, 2, 4),
      weight: 82,
      sleepHours: 7.5,
      mood: 4,
    ));
    await weights.save(WeightEntry(date: DateTime(2026, 2, 3), weight: 81.5));
    await weights.save(WeightEntry(date: DateTime(2026, 2, 4), weight: 82));
    await measurements.save(BodyMeasurement(
      date: DateTime(2026, 2, 4),
      waist: 80,
    ));
    await sessions.save(WorkoutSession(
      date: DateTime(2026, 2, 4, 8),
      durationMinutes: 45,
      completed: true,
    ));

    container = ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(env.databaseService),
        calendarNowProvider.overrideWithValue(pinnedNow),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await env.dispose();
  });

  group('calendarReadModelProvider', () {
    test('covers the whole load window', () {
      final model = container.read(calendarReadModelProvider);
      final window = loadWindow(container.read(calendarFocusedDayProvider));

      expect(window.from, DateTime(2026, 1, 20));
      expect(window.to, DateTime(2026, 3, 7));

      final missing = <DateTime>[];
      for (var day = window.from;
          !day.isAfter(window.to);
          day = day.add(const Duration(days: 1))) {
        if (model.viewFor(day) == null) missing.add(day);
      }
      expect(missing, isEmpty);
    });

    test('merges weight, row, measurement and sessions per day', () {
      final view = container
          .read(calendarReadModelProvider)
          .viewFor(DateTime(2026, 2, 4));

      expect(view, isNotNull);
      expect(view!.weight, 82);
      expect(view.sleepHours, 7.5);
      expect(view.mood, 4);
      expect(view.measurement?.waist, 80);
      expect(view.sessions.single.durationMinutes, 45);
      expect(view.workedOut, isTrue);
      expect(view.markers, contains(CalendarDayMarker.weight));
      expect(view.markers, contains(CalendarDayMarker.workout));
      expect(view.markers, contains(CalendarDayMarker.measurement));
      expect(view.markers, contains(CalendarDayMarker.sleep));
      expect(view.markers, contains(CalendarDayMarker.mood));
    });

    test('a day with only a weigh-in is a valid view', () {
      final view = container
          .read(calendarReadModelProvider)
          .viewFor(DateTime(2026, 2, 3));

      expect(view?.weight, 81.5);
      expect(view?.hasData, isTrue);
      expect(view?.markers, [CalendarDayMarker.weight]);
    });

    test('rebuilds around a newly focused month', () {
      container.read(calendarFocusedDayProvider.notifier).state =
          DateTime(2026, 3, 15);

      final model = container.read(calendarReadModelProvider);
      expect(model.viewFor(DateTime(2026, 3, 15)), isNotNull);
      expect(model.viewFor(DateTime(2026, 2, 4)), isNull);
    });
  });

  group('calendarDayViewProvider', () {
    test('reads a fresh view for the requested day', () {
      final view = container.read(calendarDayViewProvider(DateTime(2026, 2, 4)));

      expect(view.weight, 82);
      expect(view.sleepHours, 7.5);
      expect(view.sessions.single.completed, isTrue);
    });

    test('returns an empty view for an unrecorded day', () {
      final view =
          container.read(calendarDayViewProvider(DateTime(2026, 2, 10)));

      expect(view.hasData, isFalse);
      expect(view.markers, isEmpty);
    });
  });

  group('calendarPreviousWeightProvider', () {
    test('returns the latest weigh-in strictly before the day', () {
      expect(
        container.read(calendarPreviousWeightProvider(DateTime(2026, 2, 4))),
        81.5,
      );
    });

    test('returns null when nothing precedes the day', () {
      expect(
        container.read(calendarPreviousWeightProvider(DateTime(2026, 2, 3))),
        isNull,
      );
    });
  });

  group('calendarLoggedDaysProvider', () {
    test('lists every recorded day newest first', () {
      final days = container.read(calendarLoggedDaysProvider);

      expect(days, [DateTime(2026, 2, 4), DateTime(2026, 2, 3)]);
    });
  });

  group('state providers', () {
    test('default to the pinned clock', () {
      expect(
        container.read(calendarFocusedDayProvider),
        DateTime(2026, 2, 4),
      );
      expect(container.read(calendarSelectedDayProvider), DateTime(2026, 2, 4));
      expect(container.read(calendarFormatProvider), isNotNull);
    });

    test('state can be updated', () {
      container.read(calendarSelectedDayProvider.notifier).state =
          DateTime(2026, 2, 14);

      expect(
        container.read(calendarSelectedDayProvider),
        DateTime(2026, 2, 14),
      );
    });
  });
}
