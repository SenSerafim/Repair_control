//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'dispute_material_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DisputeMaterialDto {
  /// Returns a new [DisputeMaterialDto] instance.
  DisputeMaterialDto({

    required  this.reason,
  });

  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DisputeMaterialDto &&
      other.reason == reason;

    @override
    int get hashCode =>
        reason.hashCode;

  factory DisputeMaterialDto.fromJson(Map<String, dynamic> json) => _$DisputeMaterialDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DisputeMaterialDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

