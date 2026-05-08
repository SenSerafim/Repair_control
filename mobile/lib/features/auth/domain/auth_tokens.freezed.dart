// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_tokens.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) {
  return _AuthTokens.fromJson(json);
}

/// @nodoc
mixin _$AuthTokens {
  String get accessToken => throw _privateConstructorUsedError;
  String get refreshToken => throw _privateConstructorUsedError;
  int get expiresIn => throw _privateConstructorUsedError;

  /// Serializes this AuthTokens to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthTokensCopyWith<AuthTokens> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthTokensCopyWith<$Res> {
  factory $AuthTokensCopyWith(
    AuthTokens value,
    $Res Function(AuthTokens) then,
  ) = _$AuthTokensCopyWithImpl<$Res, AuthTokens>;
  @useResult
  $Res call({String accessToken, String refreshToken, int expiresIn});
}

/// @nodoc
class _$AuthTokensCopyWithImpl<$Res, $Val extends AuthTokens>
    implements $AuthTokensCopyWith<$Res> {
  _$AuthTokensCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? expiresIn = null,
  }) {
    return _then(
      _value.copyWith(
            accessToken: null == accessToken
                ? _value.accessToken
                : accessToken // ignore: cast_nullable_to_non_nullable
                      as String,
            refreshToken: null == refreshToken
                ? _value.refreshToken
                : refreshToken // ignore: cast_nullable_to_non_nullable
                      as String,
            expiresIn: null == expiresIn
                ? _value.expiresIn
                : expiresIn // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthTokensImplCopyWith<$Res>
    implements $AuthTokensCopyWith<$Res> {
  factory _$$AuthTokensImplCopyWith(
    _$AuthTokensImpl value,
    $Res Function(_$AuthTokensImpl) then,
  ) = __$$AuthTokensImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String accessToken, String refreshToken, int expiresIn});
}

/// @nodoc
class __$$AuthTokensImplCopyWithImpl<$Res>
    extends _$AuthTokensCopyWithImpl<$Res, _$AuthTokensImpl>
    implements _$$AuthTokensImplCopyWith<$Res> {
  __$$AuthTokensImplCopyWithImpl(
    _$AuthTokensImpl _value,
    $Res Function(_$AuthTokensImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? expiresIn = null,
  }) {
    return _then(
      _$AuthTokensImpl(
        accessToken: null == accessToken
            ? _value.accessToken
            : accessToken // ignore: cast_nullable_to_non_nullable
                  as String,
        refreshToken: null == refreshToken
            ? _value.refreshToken
            : refreshToken // ignore: cast_nullable_to_non_nullable
                  as String,
        expiresIn: null == expiresIn
            ? _value.expiresIn
            : expiresIn // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthTokensImpl implements _AuthTokens {
  const _$AuthTokensImpl({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory _$AuthTokensImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthTokensImplFromJson(json);

  @override
  final String accessToken;
  @override
  final String refreshToken;
  @override
  final int expiresIn;

  @override
  String toString() {
    return 'AuthTokens(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthTokensImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken) &&
            (identical(other.expiresIn, expiresIn) ||
                other.expiresIn == expiresIn));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, accessToken, refreshToken, expiresIn);

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthTokensImplCopyWith<_$AuthTokensImpl> get copyWith =>
      __$$AuthTokensImplCopyWithImpl<_$AuthTokensImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthTokensImplToJson(this);
  }
}

abstract class _AuthTokens implements AuthTokens {
  const factory _AuthTokens({
    required final String accessToken,
    required final String refreshToken,
    required final int expiresIn,
  }) = _$AuthTokensImpl;

  factory _AuthTokens.fromJson(Map<String, dynamic> json) =
      _$AuthTokensImpl.fromJson;

  @override
  String get accessToken;
  @override
  String get refreshToken;
  @override
  int get expiresIn;

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthTokensImplCopyWith<_$AuthTokensImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LoginResult _$LoginResultFromJson(Map<String, dynamic> json) {
  return _LoginResult.fromJson(json);
}

/// @nodoc
mixin _$LoginResult {
  String get userId => throw _privateConstructorUsedError;
  String get systemRole => throw _privateConstructorUsedError;
  AuthTokens get tokens => throw _privateConstructorUsedError;

  /// Serializes this LoginResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoginResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoginResultCopyWith<LoginResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoginResultCopyWith<$Res> {
  factory $LoginResultCopyWith(
    LoginResult value,
    $Res Function(LoginResult) then,
  ) = _$LoginResultCopyWithImpl<$Res, LoginResult>;
  @useResult
  $Res call({String userId, String systemRole, AuthTokens tokens});

  $AuthTokensCopyWith<$Res> get tokens;
}

/// @nodoc
class _$LoginResultCopyWithImpl<$Res, $Val extends LoginResult>
    implements $LoginResultCopyWith<$Res> {
  _$LoginResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoginResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? systemRole = null,
    Object? tokens = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            systemRole: null == systemRole
                ? _value.systemRole
                : systemRole // ignore: cast_nullable_to_non_nullable
                      as String,
            tokens: null == tokens
                ? _value.tokens
                : tokens // ignore: cast_nullable_to_non_nullable
                      as AuthTokens,
          )
          as $Val,
    );
  }

  /// Create a copy of LoginResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AuthTokensCopyWith<$Res> get tokens {
    return $AuthTokensCopyWith<$Res>(_value.tokens, (value) {
      return _then(_value.copyWith(tokens: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LoginResultImplCopyWith<$Res>
    implements $LoginResultCopyWith<$Res> {
  factory _$$LoginResultImplCopyWith(
    _$LoginResultImpl value,
    $Res Function(_$LoginResultImpl) then,
  ) = __$$LoginResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String userId, String systemRole, AuthTokens tokens});

  @override
  $AuthTokensCopyWith<$Res> get tokens;
}

/// @nodoc
class __$$LoginResultImplCopyWithImpl<$Res>
    extends _$LoginResultCopyWithImpl<$Res, _$LoginResultImpl>
    implements _$$LoginResultImplCopyWith<$Res> {
  __$$LoginResultImplCopyWithImpl(
    _$LoginResultImpl _value,
    $Res Function(_$LoginResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LoginResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? systemRole = null,
    Object? tokens = null,
  }) {
    return _then(
      _$LoginResultImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        systemRole: null == systemRole
            ? _value.systemRole
            : systemRole // ignore: cast_nullable_to_non_nullable
                  as String,
        tokens: null == tokens
            ? _value.tokens
            : tokens // ignore: cast_nullable_to_non_nullable
                  as AuthTokens,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LoginResultImpl implements _LoginResult {
  const _$LoginResultImpl({
    required this.userId,
    required this.systemRole,
    required this.tokens,
  });

  factory _$LoginResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoginResultImplFromJson(json);

  @override
  final String userId;
  @override
  final String systemRole;
  @override
  final AuthTokens tokens;

  @override
  String toString() {
    return 'LoginResult(userId: $userId, systemRole: $systemRole, tokens: $tokens)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginResultImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.systemRole, systemRole) ||
                other.systemRole == systemRole) &&
            (identical(other.tokens, tokens) || other.tokens == tokens));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, systemRole, tokens);

  /// Create a copy of LoginResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginResultImplCopyWith<_$LoginResultImpl> get copyWith =>
      __$$LoginResultImplCopyWithImpl<_$LoginResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LoginResultImplToJson(this);
  }
}

abstract class _LoginResult implements LoginResult {
  const factory _LoginResult({
    required final String userId,
    required final String systemRole,
    required final AuthTokens tokens,
  }) = _$LoginResultImpl;

  factory _LoginResult.fromJson(Map<String, dynamic> json) =
      _$LoginResultImpl.fromJson;

  @override
  String get userId;
  @override
  String get systemRole;
  @override
  AuthTokens get tokens;

  /// Create a copy of LoginResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginResultImplCopyWith<_$LoginResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RegisterResult _$RegisterResultFromJson(Map<String, dynamic> json) {
  return _RegisterResult.fromJson(json);
}

/// @nodoc
mixin _$RegisterResult {
  String get userId => throw _privateConstructorUsedError;
  AuthTokens get tokens => throw _privateConstructorUsedError;

  /// Serializes this RegisterResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RegisterResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RegisterResultCopyWith<RegisterResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegisterResultCopyWith<$Res> {
  factory $RegisterResultCopyWith(
    RegisterResult value,
    $Res Function(RegisterResult) then,
  ) = _$RegisterResultCopyWithImpl<$Res, RegisterResult>;
  @useResult
  $Res call({String userId, AuthTokens tokens});

  $AuthTokensCopyWith<$Res> get tokens;
}

/// @nodoc
class _$RegisterResultCopyWithImpl<$Res, $Val extends RegisterResult>
    implements $RegisterResultCopyWith<$Res> {
  _$RegisterResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RegisterResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? userId = null, Object? tokens = null}) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            tokens: null == tokens
                ? _value.tokens
                : tokens // ignore: cast_nullable_to_non_nullable
                      as AuthTokens,
          )
          as $Val,
    );
  }

  /// Create a copy of RegisterResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AuthTokensCopyWith<$Res> get tokens {
    return $AuthTokensCopyWith<$Res>(_value.tokens, (value) {
      return _then(_value.copyWith(tokens: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RegisterResultImplCopyWith<$Res>
    implements $RegisterResultCopyWith<$Res> {
  factory _$$RegisterResultImplCopyWith(
    _$RegisterResultImpl value,
    $Res Function(_$RegisterResultImpl) then,
  ) = __$$RegisterResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String userId, AuthTokens tokens});

  @override
  $AuthTokensCopyWith<$Res> get tokens;
}

/// @nodoc
class __$$RegisterResultImplCopyWithImpl<$Res>
    extends _$RegisterResultCopyWithImpl<$Res, _$RegisterResultImpl>
    implements _$$RegisterResultImplCopyWith<$Res> {
  __$$RegisterResultImplCopyWithImpl(
    _$RegisterResultImpl _value,
    $Res Function(_$RegisterResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RegisterResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? userId = null, Object? tokens = null}) {
    return _then(
      _$RegisterResultImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        tokens: null == tokens
            ? _value.tokens
            : tokens // ignore: cast_nullable_to_non_nullable
                  as AuthTokens,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RegisterResultImpl implements _RegisterResult {
  const _$RegisterResultImpl({required this.userId, required this.tokens});

  factory _$RegisterResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$RegisterResultImplFromJson(json);

  @override
  final String userId;
  @override
  final AuthTokens tokens;

  @override
  String toString() {
    return 'RegisterResult(userId: $userId, tokens: $tokens)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegisterResultImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.tokens, tokens) || other.tokens == tokens));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, tokens);

  /// Create a copy of RegisterResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegisterResultImplCopyWith<_$RegisterResultImpl> get copyWith =>
      __$$RegisterResultImplCopyWithImpl<_$RegisterResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RegisterResultImplToJson(this);
  }
}

abstract class _RegisterResult implements RegisterResult {
  const factory _RegisterResult({
    required final String userId,
    required final AuthTokens tokens,
  }) = _$RegisterResultImpl;

  factory _RegisterResult.fromJson(Map<String, dynamic> json) =
      _$RegisterResultImpl.fromJson;

  @override
  String get userId;
  @override
  AuthTokens get tokens;

  /// Create a copy of RegisterResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegisterResultImplCopyWith<_$RegisterResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
