// Tests for the clipboard service.
//
// The flutter/platform channel is mocked so Clipboard.setData/getData and
// the haptic feedback calls are captured without a device.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/services/clipboard/clipboard_service.dart';
import 'package:forge/core/services/error_handling/forge_failures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  String? clipboardText;

  setUp(() {
    calls = [];
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'Clipboard.setData':
          clipboardText = call.arguments['text'] as String;
          return null;
        case 'Clipboard.getData':
          return clipboardText == null
              ? null
              : <String, dynamic>{'text': clipboardText};
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  ClipboardService service() =>
      ClipboardService(hapticFeedback: false);

  test('copyText writes to the clipboard', () async {
    final result = await service().copyText('hello');

    expect(result.isSuccess, isTrue);
    expect(clipboardText, 'hello');
  });

  test('readText returns the clipboard text', () async {
    clipboardText = 'stored';
    final result = await service().readText();

    expect(result.valueOrNull, 'stored');
  });

  test('copyJson writes pretty-printed JSON', () async {
    final result = await service().copyJson({'a': 1});

    expect(result.isSuccess, isTrue);
    expect(clipboardText, contains('"a": 1'));
  });

  test('clear empties the clipboard', () async {
    clipboardText = 'stored';
    await service().clear();

    expect(clipboardText, '');
  });

  test('clear is called through the platform channel', () async {
    await service().clear();

    expect(calls.any((call) => call.method == 'Clipboard.setData'), isTrue);
  });

  test('a thrown platform error becomes a ClipboardFailure', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      throw PlatformException(code: 'channel-error');
    });

    final result = await service().copyText('boom');

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ClipboardFailure>());
  });
}
