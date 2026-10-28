// Tests for the device service.
//
// The test binding exposes a default view and platform, so the assertions
// target the service's contract rather than any specific device.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/services/device/device_service.dart';
import 'package:forge/core/services/error_handling/result.dart';

class _FakeBatteryReader implements BatteryReader {
  @override
  Future<Result<int?>> level() async => Success(80);

  @override
  Future<Result<BatteryLevelState>> state() async =>
      const Success(BatteryLevelState.charging);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceService', () {
    test('platform is a known platform', () {
      final service = DeviceService();

      expect(service.platform, isNot(ForgePlatform.unknown));
    });

    test('platform boolean flags are consistent', () {
      final service = DeviceService();
      final platform = service.platform;

      expect(service.isMobile || service.isWeb, isTrue);
      expect(service.isAndroid, platform == ForgePlatform.android);
      expect(
        service.isApple,
        platform == ForgePlatform.ios || platform == ForgePlatform.macos,
      );
      expect(
        service.isMobile,
        platform == ForgePlatform.android || platform == ForgePlatform.ios,
      );
      expect(
        service.isDesktop,
        platform == ForgePlatform.macos ||
            platform == ForgePlatform.windows ||
            platform == ForgePlatform.linux,
      );
      expect(service.isWeb, platform == ForgePlatform.web);
    });

    test('brightness returns one of the known values', () {
      final service = DeviceService();

      expect(service.brightness(), isIn(ForgeBrightness.values));
      expect(
        service.systemDarkMode,
        service.brightness() == ForgeBrightness.dark,
      );
    });

    test('screenSize reads from the test view', () {
      final service = DeviceService();

      expect(service.screenSize().width, greaterThan(0));
      expect(service.screenSize().height, greaterThan(0));
    });

    test('devicePixelRatio is positive', () {
      final service = DeviceService();

      expect(service.devicePixelRatio, greaterThan(0));
    });

    test('battery returns unknown defaults', () async {
      final service = DeviceService();

      final level = await service.battery.level();
      final state = await service.battery.state();

      expect(level.isSuccess, isTrue);
      expect(level.valueOrNull, isNull);
      expect(state.isSuccess, isTrue);
      expect(state.valueOrNull, BatteryLevelState.unknown);
    });

    test('accepts an injected battery reader', () async {
      final reader = _FakeBatteryReader();
      final service = DeviceService(battery: reader);

      expect(service.battery, same(reader));

      final level = await service.battery.level();
      final state = await service.battery.state();

      expect(level.valueOrNull, 80);
      expect(state.valueOrNull, BatteryLevelState.charging);
    });
  });
}
