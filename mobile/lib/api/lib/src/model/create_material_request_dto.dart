//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:repair_control_api/src/model/material_item_input_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_material_request_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateMaterialRequestDto {
  /// Returns a new [CreateMaterialRequestDto] instance.
  CreateMaterialRequestDto({

    required  this.recipient,

    required  this.title,

     this.stageId,

     this.comment,

    required  this.items,
  });

  @JsonKey(
    
    name: r'recipient',
    required: true,
    includeIfNull: false,
  )


  final CreateMaterialRequestDtoRecipientEnum recipient;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'stageId',
    required: false,
    includeIfNull: false,
  )


  final String? stageId;



  @JsonKey(
    
    name: r'comment',
    required: false,
    includeIfNull: false,
  )


  final String? comment;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<MaterialItemInputDto> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateMaterialRequestDto &&
      other.recipient == recipient &&
      other.title == title &&
      other.stageId == stageId &&
      other.comment == comment &&
      other.items == items;

    @override
    int get hashCode =>
        recipient.hashCode +
        title.hashCode +
        stageId.hashCode +
        comment.hashCode +
        items.hashCode;

  factory CreateMaterialRequestDto.fromJson(Map<String, dynamic> json) => _$CreateMaterialRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateMaterialRequestDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreateMaterialRequestDtoRecipientEnum {
@JsonValue(r'foreman')
foreman(r'foreman'),
@JsonValue(r'customer')
customer(r'customer');

const CreateMaterialRequestDtoRecipientEnum(this.value);

final String value;

@override
String toString() => value;
}


