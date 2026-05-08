//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'add_participant_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddParticipantDto {
  /// Returns a new [AddParticipantDto] instance.
  AddParticipantDto({

    required  this.userId,
  });

  @JsonKey(
    
    name: r'userId',
    required: true,
    includeIfNull: false,
  )


  final String userId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AddParticipantDto &&
      other.userId == userId;

    @override
    int get hashCode =>
        userId.hashCode;

  factory AddParticipantDto.fromJson(Map<String, dynamic> json) => _$AddParticipantDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AddParticipantDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

