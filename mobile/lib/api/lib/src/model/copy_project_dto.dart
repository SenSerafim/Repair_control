//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'copy_project_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CopyProjectDto {
  /// Returns a new [CopyProjectDto] instance.
  CopyProjectDto({

     this.newTitle,
  });

  @JsonKey(
    
    name: r'newTitle',
    required: false,
    includeIfNull: false,
  )


  final String? newTitle;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CopyProjectDto &&
      other.newTitle == newTitle;

    @override
    int get hashCode =>
        newTitle.hashCode;

  factory CopyProjectDto.fromJson(Map<String, dynamic> json) => _$CopyProjectDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CopyProjectDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

