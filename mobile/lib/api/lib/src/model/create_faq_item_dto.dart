//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_faq_item_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateFaqItemDto {
  /// Returns a new [CreateFaqItemDto] instance.
  CreateFaqItemDto({

    required  this.sectionId,

    required  this.question,

    required  this.answer,

    required  this.orderIndex,
  });

  @JsonKey(
    
    name: r'sectionId',
    required: true,
    includeIfNull: false,
  )


  final String sectionId;



  @JsonKey(
    
    name: r'question',
    required: true,
    includeIfNull: false,
  )


  final String question;



  @JsonKey(
    
    name: r'answer',
    required: true,
    includeIfNull: false,
  )


  final String answer;



  @JsonKey(
    
    name: r'orderIndex',
    required: true,
    includeIfNull: false,
  )


  final num orderIndex;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateFaqItemDto &&
      other.sectionId == sectionId &&
      other.question == question &&
      other.answer == answer &&
      other.orderIndex == orderIndex;

    @override
    int get hashCode =>
        sectionId.hashCode +
        question.hashCode +
        answer.hashCode +
        orderIndex.hashCode;

  factory CreateFaqItemDto.fromJson(Map<String, dynamic> json) => _$CreateFaqItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateFaqItemDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

