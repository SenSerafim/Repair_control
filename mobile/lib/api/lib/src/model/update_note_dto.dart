//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'update_note_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateNoteDto {
  /// Returns a new [UpdateNoteDto] instance.
  UpdateNoteDto({

    required  this.text,
  });

  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateNoteDto &&
      other.text == text;

    @override
    int get hashCode =>
        text.hashCode;

  factory UpdateNoteDto.fromJson(Map<String, dynamic> json) => _$UpdateNoteDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateNoteDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

