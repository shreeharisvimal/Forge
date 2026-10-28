// Haptics service for the Forge application.
//
// App-layer abstraction over the design system's HapticHelper. The design
// system stays the low-level platform channel wrapper; this service lets
// features depend on haptics through a single provider and honors a user
// setting that can disable feedback entirely.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/utilities/haptic_helper.dart';

/// The app-layer abstraction for haptic feedback.
///
/// Wraps [HapticHelper] (the low-level channel wrapper) behind an injectable
/// delegate so tests can substitute a fake without platform channels, and so
/// every feature can fire feedback through the shared [hapticsServiceProvider].
class HapticsService {
  /// Creates a haptics service.
  ///
  /// [delegate] defaults to [HapticHelper.fire]; pass a fake in tests.
  HapticsService({Future<void> Function(HapticType type)? delegate})
      : _delegate = delegate ?? HapticHelper.fire;

  final Future<void> Function(HapticType type) _delegate;

  /// Whether haptic feedback is enabled.
  ///
  /// A user setting: when false every call is a no-op.
  bool enabled = true;

  /// Fires the haptic matching [type].
  ///
  /// Safe to call fire-and-forget: errors from the platform are swallowed so
  /// feedback can never crash the app.
  Future<void> fire(HapticType type) async {
    if (!enabled) return;
    try {
      await _delegate(type);
    } catch (_) {}
  }

  /// Light tap feedback.
  Future<void> tap() => fire(HapticType.light);

  /// Subtle selection tick.
  Future<void> select() => fire(HapticType.selection);

  /// Success confirmation feedback.
  Future<void> success() => fire(HapticType.success);

  /// Warning feedback.
  Future<void> warning() => fire(HapticType.warning);

  /// Heavy confirmation feedback.
  Future<void> heavy() => fire(HapticType.heavy);

  /// Medium tap feedback.
  Future<void> medium() => fire(HapticType.medium);
}

/// Provides the app-wide [HapticsService].
final Provider<HapticsService> hapticsServiceProvider =
    Provider<HapticsService>((ref) => HapticsService());
