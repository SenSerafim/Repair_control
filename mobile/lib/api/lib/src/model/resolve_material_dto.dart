//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'resolve_material_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ResolveMaterialDto {
  /// Returns a new [ResolveMaterialDto] instance.
  ResolveMaterialDto({

    required  this.resolution,
  });

  @JsonKey(
    
    name: r'resolution',
    required: true,
    includeIfNull: false,
  )


  final String resolution;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ResolveMaterialDto &&
      other.resolution == resolution;

    @override
    int get hashCode =>
        resolution.hashCode;

  factory ResolveMaterialDto.fromJson(Map<String, dynamic> json) => _$ResolveMaterialDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ResolveMaterialDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

