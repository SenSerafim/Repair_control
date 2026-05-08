//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'pause_stage_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PauseStageDto {
  /// Returns a new [PauseStageDto] instance.
  PauseStageDto({

    required  this.reason,

     this.comment,
  });

  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final PauseStageDtoReasonEnum reason;



  @JsonKey(
    
    name: r'comment',
    required: false,
    includeIfNull: false,
  )


  final String? comment;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PauseStageDto &&
      other.reason == reason &&
      other.comment == comment;

    @override
    int get hashCode =>
        reason.hashCode +
        comment.hashCode;

  factory PauseStageDto.fromJson(Map<String, dynamic> json) => _$PauseStageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PauseStageDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PauseStageDtoReasonEnum {
@JsonValue(r'materials')
materials(r'materials'),
@JsonValue(r'approval')
approval(r'approval'),
@JsonValue(r'force_majeure')
forceMajeure(r'force_majeure'),
@JsonValue(r'other')
other(r'other');

const PauseStageDtoReasonEnum(this.value);

final String value;

@override
String toString() => value;
}


