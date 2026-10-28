// Image service for the Forge application.
//
// Prepares progress photos: decode, resize, compress, generate thumbnails
// and read basic metadata, all pure on bytes so callers keep full control
// of where files land (via the FileService). Encoding is production-safe:
// unknown formats fall back to PNG rather than throwing.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../error_handling/forge_failures.dart';
import '../error_handling/result.dart';
import '../logger/forge_logger.dart';

/// The image formats Forge recognizes and can emit.
enum ForgeImageFormat {
  /// JPEG.
  jpeg,

  /// PNG.
  png,

  /// WebP.
  webp,

  /// GIF.
  gif,

  /// BMP.
  bmp,

  /// TIFF.
  tiff,

  /// An unsupported or unknown format.
  unknown,
}

/// Static metadata about an image.
class ForgeImageMetadata {
  /// Creates image metadata.
  const ForgeImageMetadata({
    required this.width,
    required this.height,
    required this.format,
    required this.byteLength,
    required this.hasAlpha,
  });

  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;

  /// Detected format.
  final ForgeImageFormat format;

  /// Size of the source bytes.
  final int byteLength;

  /// Whether the image has an alpha channel.
  final bool hasAlpha;
}

/// A decoded or processed image plus its dimensions.
class ForgeProcessedImage {
  /// Creates a processed image.
  const ForgeProcessedImage({
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
  });

  /// The encoded image bytes.
  final Uint8List bytes;

  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;

  /// The format the bytes were encoded as.
  final ForgeImageFormat format;

  /// The decoded pixel size.
  ForgeImageMetadata get metadata => ForgeImageMetadata(
        width: width,
        height: height,
        format: format,
        byteLength: bytes.length,
        hasAlpha: false,
      );
}

/// Image processing for progress photos and avatars.
class ImageService {
  /// Creates an image service.
  ImageService({ForgeLogger? logger}) : _logger = logger;

  /// Default JPEG quality (0-100) for compression.
  static const int defaultJpegQuality = 85;

  /// Default thumbnail edge length in pixels.
  static const int defaultThumbnailSize = 256;

  final ForgeLogger? _logger;

  /// Decodes [bytes] into a [ForgeProcessedImage] preserving the format.
  Future<Result<ForgeProcessedImage>> decode(Uint8List bytes) =>
      Result.tryAsync(
        () async {
          final image = _decodeImage(bytes);
          return _encodePreserving(image);
        },
        classify: _imageFailure,
      );

  /// Resizes [bytes] to fit within [maxWidth] x [maxHeight], aspect kept.
  Future<Result<ForgeProcessedImage>> resize(
    Uint8List bytes, {
    required int maxWidth,
    required int maxHeight,
  }) =>
      Result.tryAsync(
        () async {
          final image = _decodeImage(bytes);
          final scale = _fitScale(
            image.width,
            image.height,
            maxWidth,
            maxHeight,
          );
          final resized = img.copyResize(
            image,
            width: _scaled(image.width, scale),
            height: _scaled(image.height, scale),
            interpolation: img.Interpolation.average,
          );
          return _encodePreserving(resized);
        },
        classify: _imageFailure,
      );

  /// Re-encodes [bytes] as JPEG at [quality] (0-100) to shrink file size.
  ///
  /// Non-JPEG sources are converted to JPEG, which is lossy. Use [resize]
  /// on top of this for maximum savings.
  Future<Result<ForgeProcessedImage>> compress(
    Uint8List bytes, {
    int quality = defaultJpegQuality,
  }) =>
      Result.tryAsync(
        () async {
          final image = _decodeImage(bytes);
          return _encode(image, ForgeImageFormat.jpeg, quality: quality);
        },
        classify: _imageFailure,
      );

  /// Generates a square-ish thumbnail with its longest edge [size] pixels.
  Future<Result<ForgeProcessedImage>> thumbnail(
    Uint8List bytes, {
    int size = defaultThumbnailSize,
  }) =>
      Result.tryAsync(
        () async {
          final image = _decodeImage(bytes);
          final scale = size /
              (image.width >= image.height ? image.width : image.height);
          final thumb = img.copyResize(
            image,
            width: _scaled(image.width, scale),
            height: _scaled(image.height, scale),
            interpolation: img.Interpolation.average,
          );
          return _encodePreserving(thumb);
        },
        classify: _imageFailure,
      );

