import 'package:freezed_annotation/freezed_annotation.dart';

part 'legal_document.freezed.dart';
part 'legal_document.g.dart';

/// Соответствует backend enum `LegalKind` (Prisma): privacy / tos / data_processing_consent.
/// Раньше mobile использовал 'privacy_policy' и 'terms_of_service' — это был
/// pre-existing баг: `_parseKind('privacy')` возвращал null, и пользователь
/// видел только один из трёх обязательных документов на регистрации.
enum LegalKind {
  @JsonValue('privacy')
  privacyPolicy,
  @JsonValue('tos')
  termsOfService,
  @JsonValue('data_processing_consent')
  dataProcessingConsent;

  String get apiValue => switch (this) {
        LegalKind.privacyPolicy => 'privacy',
        LegalKind.termsOfService => 'tos',
        LegalKind.dataProcessingConsent => 'data_processing_consent',
      };

  String get title => switch (this) {
        LegalKind.privacyPolicy => 'Политика конфиденциальности',
        LegalKind.termsOfService => 'Пользовательское соглашение',
        LegalKind.dataProcessingConsent => 'Согласие на обработку ПДн',
      };
}

@freezed
class LegalDocument with _$LegalDocument {
  const factory LegalDocument({
    required LegalKind kind,
    required String title,
    required int version,
    required String bodyMd,
    DateTime? publishedAt,
  }) = _LegalDocument;

  factory LegalDocument.fromJson(Map<String, dynamic> json) =>
      _$LegalDocumentFromJson(json);
}

/// Ответ `GET /api/me/legal-acceptance` — карта kind → статус.
@freezed
class LegalAcceptanceStatus with _$LegalAcceptanceStatus {
  const factory LegalAcceptanceStatus({
    required bool required_,
    required bool accepted,
    int? version,
  }) = _LegalAcceptanceStatus;

  factory LegalAcceptanceStatus.fromJson(Map<String, dynamic> json) =>
      LegalAcceptanceStatus(
        required_: json['required'] as bool? ?? false,
        accepted: json['accepted'] as bool? ?? false,
        version: (json['version'] as num?)?.toInt(),
      );
}
