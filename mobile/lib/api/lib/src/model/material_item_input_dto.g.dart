// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_item_input_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaterialItemInputDto _$MaterialItemInputDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('MaterialItemInputDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'qty']);
  final val = MaterialItemInputDto(
    name: $checkedConvert('name', (v) => v as String),
    qty: $checkedConvert('qty', (v) => v as num),
    unit: $checkedConvert('unit', (v) => v as String?),
    note: $checkedConvert('note', (v) => v as String?),
    pricePerUnit: $checkedConvert('pricePerUnit', (v) => v as num?),
  );
  return val;
});

Map<String, dynamic> _$MaterialItemInputDtoToJson(
  MaterialItemInputDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'qty': instance.qty,
  if (instance.unit case final value?) 'unit': value,
  if (instance.note case final value?) 'note': value,
  if (instance.pricePerUnit case final value?) 'pricePerUnit': value,
};
