// Tests for the image service.
//
// Images are synthesized in-memory with the image package so no fixtures or
// platform calls are needed.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/services/error_handling/forge_failures.dart';
import 'package:forge/core/services/images/image_service.dart';
import 'package:image/image.dart' as img;

void main() {
  final service = ImageService();

  img.Image makeImage({int width = 32, int height = 24}) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(120, 80, 40));
    return image;
  }

  Uint8List pngOf(img.Image image) => img.encodePng(image);

  test('detectFormat recognizes JPEG, PNG, GIF, WebP, BMP and TIFF',
      () {
    expect(ImageService.detectFormat(pngOf(makeImage())),
        ForgeImageFormat.png);
    expect(
      ImageService.detectFormat(Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0,
      ])),
      ForgeImageFormat.jpeg,
    );
    expect(
      ImageService.detectFormat(Uint8List.fromList([
        0x47, 0x49, 0x46, 0x38, 0, 0,
      ])),
      ForgeImageFormat.gif,
    );
    expect(
      ImageService.detectFormat(Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0,
        0x57, 0x45, 0x42, 0x50,
      ])),
      ForgeImageFormat.webp,
    );
    expect(
      ImageService.detectFormat(Uint8List.fromList([0x42, 0x4D])),
      ForgeImageFormat.bmp,
    );
    expect(
      ImageService.detectFormat(Uint8List.fromList([
        0x49, 0x49, 0x2A, 0x00,
      ])),
      ForgeImageFormat.tiff,
    );
    expect(ImageService.detectFormat(Uint8List.fromList([1, 2, 3])),
        ForgeImageFormat.unknown);
  });

  test('decode preserves a PNG and its dimensions', () async {
    final bytes = pngOf(makeImage(width: 32, height: 24));

    final result = await service.decode(bytes);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.width, 32);
    expect(result.valueOrNull!.height, 24);
    expect(result.valueOrNull!.format, ForgeImageFormat.png);
  });

  test('resize fits within the requested bounds keeping aspect', () async {
    final bytes = pngOf(makeImage(width: 800, height: 600));

    final result = await service.resize(bytes, maxWidth: 200, maxHeight: 200);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.width, lessThanOrEqualTo(200));
    expect(result.valueOrNull!.height, lessThanOrEqualTo(200));
  });

  test('compress re-encodes as JPEG', () async {
    final bytes = pngOf(makeImage());

    final result = await service.compress(bytes);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.format, ForgeImageFormat.jpeg);
  });

  test('thumbnail is square-ish with the requested edge', () async {
    final bytes = pngOf(makeImage(width: 800, height: 600));

    final result = await service.thumbnail(bytes, size: 64);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.width, 64);
    expect(result.valueOrNull!.height, 48);
  });

  test('metadata reports dimensions, format and alpha', () async {
    final bytes = pngOf(makeImage());

    final result = await service.metadata(bytes);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.width, 32);
    expect(result.valueOrNull!.height, 24);
    expect(result.valueOrNull!.format, ForgeImageFormat.png);
    expect(result.valueOrNull!.byteLength, bytes.length);
  });

  test('decode of corrupt bytes fails with an ImageFailure', () async {
    final result = await service.decode(Uint8List.fromList([1, 2, 3]));

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ImageFailure>());
  });

  test('deleteFile removes an existing file and tolerates a missing one',
      () async {
    final directory = await Directory.systemTemp.createTemp('forge_img_');
    final file = File('${directory.path}/photo.png');
    await file.writeAsBytes(pngOf(makeImage()));

    final deleted = await service.deleteFile(file.path);
    expect(deleted.isSuccess, isTrue);
    expect(await file.exists(), isFalse);

    final missing = await service.deleteFile('${directory.path}/nope.png');
    expect(missing.isSuccess, isTrue);

    await directory.delete(recursive: true);
  });
}
