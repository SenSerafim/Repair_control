//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_message_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateMessageDto {
  /// Returns a new [CreateMessageDto] instance.
  CreateMessageDto({

     this.text,

     this.attachmentKeys,
  });

  @JsonKey(
    
    name: r'text',
    required: false,
    includeIfNull: false,
  )


  final String? text;



  @JsonKey(
    
    name: r'attachmentKeys',
    required: false,
    includeIfNull: false,
  )


  final List<String>? attachmentKeys;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateMessageDto &&
      other.text == text &&
      other.attachmentKeys == attachmentKeys;

    @override
    int get hashCode =>
        text.hashCode +
        attachmentKeys.hashCode;

  factory CreateMessageDto.fromJson(Map<String, dynamic> json) => _$CreateMessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateMessageDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

