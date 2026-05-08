//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'answer_question_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AnswerQuestionDto {
  /// Returns a new [AnswerQuestionDto] instance.
  AnswerQuestionDto({

    required  this.answer,
  });

  @JsonKey(
    
    name: r'answer',
    required: true,
    includeIfNull: false,
  )


  final String answer;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AnswerQuestionDto &&
      other.answer == answer;

    @override
    int get hashCode =>
        answer.hashCode;

  factory AnswerQuestionDto.fromJson(Map<String, dynamic> json) => _$AnswerQuestionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AnswerQuestionDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

