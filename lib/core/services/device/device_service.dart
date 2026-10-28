// Device service for the Forge application.
//
// Central access to platform and display facts: operating system, screen
// brightness, screen geometry and battery. Battery reads are pluggable
// because the battery plugin is future work; [UnknownBatteryReader] keeps
// every consumer safe until then.
library;

import 'dart:ui' show FlutterView;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error_handling/result.dart';

/// The operating system Forge is running on.
enum ForgePlatform {
  /// Android.
  android,

  /// iOS.
  ios,

  /// macOS.
  macos,

  /// Windows.
  windows,

  /// Linux.
  linux,

  /// Web.
  web,

  /// Any other (or unknown) platform.
  unknown,
}

/// The screen brightness mode.
enum ForgeBrightness {
  /// Light mode.
  light,

  /// Dark mode.
  dark,

  /// Could not be determined.
  unknown,
}

/// The battery charge state.
enum BatteryLevelState {
  /// The device is plugged in and charging.
  charging,

  /// The device is running on battery.
  discharging,

  /// Could not be determined.
  unknown,
}

/// Reads battery information from the device.
abstract class BatteryReader {
  /// The current battery charge level as a percentage, or null if unknown.
  Future<Result<int?>> level();

  /// The current battery charge state.
  Future<Result<BatteryLevelState>> state();
}

/// A [BatteryReader] that reports nothing.
///
/// The battery plugin is future work; this keeps consumers safe until a real
/// reader is wired in. Every call succeeds with an unknown/default value.
class UnknownBatteryReader implements BatteryReader {
  /// Creates an unknown battery reader.
  const UnknownBatteryReader();

  @override
  Future<Result<int?>> level() async => Success(null);

  @override
  Future<Result<BatteryLevelState>> state() async =>
      const Success(BatteryLevelState.unknown);
}

/// Answers platform and display questions about the current device.
class DeviceService {
  /// Creates a device service.
  ///
  /// [battery] defaults to an [UnknownBatteryReader].
  DeviceService({BatteryReader? battery})
      : battery = battery ?? const UnknownBatteryReader();

  /// The injected battery reader.
  final BatteryReader battery;

  WidgetsBinding? get _binding {
    try {
      return WidgetsBinding.instance;
    } catch (_) {
      return null;
    }
  }

  FlutterView? get _firstView {
    final binding = _binding;
    if (binding == null) return null;
    final views = binding.platformDispatcher.views;
    return views.isEmpty ? null : views.first;
  }

  /// The platform Forge is running on.
  ForgePlatform get platform {
    if (kIsWeb) return ForgePlatform.web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => ForgePlatform.android,
      TargetPlatform.iOS => ForgePlatform.ios,
      TargetPlatform.macOS => ForgePlatform.macos,
      TargetPlatform.windows => ForgePlatform.windows,
      TargetPlatform.linux => ForgePlatform.linux,
      TargetPlatform.fuchsia => ForgePlatform.unknown,
    };
  }

  /// Whether Forge runs on Android.
  bool get isAndroid => platform == ForgePlatform.android;

  /// Whether Forge runs on an Apple platform (iOS or macOS).
  bool get isApple =>
      platform == ForgePlatform.ios || platform == ForgePlatform.macos;

  /// Whether Forge runs on a mobile platform (Android or iOS).
  bool get isMobile =>
      platform == ForgePlatform.android || platform == ForgePlatform.ios;

  /// Whether Forge runs on a desktop platform (macOS, Windows or Linux).
  bool get isDesktop =>
      platform == ForgePlatform.macos ||
      platform == ForgePlatform.windows ||
      platform == ForgePlatform.linux;

  /// Whether Forge runs on the web.
  bool get isWeb => platform == ForgePlatform.web;

  /// The current screen brightness, or [ForgeBrightness.unknown] when the
  /// binding or the brightness value is unavailable.
  ForgeBrightness brightness() {
    final binding = _binding;
    if (binding == null) return ForgeBrightness.unknown;
    return switch (binding.platformDispatcher.platformBrightness) {
      Brightness.light => ForgeBrightness.light,
      Brightness.dark => ForgeBrightness.dark,
    };
  }

  /// Whether the system is in dark mode.
  bool get systemDarkMode => brightness() == ForgeBrightness.dark;

  /// The current screen size in logical pixels.
  ///
  /// Computed from the first view's physical size divided by its device pixel
  /// ratio; returns [Size.zero] when the binding or the view is unavailable.
  Size screenSize() {
    final view = _firstView;
    if (view == null) return Size.zero;
    final pixelRatio = view.devicePixelRatio;
    if (pixelRatio == 0) return Size.zero;
    return view.physicalSize / pixelRatio;
  }

  /// The current device pixel ratio.
  ///
  /// Returns one when the binding or the view is unavailable.
  double get devicePixelRatio {
    final view = _firstView;
    if (view == null) return 1.0;
    final pixelRatio = view.devicePixelRatio;
    return pixelRatio == 0 ? 1.0 : pixelRatio;
  }
}

/// Provides the app-wide [DeviceService].
final Provider<DeviceService> deviceServiceProvider =
    Provider<DeviceService>((ref) => DeviceService());
