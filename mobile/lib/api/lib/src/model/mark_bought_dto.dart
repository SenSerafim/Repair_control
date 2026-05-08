//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'mark_bought_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MarkBoughtDto {
  /// Returns a new [MarkBoughtDto] instance.
  MarkBoughtDto({

    required  this.pricePerUnit,
  });

      /// Цена за единицу в копейках (если не указана при создании)
  @JsonKey(
    
    name: r'pricePerUnit',
    required: true,
    includeIfNull: false,
  )


  final num pricePerUnit;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MarkBoughtDto &&
      other.pricePerUnit == pricePerUnit;

    @override
    int get hashCode =>
        pricePerUnit.hashCode;

  factory MarkBoughtDto.fromJson(Map<String, dynamic> json) => _$MarkBoughtDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MarkBoughtDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

