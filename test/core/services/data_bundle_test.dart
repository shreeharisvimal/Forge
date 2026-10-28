// Tests for the data bundle codec shared by export, import and backup.
//
// Covers envelope round-trips, format/version/checksum validation and the
// gzip helpers, all against in-memory snapshots.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge/core/services/data_bundle.dart';
import 'package:forge/core/services/data_registry.dart';
import 'package:forge/core/services/error_handling/forge_failures.dart';
import 'package:forge/database/box_names.dart';

void main() {
  DataSnapshot snapshot({String recordId = 'id-1'}) => DataSnapshot(
        createdAt: DateTime.utc(2026, 1, 15, 10, 30),
        boxes: {
          BoxNames.settings: {
            recordId: {
              'weightUnit': 'kg',
              'theme': 'system',
            },
          },
        },
      );

  group('build', () {
    test('produces a bundle with format, version, app version and checksum',
        () {
      final bundle = DataBundleCodec.build(snapshot());

      expect(bundle.format, ForgeDataFormat.name);
      expect(bundle.formatVersion, ForgeDataFormat.version);
      expect(bundle.appVersion, isNotEmpty);
      expect(bundle.checksum, hasLength(64));
      expect(bundle.snapshot.boxes[BoxNames.settings], hasLength(1));
    });

    test('checksum is deterministic for equal snapshots', () {
      expect(
        DataBundleCodec.build(snapshot()).checksum,
        DataBundleCodec.build(snapshot()).checksum,
      );
    });
  });

  group('encode/decode', () {
    test('encode then decode round-trips the bundle', () {
      final bytes = DataBundleCodec.encode(DataBundleCodec.build(snapshot()));

      final result = DataBundleCodec.decode(bytes);

      expect(result.isSuccess, isTrue);
      final bundle = result.valueOrNull!;
      expect(bundle.snapshot.boxes[BoxNames.settings]!['id-1']!['weightUnit'], 'kg');
      expect(bundle.createdAt.millisecondsSinceEpoch,
          DateTime.utc(2026, 1, 15, 10, 30).millisecondsSinceEpoch);
      expect(bundle.checksum, hasLength(64));
    });

    test('decode rejects malformed JSON', () {
      final result = DataBundleCodec.decode(
        Uint8List.fromList(utf8.encode('{not json')),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('decode rejects an unknown format name', () {
      final bundle = DataBundleCodec.build(snapshot());
      final map = bundle.toJson();
      map['format'] = 'other-app';
      final result = DataBundleCodec.decode(
        Uint8List.fromList(utf8.encode(jsonEncode(map))),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('decode rejects a future format version', () {
      final bundle = DataBundleCodec.build(snapshot());
      final map = bundle.toJson();
      map['formatVersion'] = ForgeDataFormat.version + 1;
      final result = DataBundleCodec.decode(
        Uint8List.fromList(utf8.encode(jsonEncode(map))),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('decode rejects a tampered payload via the checksum', () {
      final bundle = DataBundleCodec.build(snapshot());
      final map = bundle.toJson();
      map['data']['boxes'][BoxNames.settings]['id-1']['weightUnit'] = 'lbs';
      final result = DataBundleCodec.decode(
        Uint8List.fromList(utf8.encode(jsonEncode(map))),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('gzip', () {
    test('compress then decompress round-trips bytes', () {
      final original = DataBundleCodec.encode(DataBundleCodec.build(snapshot()));

      final compressed = DataBundleCodec.compress(original);
      final result = DataBundleCodec.decompress(compressed);

      expect(DataBundleCodec.isGzip(compressed), isTrue);
      expect(result.valueOrNull, original);
    });

    test('compressed JSON is smaller than the raw JSON', () {
      final original = DataBundleCodec.encode(DataBundleCodec.build(snapshot()));
      expect(DataBundleCodec.compress(original).length, lessThan(original.length));
    });

    test('decompressing non-gzip bytes fails', () {
      final result = DataBundleCodec.decompress(Uint8List.fromList([1, 2, 3]));
      expect(result.isFailure, isTrue);
    });

    test('isGzip detects the gzip magic bytes', () {
      expect(DataBundleCodec.isGzip(Uint8List.fromList([0x1F, 0x8B, 0x08])), isTrue);
      expect(DataBundleCodec.isGzip(Uint8List.fromList([0x1F, 0x00])), isFalse);
      expect(DataBundleCodec.isGzip(Uint8List.fromList([])), isFalse);
    });
  });

  test('gzip codec round-trips through dart:io directly', () {
    final payload = Uint8List.fromList(List<int>.generate(1000, (i) => i % 7));
    final roundTrip = gzip.decode(gzip.encode(payload));
    expect(roundTrip, payload);
  });
}
