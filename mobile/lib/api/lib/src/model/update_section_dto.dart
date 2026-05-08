//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'update_section_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateSectionDto {
  /// Returns a new [UpdateSectionDto] instance.
  UpdateSectionDto({

     this.title,

     this.orderIndex,
  });

  @JsonKey(
    
    name: r'title',
    required: false,
    includeIfNull: false,
  )


  final String? title;



  @JsonKey(
    
    name: r'orderIndex',
    required: false,
    includeIfNull: false,
  )


  final num? orderIndex;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateSectionDto &&
      other.title == title &&
      other.orderIndex == orderIndex;

    @override
    int get hashCode =>
        title.hashCode +
        orderIndex.hashCode;

  factory UpdateSectionDto.fromJson(Map<String, dynamic> json) => _$UpdateSectionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateSectionDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

