//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'confirm_photo_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConfirmPhotoDto {
  /// Returns a new [ConfirmPhotoDto] instance.
  ConfirmPhotoDto({

    required  this.fileKey,

    required  this.mimeType,

    required  this.sizeBytes,
  });

  @JsonKey(
    
    name: r'fileKey',
    required: true,
    includeIfNull: false,
  )


  final String fileKey;



      /// MIME-type финализированного файла
  @JsonKey(
    
    name: r'mimeType',
    required: true,
    includeIfNull: false,
  )


  final String mimeType;



  @JsonKey(
    
    name: r'sizeBytes',
    required: true,
    includeIfNull: false,
  )


  final num sizeBytes;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ConfirmPhotoDto &&
      other.fileKey == fileKey &&
      other.mimeType == mimeType &&
      other.sizeBytes == sizeBytes;

    @override
    int get hashCode =>
        fileKey.hashCode +
        mimeType.hashCode +
        sizeBytes.hashCode;

  factory ConfirmPhotoDto.fromJson(Map<String, dynamic> json) => _$ConfirmPhotoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ConfirmPhotoDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

