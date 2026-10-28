// Tests for the notification service.
//
// The no-op implementation must never touch a platform plugin, so a plain
// test process is enough.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:forge/core/services/notifications/notification_service.dart';

void main() {
  group('NoOpNotificationService', () {
    const service = NoOpNotificationService();
    const notification = ForgeNotification(
      id: 'reminder',
      title: 'Time to train',
      body: 'Your workout is ready.',
      payload: 'workout/42',
      priority: 2,
    );

    test('initialize reports unsupported', () async {
      expect(await service.initialize(), NotificationResult.unsupported);
    });

    test('show reports unsupported', () async {
      expect(await service.show(notification), NotificationResult.unsupported);
    });

    test('cancel reports unsupported', () async {
      expect(await service.cancel('reminder'), NotificationResult.unsupported);
    });

    test('requestPermission completes without throwing', () async {
      await service.requestPermission();
    });

    test('cancelAll completes without throwing', () async {
      await service.cancelAll();
    });
  });
}
