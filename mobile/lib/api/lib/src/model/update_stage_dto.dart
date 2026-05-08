//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'update_stage_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateStageDto {
  /// Returns a new [UpdateStageDto] instance.
  UpdateStageDto({

     this.title,

     this.plannedStart,

     this.plannedEnd,

     this.workBudget,

     this.materialsBudget,

     this.foremanIds,
  });

  @JsonKey(
    
    name: r'title',
    required: false,
    includeIfNull: false,
  )


  final String? title;



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
    bool operator ==(Object other) => identical(this, other) || other is UpdateStageDto &&
      other.title == title &&
      other.plannedStart == plannedStart &&
      other.plannedEnd == plannedEnd &&
      other.workBudget == workBudget &&
      other.materialsBudget == materialsBudget &&
      other.foremanIds == foremanIds;

    @override
    int get hashCode =>
        title.hashCode +
        plannedStart.hashCode +
        plannedEnd.hashCode +
        workBudget.hashCode +
        materialsBudget.hashCode +
        foremanIds.hashCode;

  factory UpdateStageDto.fromJson(Map<String, dynamic> json) => _$UpdateStageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateStageDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

