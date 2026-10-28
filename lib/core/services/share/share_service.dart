// Share service for the Forge application.
//
// Prepares future export sharing behind a small abstraction. The current
// offline-first implementation shares by copying the payload text to the
// clipboard; a system share-sheet implementation can be swapped in later
// without touching callers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../clipboard/clipboard_service.dart';
import '../error_handling/forge_failures.dart';
import '../error_handling/result.dart';

/// The content to share.
class ForgeSharePayload {
  /// Creates a share payload.
  const ForgeSharePayload({
    required this.title,
    required this.text,
    this.filePath,
    this.mimeType,
  });

  /// A short title describing the shared content.
  final String title;

  /// The text representation of the content.
  final String text;

  /// An optional file path of an artifact to share alongside the text.
  final String? filePath;

  /// The MIME type of [filePath], when present.
  final String? mimeType;
}

/// Shares [ForgeSharePayload]s with the rest of the device.
abstract class ShareService {
  /// Shares [payload], returning a typed [Result].
  Future<Result<void>> share(ForgeSharePayload payload);
}

/// A share implementation that copies the payload text to the clipboard.
///
/// A pragmatic offline-safe default: the user can paste the shared content
/// into any app. Replace with a system share sheet when sharing ships.
class ClipboardShareService implements ShareService {
  /// Creates a clipboard share service.
  ClipboardShareService({ClipboardService? clipboard}) : _clipboard = clipboard ?? ClipboardService();

  final ClipboardService _clipboard;

  @override
  Future<Result<void>> share(ForgeSharePayload payload) async {
    final result = await _clipboard.copyText(payload.text);
    return result.when(
      success: (_) => const Success(null),
      failure: (failure) => Failure(
        ShareFailure('Could not share "$payload.title".', cause: failure),
      ),
    );
  }
}

/// The default [ShareService] for the app.
final shareServiceProvider = Provider<ShareService>(
  (ref) => ClipboardShareService(),
);
