//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'reorder_item_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReorderItemDto {
  /// Returns a new [ReorderItemDto] instance.
  ReorderItemDto({

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
    bool operator ==(Object other) => identical(this, other) || other is ReorderItemDto &&
      other.id == id &&
      other.orderIndex == orderIndex;

    @override
    int get hashCode =>
        id.hashCode +
        orderIndex.hashCode;

  factory ReorderItemDto.fromJson(Map<String, dynamic> json) => _$ReorderItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReorderItemDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

