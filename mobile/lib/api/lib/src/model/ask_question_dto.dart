//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'ask_question_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AskQuestionDto {
  /// Returns a new [AskQuestionDto] instance.
  AskQuestionDto({

    required  this.text,

    required  this.addresseeId,
  });

  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;



  @JsonKey(
    
    name: r'addresseeId',
    required: true,
    includeIfNull: false,
  )


  final String addresseeId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AskQuestionDto &&
      other.text == text &&
      other.addresseeId == addresseeId;

    @override
    int get hashCode =>
        text.hashCode +
        addresseeId.hashCode;

  factory AskQuestionDto.fromJson(Map<String, dynamic> json) => _$AskQuestionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AskQuestionDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

