// Connectivity service for the Forge application.
//
// Forge is offline-first: nothing depends on a network connection to work.
// This architecture-only service defines the contract features rely on today
// and the surface a real connectivity plugin will slot into later. Until then
// [OfflineConnectivityService] reports offline unconditionally, which is the
// safe default.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The device's network reachability.
///
/// Future work will split `online` into granular wifi/mobile/ethernet states.
enum ConnectivityStatus {
  /// The device is online and can reach the network.
  online,

  /// The device is offline.
  offline,
}

/// Tracks the device's network reachability.
abstract class ConnectivityService {
  /// The current connectivity status.
  ConnectivityStatus get status;

  /// Emits whenever the connectivity status changes.
  Stream<ConnectivityStatus> get changes;

  /// Re-queries the current status.
  Future<ConnectivityStatus> refresh();
}

/// The safe default connectivity service.
///
/// Forge is offline-first, so this implementation always reports [offline]
/// and its [changes] stream is a broadcast stream that never emits. It is
/// the default until a real connectivity plugin lands.
class OfflineConnectivityService implements ConnectivityService {
  final StreamController<ConnectivityStatus> _changes =
      StreamController<ConnectivityStatus>.broadcast();

  @override
  ConnectivityStatus get status => ConnectivityStatus.offline;

  @override
  Stream<ConnectivityStatus> get changes => _changes.stream;

  @override
  Future<ConnectivityStatus> refresh() async => ConnectivityStatus.offline;
}

/// A [ChangeNotifier] wrapper around a [ConnectivityService].
///
/// Exposes the current status to UI code and notifies listeners when the
/// wrapped service reports a change.
class ConnectivityController extends ChangeNotifier {
  /// Creates a controller wrapping [service].
  ConnectivityController(this._service) : _status = _service.status;

  final ConnectivityService _service;
  ConnectivityStatus _status;
  StreamSubscription<ConnectivityStatus>? _subscription;

  /// The latest connectivity status.
  ConnectivityStatus get status => _status;

  /// Subscribes to the wrapped service's change stream.
  void listen() {
    _subscription ??= _service.changes.listen(_onChanged);
  }

  void _onChanged(ConnectivityStatus next) {
    if (next == _status) return;
    _status = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provides the app-wide [ConnectivityService].
final Provider<ConnectivityService> connectivityServiceProvider =
    Provider<ConnectivityService>((ref) => OfflineConnectivityService());

/// Provides the app-wide [ConnectivityController].
///
/// Features read the current status with
/// `ref.watch(connectivityProvider).status`.
final Provider<ConnectivityController> connectivityProvider =
    Provider<ConnectivityController>((ref) {
  final controller =
      ConnectivityController(ref.watch(connectivityServiceProvider));
  ref.onDispose(controller.dispose);
  controller.listen();
  return controller;
});
