//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'decide_approval_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecideApprovalDto {
  /// Returns a new [DecideApprovalDto] instance.
  DecideApprovalDto({

     this.comment,
  });

  @JsonKey(
    
    name: r'comment',
    required: false,
    includeIfNull: false,
  )


  final String? comment;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DecideApprovalDto &&
      other.comment == comment;

    @override
    int get hashCode =>
        comment.hashCode;

  factory DecideApprovalDto.fromJson(Map<String, dynamic> json) => _$DecideApprovalDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DecideApprovalDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

