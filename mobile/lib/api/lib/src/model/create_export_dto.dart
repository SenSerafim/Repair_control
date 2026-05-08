//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_export_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateExportDto {
  /// Returns a new [CreateExportDto] instance.
  CreateExportDto({

    required  this.kind,

     this.kinds,

     this.stageId,

     this.dateFrom,

     this.dateTo,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final CreateExportDtoKindEnum kind;



  @JsonKey(
    
    name: r'kinds',
    required: false,
    includeIfNull: false,
  )


  final List<String>? kinds;



  @JsonKey(
    
    name: r'stageId',
    required: false,
    includeIfNull: false,
  )


  final String? stageId;



  @JsonKey(
    
    name: r'dateFrom',
    required: false,
    includeIfNull: false,
  )


  final String? dateFrom;



  @JsonKey(
    
    name: r'dateTo',
    required: false,
    includeIfNull: false,
  )


  final String? dateTo;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateExportDto &&
      other.kind == kind &&
      other.kinds == kinds &&
      other.stageId == stageId &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo;

    @override
    int get hashCode =>
        kind.hashCode +
        kinds.hashCode +
        stageId.hashCode +
        dateFrom.hashCode +
        dateTo.hashCode;

  factory CreateExportDto.fromJson(Map<String, dynamic> json) => _$CreateExportDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateExportDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreateExportDtoKindEnum {
@JsonValue(r'feed_pdf')
feedPdf(r'feed_pdf'),
@JsonValue(r'project_zip')
projectZip(r'project_zip');

const CreateExportDtoKindEnum(this.value);

final String value;

@override
String toString() => value;
}


