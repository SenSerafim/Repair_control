//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'update_legal_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateLegalDto {
  /// Returns a new [UpdateLegalDto] instance.
  UpdateLegalDto({

     this.title,

     this.bodyMd,
  });

  @JsonKey(
    
    name: r'title',
    required: false,
    includeIfNull: false,
  )


  final String? title;



  @JsonKey(
    
    name: r'bodyMd',
    required: false,
    includeIfNull: false,
  )


  final String? bodyMd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateLegalDto &&
      other.title == title &&
      other.bodyMd == bodyMd;

    @override
    int get hashCode =>
        title.hashCode +
        bodyMd.hashCode;

  factory UpdateLegalDto.fromJson(Map<String, dynamic> json) => _$UpdateLegalDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateLegalDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

