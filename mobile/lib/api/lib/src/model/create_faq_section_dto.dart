//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_faq_section_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateFaqSectionDto {
  /// Returns a new [CreateFaqSectionDto] instance.
  CreateFaqSectionDto({

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
    bool operator ==(Object other) => identical(this, other) || other is CreateFaqSectionDto &&
      other.title == title &&
      other.orderIndex == orderIndex;

    @override
    int get hashCode =>
        title.hashCode +
        orderIndex.hashCode;

  factory CreateFaqSectionDto.fromJson(Map<String, dynamic> json) => _$CreateFaqSectionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateFaqSectionDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

