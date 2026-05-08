// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'legal_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LegalDocument _$LegalDocumentFromJson(Map<String, dynamic> json) {
  return _LegalDocument.fromJson(json);
}

/// @nodoc
mixin _$LegalDocument {
  LegalKind get kind => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  String get bodyMd => throw _privateConstructorUsedError;
  DateTime? get publishedAt => throw _privateConstructorUsedError;

  /// Serializes this LegalDocument to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LegalDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LegalDocumentCopyWith<LegalDocument> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LegalDocumentCopyWith<$Res> {
  factory $LegalDocumentCopyWith(
    LegalDocument value,
    $Res Function(LegalDocument) then,
  ) = _$LegalDocumentCopyWithImpl<$Res, LegalDocument>;
  @useResult
  $Res call({
    LegalKind kind,
    String title,
    int version,
    String bodyMd,
    DateTime? publishedAt,
  });
}

/// @nodoc
class _$LegalDocumentCopyWithImpl<$Res, $Val extends LegalDocument>
    implements $LegalDocumentCopyWith<$Res> {
  _$LegalDocumentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LegalDocument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? title = null,
    Object? version = null,
    Object? bodyMd = null,
    Object? publishedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as LegalKind,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            version: null == version
                ? _value.version
                : version // ignore: cast_nullable_to_non_nullable
                      as int,
            bodyMd: null == bodyMd
                ? _value.bodyMd
                : bodyMd // ignore: cast_nullable_to_non_nullable
                      as String,
            publishedAt: freezed == publishedAt
                ? _value.publishedAt
                : publishedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LegalDocumentImplCopyWith<$Res>
    implements $LegalDocumentCopyWith<$Res> {
  factory _$$LegalDocumentImplCopyWith(
    _$LegalDocumentImpl value,
    $Res Function(_$LegalDocumentImpl) then,
  ) = __$$LegalDocumentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    LegalKind kind,
    String title,
    int version,
    String bodyMd,
    DateTime? publishedAt,
  });
}

