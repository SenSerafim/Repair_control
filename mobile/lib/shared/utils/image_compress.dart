import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

/// Результат компрессии: готовые байты + метаданные для /photos/confirm.
class CompressedImage {
  const CompressedImage({
    required this.bytes,
    required this.mimeType,
    required this.width,
    required this.height,
    required this.sha256,
  });

  final Uint8List bytes;
  final String mimeType;
  final int width;
  final int height;
  final String sha256;

  int get sizeBytes => bytes.length;
}

/// Сжимает изображение: max side = 1920 px, JPEG q=80. EXIF стирается
/// автоматически (package:image при re-encode в JPEG не копирует EXIF),
/// см. README package:image.
///
/// Возвращает null для непригодного ввода (не-изображение, слишком маленькое).
CompressedImage? compressImage(
  Uint8List raw, {
  int maxSide = 1920,
  int quality = 80,
}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(raw);
  } on Object {
    decoded = null;
  }
  if (decoded == null) return null;

  var image = decoded;
  if (image.width > maxSide || image.height > maxSide) {
    // resize keeps aspect, сам вычисляет меньшую сторону
    if (image.width >= image.height) {
      image = img.copyResize(image, width: maxSide);
    } else {
      image = img.copyResize(image, height: maxSide);
    }
  }

  final encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
  final digest = sha256.convert(encoded).toString();

  return CompressedImage(
    bytes: encoded,
    mimeType: 'image/jpeg',
    width: image.width,
    height: image.height,
    sha256: digest,
  );
}

/// Вспомогательно — base64 для debug/логирования (не для передачи).
// ignore: unused_element
String _debugBase64Preview(Uint8List bytes) =>
    base64Encode(bytes.sublist(0, bytes.length.clamp(0, 64)));
