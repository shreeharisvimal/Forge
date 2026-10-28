// Tests for the analytics service.
//
// Exercises the in-memory recorder used by tests and debugging; the no-op
// service is verified to do nothing observable.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/services/analytics/analytics_service.dart';

void main() {
  group('InMemoryAnalyticsService', () {
    late InMemoryAnalyticsService service;

    setUp(() => service = InMemoryAnalyticsService());

    test('track records events in order', () async {
      await service.track(const AnalyticsEvent('workout_started', {'sets': 3}));
      await service.track(const AnalyticsEvent('workout_completed'));

      expect(
        service.events.map((event) => event.name),
        ['workout_started', 'workout_completed'],
      );
      expect(service.events.first.properties, {'sets': 3});
    });

    test('setProperty records user-level properties', () async {
      await service.setProperty('goal', 'strength');

      expect(service.properties, {'goal': 'strength'});
    });

    test('flush clears the event buffer', () async {
      await service.track(const AnalyticsEvent('workout_started'));
      await service.flush();

      expect(service.events, isEmpty);
    });
  });

  group('NoOpAnalyticsService', () {
    const service = NoOpAnalyticsService();

    test('track, setProperty and flush complete without throwing', () async {
      await service.track(const AnalyticsEvent('workout_started'));
      await service.setProperty('goal', 'strength');
      await service.flush();
    });
  });
}
