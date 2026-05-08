//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'broadcast_filter_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BroadcastFilterDto {
  /// Returns a new [BroadcastFilterDto] instance.
  BroadcastFilterDto({

     this.roles,

     this.projectIds,

     this.userIds,

     this.bannedOnly,
  });

  @JsonKey(
    
    name: r'roles',
    required: false,
    includeIfNull: false,
  )


  final List<RolesEnum>? roles;



  @JsonKey(
    
    name: r'projectIds',
    required: false,
    includeIfNull: false,
  )


  final List<String>? projectIds;



  @JsonKey(
    
    name: r'userIds',
    required: false,
    includeIfNull: false,
  )


  final List<String>? userIds;



  @JsonKey(
    
    name: r'bannedOnly',
    required: false,
    includeIfNull: false,
  )


  final bool? bannedOnly;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BroadcastFilterDto &&
      other.roles == roles &&
      other.projectIds == projectIds &&
      other.userIds == userIds &&
      other.bannedOnly == bannedOnly;

    @override
    int get hashCode =>
        roles.hashCode +
        projectIds.hashCode +
        userIds.hashCode +
        bannedOnly.hashCode;

  factory BroadcastFilterDto.fromJson(Map<String, dynamic> json) => _$BroadcastFilterDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BroadcastFilterDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum BroadcastFilterDtoRolesEnum {
@JsonValue(r'customer')
customer(r'customer'),
@JsonValue(r'representative')
representative(r'representative'),
@JsonValue(r'contractor')
contractor(r'contractor'),
@JsonValue(r'master')
master(r'master'),
@JsonValue(r'admin')
admin(r'admin');

const BroadcastFilterDtoRolesEnum(this.value);

final String value;

@override
String toString() => value;
}


