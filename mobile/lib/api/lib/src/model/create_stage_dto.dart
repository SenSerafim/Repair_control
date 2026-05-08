//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_stage_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateStageDto {
  /// Returns a new [CreateStageDto] instance.
  CreateStageDto({

    required  this.title,

     this.orderIndex,

     this.plannedStart,

     this.plannedEnd,

     this.workBudget,

     this.materialsBudget,

     this.foremanIds,
  });

  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'orderIndex',
    required: false,
    includeIfNull: false,
  )


  final num? orderIndex;



  @JsonKey(
    
    name: r'plannedStart',
    required: false,
    includeIfNull: false,
  )


  final String? plannedStart;



  @JsonKey(
    
    name: r'plannedEnd',
    required: false,
    includeIfNull: false,
  )


  final String? plannedEnd;



  @JsonKey(
    
    name: r'workBudget',
    required: false,
    includeIfNull: false,
  )


  final int? workBudget;



  @JsonKey(
    
    name: r'materialsBudget',
    required: false,
    includeIfNull: false,
  )


  final int? materialsBudget;



  @JsonKey(
    
    name: r'foremanIds',
    required: false,
    includeIfNull: false,
  )


  final List<String>? foremanIds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateStageDto &&
      other.title == title &&
      other.orderIndex == orderIndex &&
      other.plannedStart == plannedStart &&
      other.plannedEnd == plannedEnd &&
      other.workBudget == workBudget &&
      other.materialsBudget == materialsBudget &&
      other.foremanIds == foremanIds;

    @override
    int get hashCode =>
        title.hashCode +
        orderIndex.hashCode +
        plannedStart.hashCode +
        plannedEnd.hashCode +
        workBudget.hashCode +
        materialsBudget.hashCode +
        foremanIds.hashCode;

  factory CreateStageDto.fromJson(Map<String, dynamic> json) => _$CreateStageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateStageDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