/// @nodoc
class __$$LegalDocumentImplCopyWithImpl<$Res>
    extends _$LegalDocumentCopyWithImpl<$Res, _$LegalDocumentImpl>
    implements _$$LegalDocumentImplCopyWith<$Res> {
  __$$LegalDocumentImplCopyWithImpl(
    _$LegalDocumentImpl _value,
    $Res Function(_$LegalDocumentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LegalDocument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? title = null,
    Object? version = null,
    Object? bodyMd = null,
    Object? publishedAt = freezed,
  }) {
    return _then(
      _$LegalDocumentImpl(
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as LegalKind,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        version: null == version
            ? _value.version
            : version // ignore: cast_nullable_to_non_nullable
                  as int,
        bodyMd: null == bodyMd
            ? _value.bodyMd
            : bodyMd // ignore: cast_nullable_to_non_nullable
                  as String,
        publishedAt: freezed == publishedAt
            ? _value.publishedAt
            : publishedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LegalDocumentImpl implements _LegalDocument {
  const _$LegalDocumentImpl({
    required this.kind,
    required this.title,
    required this.version,
    required this.bodyMd,
    this.publishedAt,
  });

  factory _$LegalDocumentImpl.fromJson(Map<String, dynamic> json) =>
      _$$LegalDocumentImplFromJson(json);

  @override
  final LegalKind kind;
  @override
  final String title;
  @override
  final int version;
  @override
  final String bodyMd;
  @override
  final DateTime? publishedAt;

  @override
  String toString() {
    return 'LegalDocument(kind: $kind, title: $title, version: $version, bodyMd: $bodyMd, publishedAt: $publishedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LegalDocumentImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.bodyMd, bodyMd) || other.bodyMd == bodyMd) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, kind, title, version, bodyMd, publishedAt);

  /// Create a copy of LegalDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LegalDocumentImplCopyWith<_$LegalDocumentImpl> get copyWith =>
      __$$LegalDocumentImplCopyWithImpl<_$LegalDocumentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LegalDocumentImplToJson(this);
  }
}

abstract class _LegalDocument implements LegalDocument {
  const factory _LegalDocument({
    required final LegalKind kind,
    required final String title,
    required final int version,
    required final String bodyMd,
    final DateTime? publishedAt,
  }) = _$LegalDocumentImpl;

  factory _LegalDocument.fromJson(Map<String, dynamic> json) =
      _$LegalDocumentImpl.fromJson;

  @override
  LegalKind get kind;
  @override
  String get title;
  @override
  int get version;
  @override
  String get bodyMd;
  @override
  DateTime? get publishedAt;

  /// Create a copy of LegalDocument
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LegalDocumentImplCopyWith<_$LegalDocumentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LegalAcceptanceStatus _$LegalAcceptanceStatusFromJson(
  Map<String, dynamic> json,
) {
  return _LegalAcceptanceStatus.fromJson(json);
}

/// @nodoc
mixin _$LegalAcceptanceStatus {
  bool get required_ => throw _privateConstructorUsedError;
  bool get accepted => throw _privateConstructorUsedError;
  int? get version => throw _privateConstructorUsedError;

  /// Serializes this LegalAcceptanceStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LegalAcceptanceStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LegalAcceptanceStatusCopyWith<LegalAcceptanceStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LegalAcceptanceStatusCopyWith<$Res> {
  factory $LegalAcceptanceStatusCopyWith(
    LegalAcceptanceStatus value,
    $Res Function(LegalAcceptanceStatus) then,
  ) = _$LegalAcceptanceStatusCopyWithImpl<$Res, LegalAcceptanceStatus>;
  @useResult
  $Res call({bool required_, bool accepted, int? version});
}

/// @nodoc
class _$LegalAcceptanceStatusCopyWithImpl<
  $Res,
  $Val extends LegalAcceptanceStatus
>
    implements $LegalAcceptanceStatusCopyWith<$Res> {
  _$LegalAcceptanceStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LegalAcceptanceStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? required_ = null,
    Object? accepted = null,
    Object? version = freezed,
  }) {
    return _then(
      _value.copyWith(
            required_: null == required_
                ? _value.required_
                : required_ // ignore: cast_nullable_to_non_nullable
                      as bool,
            accepted: null == accepted
                ? _value.accepted
                : accepted // ignore: cast_nullable_to_non_nullable
                      as bool,
            version: freezed == version
                ? _value.version
                : version // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LegalAcceptanceStatusImplCopyWith<$Res>
    implements $LegalAcceptanceStatusCopyWith<$Res> {
  factory _$$LegalAcceptanceStatusImplCopyWith(
    _$LegalAcceptanceStatusImpl value,
    $Res Function(_$LegalAcceptanceStatusImpl) then,
  ) = __$$LegalAcceptanceStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool required_, bool accepted, int? version});
}

/// @nodoc
class __$$LegalAcceptanceStatusImplCopyWithImpl<$Res>
    extends
        _$LegalAcceptanceStatusCopyWithImpl<$Res, _$LegalAcceptanceStatusImpl>
    implements _$$LegalAcceptanceStatusImplCopyWith<$Res> {
  __$$LegalAcceptanceStatusImplCopyWithImpl(
    _$LegalAcceptanceStatusImpl _value,
    $Res Function(_$LegalAcceptanceStatusImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LegalAcceptanceStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? required_ = null,
    Object? accepted = null,
    Object? version = freezed,
  }) {
    return _then(
      _$LegalAcceptanceStatusImpl(
        required_: null == required_
            ? _value.required_
            : required_ // ignore: cast_nullable_to_non_nullable
                  as bool,
        accepted: null == accepted
            ? _value.accepted
            : accepted // ignore: cast_nullable_to_non_nullable
                  as bool,
        version: freezed == version
            ? _value.version
            : version // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LegalAcceptanceStatusImpl implements _LegalAcceptanceStatus {
  const _$LegalAcceptanceStatusImpl({
    required this.required_,
    required this.accepted,
    this.version,
  });

  factory _$LegalAcceptanceStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$LegalAcceptanceStatusImplFromJson(json);

  @override
  final bool required_;
  @override
  final bool accepted;
  @override
  final int? version;

  @override
  String toString() {
    return 'LegalAcceptanceStatus(required_: $required_, accepted: $accepted, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LegalAcceptanceStatusImpl &&
            (identical(other.required_, required_) ||
                other.required_ == required_) &&
            (identical(other.accepted, accepted) ||
                other.accepted == accepted) &&
            (identical(other.version, version) || other.version == version));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, required_, accepted, version);

  /// Create a copy of LegalAcceptanceStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LegalAcceptanceStatusImplCopyWith<_$LegalAcceptanceStatusImpl>
  get copyWith =>
      __$$LegalAcceptanceStatusImplCopyWithImpl<_$LegalAcceptanceStatusImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LegalAcceptanceStatusImplToJson(this);
  }
}

abstract class _LegalAcceptanceStatus implements LegalAcceptanceStatus {
  const factory _LegalAcceptanceStatus({
    required final bool required_,
    required final bool accepted,
    final int? version,
  }) = _$LegalAcceptanceStatusImpl;

  factory _LegalAcceptanceStatus.fromJson(Map<String, dynamic> json) =
      _$LegalAcceptanceStatusImpl.fromJson;

  @override
  bool get required_;
  @override
  bool get accepted;
  @override
  int? get version;

  /// Create a copy of LegalAcceptanceStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LegalAcceptanceStatusImplCopyWith<_$LegalAcceptanceStatusImpl>
  get copyWith => throw _privateConstructorUsedError;
}
