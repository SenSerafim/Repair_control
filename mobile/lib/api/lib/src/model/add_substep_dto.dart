//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'add_substep_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddSubstepDto {
  /// Returns a new [AddSubstepDto] instance.
  AddSubstepDto({

    required  this.text,
  });

  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AddSubstepDto &&
      other.text == text;

    @override
    int get hashCode =>
        text.hashCode;

  factory AddSubstepDto.fromJson(Map<String, dynamic> json) => _$AddSubstepDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AddSubstepDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

