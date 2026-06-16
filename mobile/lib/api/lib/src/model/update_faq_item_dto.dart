//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'update_faq_item_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateFaqItemDto {
  /// Returns a new [UpdateFaqItemDto] instance.
  UpdateFaqItemDto({this.question, this.answer, this.orderIndex});

  @JsonKey(name: r'question', required: false, includeIfNull: false)
  final String? question;

  @JsonKey(name: r'answer', required: false, includeIfNull: false)
  final String? answer;

  @JsonKey(name: r'orderIndex', required: false, includeIfNull: false)
  final num? orderIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateFaqItemDto &&
          other.question == question &&
          other.answer == answer &&
          other.orderIndex == orderIndex;

  @override
  int get hashCode => question.hashCode + answer.hashCode + orderIndex.hashCode;

  factory UpdateFaqItemDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateFaqItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateFaqItemDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
