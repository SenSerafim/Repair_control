//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'resubmit_approval_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ResubmitApprovalDto {
  /// Returns a new [ResubmitApprovalDto] instance.
  ResubmitApprovalDto({

     this.payload,

     this.attachmentKeys,
  });

      /// Обновлённый payload
  @JsonKey(
    
    name: r'payload',
    required: false,
    includeIfNull: false,
  )


  final Object? payload;



  @JsonKey(
    
    name: r'attachmentKeys',
    required: false,
    includeIfNull: false,
  )


  final List<String>? attachmentKeys;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ResubmitApprovalDto &&
      other.payload == payload &&
      other.attachmentKeys == attachmentKeys;

    @override
    int get hashCode =>
        payload.hashCode +
        attachmentKeys.hashCode;

  factory ResubmitApprovalDto.fromJson(Map<String, dynamic> json) => _$ResubmitApprovalDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ResubmitApprovalDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

