// Tests for the share service.
//
// The clipboard-backed implementation is exercised against a fake
// [ClipboardService] so failures surface as [ShareFailure]s.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/services/clipboard/clipboard_service.dart';
import 'package:forge/core/services/error_handling/forge_failures.dart';
import 'package:forge/core/services/error_handling/result.dart';
import 'package:forge/core/services/share/share_service.dart';

class _FakeClipboardService implements ClipboardService {
  _FakeClipboardService({this.failCopy = false});

  final bool failCopy;
  String? copied;

  @override
  Future<Result<void>> copyText(String text) async {
    if (failCopy) {
      return const Failure(ClipboardFailure('clipboard down'));
    }
    copied = text;
    return const Success(null);
  }

  @override
  Future<Result<String?>> readText() async => const Success(null);

  @override
  Future<Result<void>> copyJson(Map<String, dynamic> json) async =>
      const Success(null);

  @override
  Future<Result<void>> clear() async => const Success(null);
}

void main() {
  test('share copies the payload text to the clipboard', () async {
    final clipboard = _FakeClipboardService();
    final service = ClipboardShareService(clipboard: clipboard);

    final result = await service.share(
      const ForgeSharePayload(title: 'Export', text: 'payload'),
    );

    expect(result.isSuccess, isTrue);
    expect(clipboard.copied, 'payload');
  });

  test('a clipboard failure becomes a ShareFailure', () async {
    final service = ClipboardShareService(
      clipboard: _FakeClipboardService(failCopy: true),
    );

    final result = await service.share(
      const ForgeSharePayload(title: 'Export', text: 'payload'),
    );

    expect(result.isFailure, isTrue);
    final failure = result.failureOrNull;
    expect(failure, isA<ShareFailure>());
    expect(failure!.cause, isA<ClipboardFailure>());
  });
}
