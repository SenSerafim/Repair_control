// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'export_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ExportJob {
  String get id => throw _privateConstructorUsedError;
  String get projectId => throw _privateConstructorUsedError;
  ExportKind get kind => throw _privateConstructorUsedError;
  ExportStatus get status => throw _privateConstructorUsedError;
  String? get fileKey => throw _privateConstructorUsedError;
  String? get downloadUrl => throw _privateConstructorUsedError;
  int? get sizeBytes => throw _privateConstructorUsedError;
  String? get failureReason => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get startedAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;

  /// Create a copy of ExportJob
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExportJobCopyWith<ExportJob> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExportJobCopyWith<$Res> {
  factory $ExportJobCopyWith(ExportJob value, $Res Function(ExportJob) then) =
      _$ExportJobCopyWithImpl<$Res, ExportJob>;
  @useResult
  $Res call({
    String id,
    String projectId,
    ExportKind kind,
    ExportStatus status,
    String? fileKey,
    String? downloadUrl,
    int? sizeBytes,
    String? failureReason,
    DateTime createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
  });
}

/// @nodoc
class _$ExportJobCopyWithImpl<$Res, $Val extends ExportJob>
    implements $ExportJobCopyWith<$Res> {
  _$ExportJobCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExportJob
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? kind = null,
    Object? status = null,
    Object? fileKey = freezed,
    Object? downloadUrl = freezed,
    Object? sizeBytes = freezed,
    Object? failureReason = freezed,
    Object? createdAt = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? expiresAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            projectId: null == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as ExportKind,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ExportStatus,
            fileKey: freezed == fileKey
                ? _value.fileKey
                : fileKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            downloadUrl: freezed == downloadUrl
                ? _value.downloadUrl
                : downloadUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            sizeBytes: freezed == sizeBytes
                ? _value.sizeBytes
                : sizeBytes // ignore: cast_nullable_to_non_nullable
                      as int?,
            failureReason: freezed == failureReason
                ? _value.failureReason
                : failureReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExportJobImplCopyWith<$Res>
    implements $ExportJobCopyWith<$Res> {
  factory _$$ExportJobImplCopyWith(
    _$ExportJobImpl value,
    $Res Function(_$ExportJobImpl) then,
  ) = __$$ExportJobImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String projectId,
    ExportKind kind,
    ExportStatus status,
    String? fileKey,
    String? downloadUrl,
    int? sizeBytes,
    String? failureReason,
    DateTime createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
  });
}

/// @nodoc
class __$$ExportJobImplCopyWithImpl<$Res>
    extends _$ExportJobCopyWithImpl<$Res, _$ExportJobImpl>
    implements _$$ExportJobImplCopyWith<$Res> {
  __$$ExportJobImplCopyWithImpl(
    _$ExportJobImpl _value,
    $Res Function(_$ExportJobImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExportJob
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? kind = null,
    Object? status = null,
    Object? fileKey = freezed,
    Object? downloadUrl = freezed,
    Object? sizeBytes = freezed,
    Object? failureReason = freezed,
    Object? createdAt = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? expiresAt = freezed,
  }) {
    return _then(
      _$ExportJobImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        projectId: null == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as ExportKind,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ExportStatus,
        fileKey: freezed == fileKey
            ? _value.fileKey
            : fileKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        downloadUrl: freezed == downloadUrl
            ? _value.downloadUrl
            : downloadUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        sizeBytes: freezed == sizeBytes
            ? _value.sizeBytes
            : sizeBytes // ignore: cast_nullable_to_non_nullable
                  as int?,
        failureReason: freezed == failureReason
            ? _value.failureReason
            : failureReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$ExportJobImpl implements _ExportJob {
  const _$ExportJobImpl({
    required this.id,
    required this.projectId,
    required this.kind,
    required this.status,
    this.fileKey,
    this.downloadUrl,
    this.sizeBytes,
    this.failureReason,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.expiresAt,
  });

  @override
  final String id;
  @override
  final String projectId;
  @override
  final ExportKind kind;
  @override
  final ExportStatus status;
  @override
  final String? fileKey;
  @override
  final String? downloadUrl;
  @override
  final int? sizeBytes;
  @override
  final String? failureReason;
  @override
  final DateTime createdAt;
  @override
  final DateTime? startedAt;
  @override
  final DateTime? completedAt;
  @override
  final DateTime? expiresAt;

  @override
  String toString() {
    return 'ExportJob(id: $id, projectId: $projectId, kind: $kind, status: $status, fileKey: $fileKey, downloadUrl: $downloadUrl, sizeBytes: $sizeBytes, failureReason: $failureReason, createdAt: $createdAt, startedAt: $startedAt, completedAt: $completedAt, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExportJobImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.fileKey, fileKey) || other.fileKey == fileKey) &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.failureReason, failureReason) ||
                other.failureReason == failureReason) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    projectId,
    kind,
    status,
    fileKey,
    downloadUrl,
    sizeBytes,
    failureReason,
    createdAt,
    startedAt,
    completedAt,
    expiresAt,
  );

  /// Create a copy of ExportJob
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExportJobImplCopyWith<_$ExportJobImpl> get copyWith =>
      __$$ExportJobImplCopyWithImpl<_$ExportJobImpl>(this, _$identity);
}

abstract class _ExportJob implements ExportJob {
  const factory _ExportJob({
    required final String id,
    required final String projectId,
    required final ExportKind kind,
    required final ExportStatus status,
    final String? fileKey,
    final String? downloadUrl,
    final int? sizeBytes,
    final String? failureReason,
    required final DateTime createdAt,
    final DateTime? startedAt,
    final DateTime? completedAt,
    final DateTime? expiresAt,
  }) = _$ExportJobImpl;

  @override
  String get id;
  @override
  String get projectId;
  @override
  ExportKind get kind;
  @override
  ExportStatus get status;
  @override
  String? get fileKey;
  @override
  String? get downloadUrl;
  @override
  int? get sizeBytes;
  @override
  String? get failureReason;
  @override
  DateTime get createdAt;
  @override
  DateTime? get startedAt;
  @override
  DateTime? get completedAt;
  @override
  DateTime? get expiresAt;

  /// Create a copy of ExportJob
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExportJobImplCopyWith<_$ExportJobImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
