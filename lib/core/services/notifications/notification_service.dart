// Notification service for the Forge application.
//
// Architecture-only: Forge does not yet ship local notifications, so the
// default [NoOpNotificationService] is a placeholder. When notifications land,
// replace it with a flutter_local_notifications-backed service. Scheduling is
// deliberately not implemented yet.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single notification payload.
class ForgeNotification {
  /// Creates a notification.
  const ForgeNotification({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
    this.priority,
  });

  /// Stable identifier used to cancel the notification.
  final String id;

  /// The notification title.
  final String title;

  /// The notification body.
  final String body;

  /// Optional deep-link data delivered with the notification.
  final String? payload;

  /// Optional priority hint for the platform.
  final int? priority;
}

/// The outcome of a notification operation.
enum NotificationResult {
  /// The notification was displayed.
  shown,

  /// The notification was queued for a later time.
  scheduled,

  /// The notification was removed.
  dismissed,

  /// The user denied permission to post notifications.
  denied,

  /// The platform or current implementation cannot perform the operation.
  unsupported,
}

/// Shows and manages notifications.
abstract class NotificationService {
  /// Prepares the platform and returns the readiness outcome.
  Future<NotificationResult> initialize();

  /// Displays [notification] immediately.
  Future<NotificationResult> show(ForgeNotification notification);

  /// Cancels the notification with [id].
  Future<NotificationResult> cancel(String id);

  /// Requests permission to post notifications.
  Future<void> requestPermission();

  /// Removes every pending and delivered notification.
  Future<void> cancelAll();
}

/// [NotificationService] that does nothing yet.
///
/// Returns [NotificationResult.unsupported] for every operation and no-ops the
/// permission methods. Replace with a flutter_local_notifications-backed
/// implementation when notifications ship; scheduling is intentionally not
/// implemented.
class NoOpNotificationService implements NotificationService {
  /// Creates the no-op service.
  const NoOpNotificationService();

  @override
  Future<NotificationResult> initialize() async =>
      NotificationResult.unsupported;

  @override
  Future<NotificationResult> show(ForgeNotification notification) async =>
      NotificationResult.unsupported;

  @override
  Future<NotificationResult> cancel(String id) async =>
      NotificationResult.unsupported;

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> cancelAll() async {}
}

/// Provides the app-wide [NotificationService].
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NoOpNotificationService(),
);
