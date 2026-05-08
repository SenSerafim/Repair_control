//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:repair_control_api/src/model/broadcast_filter_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'send_broadcast_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SendBroadcastDto {
  /// Returns a new [SendBroadcastDto] instance.
  SendBroadcastDto({

    required  this.title,

    required  this.body,

     this.deepLink,

    required  this.filter,
  });

  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'body',
    required: true,
    includeIfNull: false,
  )


  final String body;



  @JsonKey(
    
    name: r'deepLink',
    required: false,
    includeIfNull: false,
  )


  final String? deepLink;



  @JsonKey(
    
    name: r'filter',
    required: true,
    includeIfNull: false,
  )


  final BroadcastFilterDto filter;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SendBroadcastDto &&
      other.title == title &&
      other.body == body &&
      other.deepLink == deepLink &&
      other.filter == filter;

    @override
    int get hashCode =>
        title.hashCode +
        body.hashCode +
        deepLink.hashCode +
        filter.hashCode;

  factory SendBroadcastDto.fromJson(Map<String, dynamic> json) => _$SendBroadcastDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SendBroadcastDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

