// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LegalDocumentImpl _$$LegalDocumentImplFromJson(Map<String, dynamic> json) =>
    _$LegalDocumentImpl(
      kind: $enumDecode(_$LegalKindEnumMap, json['kind']),
      title: json['title'] as String,
      version: (json['version'] as num).toInt(),
      bodyMd: json['bodyMd'] as String,
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
    );

Map<String, dynamic> _$$LegalDocumentImplToJson(_$LegalDocumentImpl instance) =>
    <String, dynamic>{
      'kind': _$LegalKindEnumMap[instance.kind]!,
      'title': instance.title,
      'version': instance.version,
      'bodyMd': instance.bodyMd,
      'publishedAt': instance.publishedAt?.toIso8601String(),
    };

const _$LegalKindEnumMap = {
  LegalKind.privacyPolicy: 'privacy',
  LegalKind.termsOfService: 'tos',
  LegalKind.dataProcessingConsent: 'data_processing_consent',
};

_$LegalAcceptanceStatusImpl _$$LegalAcceptanceStatusImplFromJson(
  Map<String, dynamic> json,
) => _$LegalAcceptanceStatusImpl(
  required_: json['required_'] as bool,
  accepted: json['accepted'] as bool,
  version: (json['version'] as num?)?.toInt(),
);

Map<String, dynamic> _$$LegalAcceptanceStatusImplToJson(
  _$LegalAcceptanceStatusImpl instance,
) => <String, dynamic>{
  'required_': instance.required_,
  'accepted': instance.accepted,
  'version': instance.version,
};
