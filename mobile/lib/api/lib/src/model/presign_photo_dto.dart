//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'presign_photo_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PresignPhotoDto {
  /// Returns a new [PresignPhotoDto] instance.
  PresignPhotoDto({required this.mime, required this.size, this.originalName});

  /// MIME-type: image/jpeg | image/png
  @JsonKey(name: r'mime', required: true, includeIfNull: false)
  final String mime;

  /// Размер файла в байтах
  @JsonKey(name: r'size', required: true, includeIfNull: false)
  final num size;

  @JsonKey(name: r'originalName', required: false, includeIfNull: false)
  final String? originalName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresignPhotoDto &&
          other.mime == mime &&
          other.size == size &&
          other.originalName == originalName;

  @override
  int get hashCode => mime.hashCode + size.hashCode + originalName.hashCode;

  factory PresignPhotoDto.fromJson(Map<String, dynamic> json) =>
      _$PresignPhotoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PresignPhotoDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
