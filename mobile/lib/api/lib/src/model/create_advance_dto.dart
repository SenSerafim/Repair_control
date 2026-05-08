//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_advance_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateAdvanceDto {
  /// Returns a new [CreateAdvanceDto] instance.
  CreateAdvanceDto({

    required  this.toUserId,

    required  this.amount,

     this.stageId,

     this.comment,

     this.photoKey,
  });

      /// Получатель (foreman)
  @JsonKey(
    
    name: r'toUserId',
    required: true,
    includeIfNull: false,
  )


  final String toUserId;



      /// Сумма в копейках
  @JsonKey(
    
    name: r'amount',
    required: true,
    includeIfNull: false,
  )


  final num amount;



  @JsonKey(
    
    name: r'stageId',
    required: false,
    includeIfNull: false,
  )


  final String? stageId;



  @JsonKey(
    
    name: r'comment',
    required: false,
    includeIfNull: false,
  )


  final String? comment;



  @JsonKey(
    
    name: r'photoKey',
    required: false,
    includeIfNull: false,
  )


  final String? photoKey;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateAdvanceDto &&
      other.toUserId == toUserId &&
      other.amount == amount &&
      other.stageId == stageId &&
      other.comment == comment &&
      other.photoKey == photoKey;

    @override
    int get hashCode =>
        toUserId.hashCode +
        amount.hashCode +
        stageId.hashCode +
        comment.hashCode +
        photoKey.hashCode;

  factory CreateAdvanceDto.fromJson(Map<String, dynamic> json) => _$CreateAdvanceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateAdvanceDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

