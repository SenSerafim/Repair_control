// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_tokens.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthTokensImpl _$$AuthTokensImplFromJson(Map<String, dynamic> json) =>
    _$AuthTokensImpl(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
    );

Map<String, dynamic> _$$AuthTokensImplToJson(_$AuthTokensImpl instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresIn': instance.expiresIn,
    };

_$LoginResultImpl _$$LoginResultImplFromJson(Map<String, dynamic> json) =>
    _$LoginResultImpl(
      userId: json['userId'] as String,
      systemRole: json['systemRole'] as String,
      tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$LoginResultImplToJson(_$LoginResultImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'systemRole': instance.systemRole,
      'tokens': instance.tokens,
    };

_$RegisterResultImpl _$$RegisterResultImplFromJson(Map<String, dynamic> json) =>
    _$RegisterResultImpl(
      userId: json['userId'] as String,
      tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$RegisterResultImplToJson(
  _$RegisterResultImpl instance,
) => <String, dynamic>{'userId': instance.userId, 'tokens': instance.tokens};
