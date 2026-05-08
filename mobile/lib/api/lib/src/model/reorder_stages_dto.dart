//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:repair_control_api/src/model/reorder_item_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reorder_stages_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReorderStagesDto {
  /// Returns a new [ReorderStagesDto] instance.
  ReorderStagesDto({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<ReorderItemDto> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReorderStagesDto &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ReorderStagesDto.fromJson(Map<String, dynamic> json) => _$ReorderStagesDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReorderStagesDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

