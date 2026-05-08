//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'reorder_step_item_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReorderStepItemDto {
  /// Returns a new [ReorderStepItemDto] instance.
  ReorderStepItemDto({

    required  this.id,

    required  this.orderIndex,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'orderIndex',
    required: true,
    includeIfNull: false,
  )


  final num orderIndex;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReorderStepItemDto &&
      other.id == id &&
      other.orderIndex == orderIndex;

    @override
    int get hashCode =>
        id.hashCode +
        orderIndex.hashCode;

  factory ReorderStepItemDto.fromJson(Map<String, dynamic> json) => _$ReorderStepItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReorderStepItemDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

