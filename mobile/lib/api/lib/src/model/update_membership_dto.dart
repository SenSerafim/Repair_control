//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'update_membership_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateMembershipDto {
  /// Returns a new [UpdateMembershipDto] instance.
  UpdateMembershipDto({

     this.permissions,

     this.stageIds,
  });

  @JsonKey(
    
    name: r'permissions',
    required: false,
    includeIfNull: false,
  )


  final Object? permissions;



  @JsonKey(
    
    name: r'stageIds',
    required: false,
    includeIfNull: false,
  )


  final List<String>? stageIds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateMembershipDto &&
      other.permissions == permissions &&
      other.stageIds == stageIds;

    @override
    int get hashCode =>
        permissions.hashCode +
        stageIds.hashCode;

  factory UpdateMembershipDto.fromJson(Map<String, dynamic> json) => _$UpdateMembershipDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateMembershipDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