  /// Reads [bytes] for width, height, format and alpha without re-encoding.
  Future<Result<ForgeImageMetadata>> metadata(Uint8List bytes) =>
      Result.tryAsync(
        () async {
          final format = detectFormat(bytes);
          final image = _decodeImage(bytes);
          return ForgeImageMetadata(
            width: image.width,
            height: image.height,
            format: format,
            byteLength: bytes.length,
            hasAlpha: image.numChannels == 4,
          );
        },
        classify: _imageFailure,
      );

  /// Deletes the file at [path]; a missing file counts as success.
  Future<Result<void>> deleteFile(String path) => Result.tryAsync(
        () async {
          final file = File(path);
          if (await file.exists()) await file.delete();
        },
        classify: _imageFailure,
      );

  /// Detects [ForgeImageFormat] from magic bytes.
  static ForgeImageFormat detectFormat(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return ForgeImageFormat.jpeg;
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return ForgeImageFormat.png;
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return ForgeImageFormat.gif;
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return ForgeImageFormat.webp;
    }
    if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return ForgeImageFormat.bmp;
    }
    if (bytes.length >= 4 &&
        ((bytes[0] == 0x49 && bytes[1] == 0x49 && bytes[2] == 0x2A) ||
            (bytes[0] == 0x4D && bytes[1] == 0x4D && bytes[2] == 0x00))) {
      return ForgeImageFormat.tiff;
    }
    return ForgeImageFormat.unknown;
  }

  img.Image _decodeImage(Uint8List bytes) {
    final img.Image? image;
    try {
      image = img.decodeImage(bytes);
    } catch (_) {
      throw const FormatException('Unsupported or corrupt image data');
    }
    if (image == null) {
      throw const FormatException('Unsupported or corrupt image data');
    }
    // Honours EXIF orientation so dimensions match what is displayed.
    return img.bakeOrientation(image);
  }

  double _fitScale(int width, int height, int maxWidth, int maxHeight) {
    final widthScale = maxWidth / width;
    final heightScale = maxHeight / height;
    return widthScale < heightScale ? widthScale : heightScale;
  }

  int _scaled(int value, double scale) =>
      (value * scale).round().clamp(1, value);

  ForgeProcessedImage _encodePreserving(img.Image image) {
    final format = ForgeImageFormat.unknown;
    return _encode(image, format);
  }

  ForgeProcessedImage _encode(
    img.Image image,
    ForgeImageFormat format, {
    int quality = defaultJpegQuality,
  }) {
    final Uint8List bytes;
    final ForgeImageFormat outputFormat;
    switch (format) {
      case ForgeImageFormat.jpeg:
        bytes = img.encodeJpg(image, quality: quality);
        outputFormat = ForgeImageFormat.jpeg;
      case ForgeImageFormat.unknown:
      case ForgeImageFormat.gif:
      case ForgeImageFormat.bmp:
      case ForgeImageFormat.tiff:
      case ForgeImageFormat.png:
      case ForgeImageFormat.webp:
        bytes = img.encodePng(image);
        outputFormat = ForgeImageFormat.png;
    }
    return ForgeProcessedImage(
      bytes: bytes,
      width: image.width,
      height: image.height,
      format: outputFormat,
    );
  }

  ForgeFailure _imageFailure(Object error, StackTrace stackTrace) {
    _logger?.warning('Image operation failed', error, stackTrace);
    return switch (error) {
      FormatException() => ImageFailure(error.message, cause: error),
      FileSystemException() => ImageFailure(error.message, cause: error),
      _ => FailureMapper.toFailure(error, stackTrace: stackTrace),
    };
  }
}

/// The default [ImageService] for the app.
final imageServiceProvider = Provider<ImageService>((ref) => ImageService());
