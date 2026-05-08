//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'accept_legal_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AcceptLegalDto {
  /// Returns a new [AcceptLegalDto] instance.
  AcceptLegalDto({

    required  this.kind,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final AcceptLegalDtoKindEnum kind;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AcceptLegalDto &&
      other.kind == kind;

    @override
    int get hashCode =>
        kind.hashCode;

  factory AcceptLegalDto.fromJson(Map<String, dynamic> json) => _$AcceptLegalDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AcceptLegalDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum AcceptLegalDtoKindEnum {
@JsonValue(r'privacy')
privacy(r'privacy'),
@JsonValue(r'tos')
tos(r'tos'),
@JsonValue(r'data_processing_consent')
dataProcessingConsent(r'data_processing_consent');

const AcceptLegalDtoKindEnum(this.value);

final String value;

@override
String toString() => value;
}


