// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_export_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateExportDto _$CreateExportDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateExportDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['kind']);
      final val = CreateExportDto(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$CreateExportDtoKindEnumEnumMap, v),
        ),
        kinds: $checkedConvert(
          'kinds',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        stageId: $checkedConvert('stageId', (v) => v as String?),
        dateFrom: $checkedConvert('dateFrom', (v) => v as String?),
        dateTo: $checkedConvert('dateTo', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CreateExportDtoToJson(CreateExportDto instance) =>
    <String, dynamic>{
      'kind': _$CreateExportDtoKindEnumEnumMap[instance.kind]!,
      if (instance.kinds case final value?) 'kinds': value,
      if (instance.stageId case final value?) 'stageId': value,
      if (instance.dateFrom case final value?) 'dateFrom': value,
      if (instance.dateTo case final value?) 'dateTo': value,
    };

const _$CreateExportDtoKindEnumEnumMap = {
  CreateExportDtoKindEnum.feedPdf: 'feed_pdf',
  CreateExportDtoKindEnum.projectZip: 'project_zip',
  CreateExportDtoKindEnum.projectReportPdf: 'project_report_pdf',
  CreateExportDtoKindEnum.projectSummaryTxt: 'project_summary_txt',
};
