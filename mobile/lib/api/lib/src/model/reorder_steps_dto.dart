//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:repair_control_api/src/model/reorder_step_item_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reorder_steps_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReorderStepsDto {
  /// Returns a new [ReorderStepsDto] instance.
  ReorderStepsDto({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<ReorderStepItemDto> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReorderStepsDto &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ReorderStepsDto.fromJson(Map<String, dynamic> json) => _$ReorderStepsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReorderStepsDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

