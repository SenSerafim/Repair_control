//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_self_purchase_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateSelfPurchaseDto {
  /// Returns a new [CreateSelfPurchaseDto] instance.
  CreateSelfPurchaseDto({

    required  this.amount,

     this.stageId,

     this.comment,

     this.photoKeys,
  });

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
    
    name: r'photoKeys',
    required: false,
    includeIfNull: false,
  )


  final List<String>? photoKeys;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateSelfPurchaseDto &&
      other.amount == amount &&
      other.stageId == stageId &&
      other.comment == comment &&
      other.photoKeys == photoKeys;

    @override
    int get hashCode =>
        amount.hashCode +
        stageId.hashCode +
        comment.hashCode +
        photoKeys.hashCode;

  factory CreateSelfPurchaseDto.fromJson(Map<String, dynamic> json) => _$CreateSelfPurchaseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSelfPurchaseDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

