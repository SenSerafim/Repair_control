import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:repair_control/shared/utils/image_compress.dart';

void main() {
  group('compressImage', () {
    test('non-image input → null', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      expect(compressImage(bytes), isNull);
    });

    test('3000×2000 PNG → ≤1920 JPEG', () {
      final original = img.Image(width: 3000, height: 2000);
      final raw = Uint8List.fromList(img.encodePng(original));
      final result = compressImage(raw);
      expect(result, isNotNull);
      expect(result!.mimeType, 'image/jpeg');
      expect(result.width, 1920);
      expect(result.height, 1280); // 2000 * (1920/3000)
      expect(result.sha256, hasLength(64));
      expect(result.bytes.length, greaterThan(0));
    });

    test('height > width → ресайз по height', () {
      final original = img.Image(width: 1000, height: 4000);
      final raw = Uint8List.fromList(img.encodePng(original));
      final result = compressImage(raw);
      expect(result, isNotNull);
      expect(result!.height, 1920);
      expect(result.width, 480); // 1000 * (1920/4000)
    });

    test('already <1920 — не увеличивается', () {
      final original = img.Image(width: 800, height: 600);
      final raw = Uint8List.fromList(img.encodePng(original));
      final result = compressImage(raw);
      expect(result, isNotNull);
      expect(result!.width, 800);
      expect(result.height, 600);
    });
  });
}
