//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'update_profile_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateProfileDto {
  /// Returns a new [UpdateProfileDto] instance.
  UpdateProfileDto({

     this.firstName,

     this.lastName,

     this.avatarUrl,

     this.language,

     this.email,
  });

  @JsonKey(
    
    name: r'firstName',
    required: false,
    includeIfNull: false,
  )


  final String? firstName;



  @JsonKey(
    
    name: r'lastName',
    required: false,
    includeIfNull: false,
  )


  final String? lastName;



  @JsonKey(
    
    name: r'avatarUrl',
    required: false,
    includeIfNull: false,
  )


  final Object? avatarUrl;



  @JsonKey(
    
    name: r'language',
    required: false,
    includeIfNull: false,
  )


  final String? language;



  @JsonKey(
    
    name: r'email',
    required: false,
    includeIfNull: false,
  )


  final Object? email;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateProfileDto &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.avatarUrl == avatarUrl &&
      other.language == language &&
      other.email == email;

    @override
    int get hashCode =>
        firstName.hashCode +
        lastName.hashCode +
        (avatarUrl == null ? 0 : avatarUrl.hashCode) +
        language.hashCode +
        (email == null ? 0 : email.hashCode);

  factory UpdateProfileDto.fromJson(Map<String, dynamic> json) => _$UpdateProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateProfileDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

