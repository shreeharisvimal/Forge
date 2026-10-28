// Analytics service for the Forge application.
//
// Architecture-only and offline-first: no network analytics are wired up.
// The default [NoOpAnalyticsService] records nothing; [InMemoryAnalyticsService]
// captures events for tests and debugging. When real analytics ship, they must
// stay privacy-respecting and local — nothing leaves the device.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single recorded analytics event.
class AnalyticsEvent {
  /// Creates an event with optional [properties].
  const AnalyticsEvent(this.name, [this.properties = const {}]);

  /// The event name.
  final String name;

  /// Key-value dimensions attached to the event.
  final Map<String, Object> properties;
}

/// Records and reports analytics events.
abstract class AnalyticsService {
  /// Records [event].
  Future<void> track(AnalyticsEvent event);

  /// Sets a user-level [key] property to [value].
  Future<void> setProperty(String key, String value);

  /// Flushes any buffered events.
  Future<void> flush();
}

/// [AnalyticsService] that records nothing.
///
/// A placeholder until a privacy-respecting local analytics implementation
/// replaces it; nothing leaves the device.
class NoOpAnalyticsService implements AnalyticsService {
  /// Creates the no-op service.
  const NoOpAnalyticsService();

  @override
  Future<void> track(AnalyticsEvent event) async {}

  @override
  Future<void> setProperty(String key, String value) async {}

  @override
  Future<void> flush() async {}
}

/// [AnalyticsService] that records events in memory.
///
/// Useful for tests and debugging: [events] holds everything tracked in order,
/// [flush] clears the buffer, and [properties] mirrors the current user-level
/// properties.
class InMemoryAnalyticsService implements AnalyticsService {
  /// Creates the in-memory service.
  InMemoryAnalyticsService();

  final List<AnalyticsEvent> _events = [];
  final Map<String, String> _properties = {};

  /// The events tracked so far, oldest first.
  List<AnalyticsEvent> get events => List.unmodifiable(_events);

  /// The current user-level properties.
  Map<String, String> get properties => Map.unmodifiable(_properties);

  @override
  Future<void> track(AnalyticsEvent event) async => _events.add(event);

  @override
  Future<void> setProperty(String key, String value) async =>
      _properties[key] = value;

  @override
  Future<void> flush() async => _events.clear();
}

/// Provides the app-wide [AnalyticsService].
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => NoOpAnalyticsService(),
);
