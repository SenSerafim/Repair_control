//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_step_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateStepDto {
  /// Returns a new [CreateStepDto] instance.
  CreateStepDto({

    required  this.title,

     this.type = const CreateStepDtoTypeEnum._('regular'),

     this.price,

     this.description,

     this.orderIndex,

     this.assigneeIds,
  });

  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    defaultValue: 'regular',
    name: r'type',
    required: false,
    includeIfNull: false,
  )


  final CreateStepDtoTypeEnum? type;



      /// Цена в копейках (обязательно для type=extra)
  @JsonKey(
    
    name: r'price',
    required: false,
    includeIfNull: false,
  )


  final num? price;



  @JsonKey(
    
    name: r'description',
    required: false,
    includeIfNull: false,
  )


  final String? description;



  @JsonKey(
    
    name: r'orderIndex',
    required: false,
    includeIfNull: false,
  )


  final num? orderIndex;



  @JsonKey(
    
    name: r'assigneeIds',
    required: false,
    includeIfNull: false,
  )


  final List<String>? assigneeIds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateStepDto &&
      other.title == title &&
      other.type == type &&
      other.price == price &&
      other.description == description &&
      other.orderIndex == orderIndex &&
      other.assigneeIds == assigneeIds;

    @override
    int get hashCode =>
        title.hashCode +
        type.hashCode +
        price.hashCode +
        description.hashCode +
        orderIndex.hashCode +
        assigneeIds.hashCode;

  factory CreateStepDto.fromJson(Map<String, dynamic> json) => _$CreateStepDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateStepDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreateStepDtoTypeEnum {
@JsonValue(r'regular')
regular(r'regular'),
@JsonValue(r'extra')
extra(r'extra');

const CreateStepDtoTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


