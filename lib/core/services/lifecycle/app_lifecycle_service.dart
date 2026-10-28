// App lifecycle service for the Forge application.
//
// Observes app lifecycle transitions through [WidgetsBinding] and exposes
// them as streams. Future workout-timer persistence hooks attach here: on
// paused/resumed the app can persist and restore an active timer.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app lifecycle events Forge cares about.
enum AppLifecycleEvent {
  /// The app is visible and receiving input.
  resumed,

  /// The app is partially obscured and not receiving input.
  inactive,

  /// The app is no longer visible to the user.
  paused,

  /// The app is hidden but still resident.
  hidden,

  /// The app is about to be detached from the engine.
  detached,
}

/// Maps a Flutter [AppLifecycleState] to an [AppLifecycleEvent].
AppLifecycleEvent _eventFromState(AppLifecycleState state) {
  return switch (state) {
    AppLifecycleState.resumed => AppLifecycleEvent.resumed,
    AppLifecycleState.inactive => AppLifecycleEvent.inactive,
    AppLifecycleState.paused => AppLifecycleEvent.paused,
    AppLifecycleState.hidden => AppLifecycleEvent.hidden,
    AppLifecycleState.detached => AppLifecycleEvent.detached,
  };
}

/// Observes the app's lifecycle and exposes it as a stream.
class AppLifecycleService with WidgetsBindingObserver {
  final StreamController<AppLifecycleEvent> _events =
      StreamController<AppLifecycleEvent>.broadcast();

  AppLifecycleState? _state;
  bool _wasPaused = false;
  bool _attached = false;

  /// The current lifecycle state, or null before the first transition.
  AppLifecycleState? get state => _state;

  /// Whether the app is in the foreground and interactive.
  bool get isForeground => _state == AppLifecycleState.resumed;

  /// Whether the app is in the background.
  bool get isBackground =>
      _state == AppLifecycleState.paused ||
      _state == AppLifecycleState.detached;

  /// Whether the app has been paused at least once since launch.
  bool get wasPaused => _wasPaused;

  /// Emits every lifecycle transition.
  Stream<AppLifecycleEvent> get events => _events.stream;

  /// Emits whenever the app transitions to the foreground.
  Stream<void> get resumed => _events.stream
      .where((event) => event == AppLifecycleEvent.resumed)
      .map((_) {});

  /// Emits whenever the app is no longer visible.
  Stream<void> get paused => _events.stream
      .where((event) => event == AppLifecycleEvent.paused)
      .map((_) {});

  /// Emits whenever the app is detached from the engine.
  Stream<void> get detached => _events.stream
      .where((event) => event == AppLifecycleEvent.detached)
      .map((_) {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == _state) return;
    _state = state;
    if (state == AppLifecycleState.paused) _wasPaused = true;
    _events.add(_eventFromState(state));
  }

  /// Adds this service as a [WidgetsBinding] observer.
  void attach() {
    if (_attached) return;
    WidgetsBinding.instance.addObserver(this);
    _attached = true;
  }

  /// Removes this service from the [WidgetsBinding] observers.
  void detach() {
    if (!_attached) return;
    WidgetsBinding.instance.removeObserver(this);
    _attached = false;
  }
}

/// A zero-layout widget that manages an [AppLifecycleService]'s binding
/// observer lifecycle.
///
/// Place once near the app root so the service observes the app for its whole
/// lifetime; the widget attaches in `initState` and detaches in `dispose`.
class AppLifecycleObserver extends ConsumerStatefulWidget {
  /// Creates an app lifecycle observer.
  const AppLifecycleObserver({super.key});

  @override
  ConsumerState<AppLifecycleObserver> createState() =>
      _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver> {
  @override
  void initState() {
    super.initState();
    ref.read(appLifecycleServiceProvider).attach();
  }

  @override
  void dispose() {
    ref.read(appLifecycleServiceProvider).detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appLifecycleServiceProvider);
    return const SizedBox.shrink();
  }
}

/// Provides the app-wide [AppLifecycleService].
///
/// Add [AppLifecycleObserver] once near the root to manage the binding
/// observer lifecycle (the app wires this in, not this file).
final Provider<AppLifecycleService> appLifecycleServiceProvider =
    Provider<AppLifecycleService>((ref) => AppLifecycleService());
