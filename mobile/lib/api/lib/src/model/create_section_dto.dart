//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_section_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateSectionDto {
  /// Returns a new [CreateSectionDto] instance.
  CreateSectionDto({

    required  this.title,

    required  this.orderIndex,
  });

  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'orderIndex',
    required: true,
    includeIfNull: false,
  )


  final num orderIndex;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateSectionDto &&
      other.title == title &&
      other.orderIndex == orderIndex;

    @override
    int get hashCode =>
        title.hashCode +
        orderIndex.hashCode;

  factory CreateSectionDto.fromJson(Map<String, dynamic> json) => _$CreateSectionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSectionDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

