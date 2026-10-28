// Tests for the connectivity service.
//
// A fake [ConnectivityService] drives the controller through real state
// transitions so notification behavior is verifiable.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/services/connectivity/connectivity_service.dart';

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService(this._status);

  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _status;

  @override
  ConnectivityStatus get status => _status;

  @override
  Stream<ConnectivityStatus> get changes => _controller.stream;

  @override
  Future<ConnectivityStatus> refresh() async => _status;

  void emit(ConnectivityStatus next) {
    _status = next;
    _controller.add(next);
  }
}

void main() {
  group('OfflineConnectivityService', () {
    test('is always offline', () async {
      final service = OfflineConnectivityService();

      expect(service.status, ConnectivityStatus.offline);
      expect(await service.refresh(), ConnectivityStatus.offline);
    });

    test('changes is a broadcast stream that never emits', () async {
      final service = OfflineConnectivityService();

      await expectLater(
        service.changes.first.timeout(const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('ConnectivityController', () {
    test('reflects the wrapped service status', () {
      final service = _FakeConnectivityService(ConnectivityStatus.offline);
      final controller = ConnectivityController(service);

      expect(controller.status, ConnectivityStatus.offline);

      controller.dispose();
    });

    test('listens and notifies listeners on change', () async {
      final service = _FakeConnectivityService(ConnectivityStatus.offline);
      final controller = ConnectivityController(service);
      final notifications = <ConnectivityStatus>[];
      controller.addListener(() => notifications.add(controller.status));

      controller.listen();
      service.emit(ConnectivityStatus.online);
      await Future<void>.delayed(Duration.zero);

      expect(controller.status, ConnectivityStatus.online);
      expect(notifications, [ConnectivityStatus.online]);

      controller.dispose();
    });

    test('does not notify when the status is unchanged', () async {
      final service = _FakeConnectivityService(ConnectivityStatus.offline);
      final controller = ConnectivityController(service);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.listen();
      service.emit(ConnectivityStatus.offline);
      await Future<void>.delayed(Duration.zero);

      expect(notifications, 0);

      controller.dispose();
    });

    test('dispose unsubscribes from the service', () async {
      final service = _FakeConnectivityService(ConnectivityStatus.offline);
      final controller = ConnectivityController(service);
      controller.listen();
      controller.dispose();

      service.emit(ConnectivityStatus.online);
      await Future<void>.delayed(Duration.zero);

      expect(controller.status, ConnectivityStatus.offline);
    });
  });
}
