//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'material_item_input_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MaterialItemInputDto {
  /// Returns a new [MaterialItemInputDto] instance.
  MaterialItemInputDto({

    required  this.name,

    required  this.qty,

     this.unit,

     this.note,

     this.pricePerUnit,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'qty',
    required: true,
    includeIfNull: false,
  )


  final num qty;



  @JsonKey(
    
    name: r'unit',
    required: false,
    includeIfNull: false,
  )


  final String? unit;



  @JsonKey(
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;



      /// Цена за единицу в копейках
  @JsonKey(
    
    name: r'pricePerUnit',
    required: false,
    includeIfNull: false,
  )


  final num? pricePerUnit;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MaterialItemInputDto &&
      other.name == name &&
      other.qty == qty &&
      other.unit == unit &&
      other.note == note &&
      other.pricePerUnit == pricePerUnit;

    @override
    int get hashCode =>
        name.hashCode +
        qty.hashCode +
        unit.hashCode +
        note.hashCode +
        pricePerUnit.hashCode;

  factory MaterialItemInputDto.fromJson(Map<String, dynamic> json) => _$MaterialItemInputDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MaterialItemInputDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

