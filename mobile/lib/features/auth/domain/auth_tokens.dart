import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_tokens.freezed.dart';
part 'auth_tokens.g.dart';

@freezed
class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}

@freezed
class LoginResult with _$LoginResult {
  const factory LoginResult({
    required String userId,
    required String systemRole,
    required AuthTokens tokens,
  }) = _LoginResult;

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
        userId: json['userId'] as String,
        systemRole: json['systemRole'] as String,
        tokens: AuthTokens(
          accessToken: json['accessToken'] as String,
          refreshToken: json['refreshToken'] as String,
          expiresIn: (json['expiresIn'] as num).toInt(),
        ),
      );
}

@freezed
class RegisterResult with _$RegisterResult {
  const factory RegisterResult({
    required String userId,
    required AuthTokens tokens,
  }) = _RegisterResult;

  factory RegisterResult.fromJson(Map<String, dynamic> json) => RegisterResult(
        userId: json['userId'] as String,
        tokens: AuthTokens(
          accessToken: json['accessToken'] as String,
          refreshToken: json['refreshToken'] as String,
          expiresIn: (json['expiresIn'] as num).toInt(),
        ),
      );
}
