// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'approval.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ApprovalAttempt {
  String get id => throw _privateConstructorUsedError;
  String get approvalId => throw _privateConstructorUsedError;
  int get attemptNumber => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  String get actorId => throw _privateConstructorUsedError;
  String? get comment => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of ApprovalAttempt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApprovalAttemptCopyWith<ApprovalAttempt> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApprovalAttemptCopyWith<$Res> {
  factory $ApprovalAttemptCopyWith(
    ApprovalAttempt value,
    $Res Function(ApprovalAttempt) then,
  ) = _$ApprovalAttemptCopyWithImpl<$Res, ApprovalAttempt>;
  @useResult
  $Res call({
    String id,
    String approvalId,
    int attemptNumber,
    String action,
    String actorId,
    String? comment,
    DateTime createdAt,
  });
}

/// @nodoc
class _$ApprovalAttemptCopyWithImpl<$Res, $Val extends ApprovalAttempt>
    implements $ApprovalAttemptCopyWith<$Res> {
  _$ApprovalAttemptCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApprovalAttempt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? approvalId = null,
    Object? attemptNumber = null,
    Object? action = null,
    Object? actorId = null,
    Object? comment = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            approvalId: null == approvalId
                ? _value.approvalId
                : approvalId // ignore: cast_nullable_to_non_nullable
                      as String,
            attemptNumber: null == attemptNumber
                ? _value.attemptNumber
                : attemptNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            action: null == action
                ? _value.action
                : action // ignore: cast_nullable_to_non_nullable
                      as String,
            actorId: null == actorId
                ? _value.actorId
                : actorId // ignore: cast_nullable_to_non_nullable
                      as String,
            comment: freezed == comment
                ? _value.comment
                : comment // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ApprovalAttemptImplCopyWith<$Res>
    implements $ApprovalAttemptCopyWith<$Res> {
  factory _$$ApprovalAttemptImplCopyWith(
    _$ApprovalAttemptImpl value,
    $Res Function(_$ApprovalAttemptImpl) then,
  ) = __$$ApprovalAttemptImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String approvalId,
    int attemptNumber,
    String action,
    String actorId,
    String? comment,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$ApprovalAttemptImplCopyWithImpl<$Res>
    extends _$ApprovalAttemptCopyWithImpl<$Res, _$ApprovalAttemptImpl>
    implements _$$ApprovalAttemptImplCopyWith<$Res> {
  __$$ApprovalAttemptImplCopyWithImpl(
    _$ApprovalAttemptImpl _value,
    $Res Function(_$ApprovalAttemptImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApprovalAttempt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? approvalId = null,
    Object? attemptNumber = null,
    Object? action = null,
    Object? actorId = null,
    Object? comment = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$ApprovalAttemptImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        approvalId: null == approvalId
            ? _value.approvalId
            : approvalId // ignore: cast_nullable_to_non_nullable
                  as String,
        attemptNumber: null == attemptNumber
            ? _value.attemptNumber
            : attemptNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        action: null == action
            ? _value.action
            : action // ignore: cast_nullable_to_non_nullable
                  as String,
        actorId: null == actorId
            ? _value.actorId
            : actorId // ignore: cast_nullable_to_non_nullable
                  as String,
        comment: freezed == comment
            ? _value.comment
            : comment // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$ApprovalAttemptImpl implements _ApprovalAttempt {
  const _$ApprovalAttemptImpl({
    required this.id,
    required this.approvalId,
    required this.attemptNumber,
    required this.action,
    required this.actorId,
    this.comment,
    required this.createdAt,
  });

  @override
  final String id;
  @override
  final String approvalId;
  @override
  final int attemptNumber;
  @override
  final String action;
  @override
  final String actorId;
  @override
  final String? comment;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'ApprovalAttempt(id: $id, approvalId: $approvalId, attemptNumber: $attemptNumber, action: $action, actorId: $actorId, comment: $comment, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApprovalAttemptImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.approvalId, approvalId) ||
                other.approvalId == approvalId) &&
            (identical(other.attemptNumber, attemptNumber) ||
                other.attemptNumber == attemptNumber) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.actorId, actorId) || other.actorId == actorId) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    approvalId,
    attemptNumber,
    action,
    actorId,
    comment,
    createdAt,
  );

  /// Create a copy of ApprovalAttempt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApprovalAttemptImplCopyWith<_$ApprovalAttemptImpl> get copyWith =>
      __$$ApprovalAttemptImplCopyWithImpl<_$ApprovalAttemptImpl>(
        this,
        _$identity,
      );
}

abstract class _ApprovalAttempt implements ApprovalAttempt {
  const factory _ApprovalAttempt({
    required final String id,
    required final String approvalId,
    required final int attemptNumber,
    required final String action,
    required final String actorId,
    final String? comment,
    required final DateTime createdAt,
  }) = _$ApprovalAttemptImpl;

  @override
  String get id;
  @override
  String get approvalId;
  @override
  int get attemptNumber;
  @override
  String get action;
  @override
  String get actorId;
  @override
  String? get comment;
  @override
  DateTime get createdAt;

  /// Create a copy of ApprovalAttempt
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApprovalAttemptImplCopyWith<_$ApprovalAttemptImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ApprovalAttachment {
  String get id => throw _privateConstructorUsedError;
  String get approvalId => throw _privateConstructorUsedError;
  String get fileKey => throw _privateConstructorUsedError;
  String? get thumbKey => throw _privateConstructorUsedError;
  String get mimeType => throw _privateConstructorUsedError;
  int get sizeBytes => throw _privateConstructorUsedError;
  String? get url => throw _privateConstructorUsedError;
  String? get thumbUrl => throw _privateConstructorUsedError;

  /// Create a copy of ApprovalAttachment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApprovalAttachmentCopyWith<ApprovalAttachment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApprovalAttachmentCopyWith<$Res> {
  factory $ApprovalAttachmentCopyWith(
    ApprovalAttachment value,
    $Res Function(ApprovalAttachment) then,
  ) = _$ApprovalAttachmentCopyWithImpl<$Res, ApprovalAttachment>;
  @useResult
  $Res call({
    String id,
    String approvalId,
    String fileKey,
    String? thumbKey,
    String mimeType,
    int sizeBytes,
    String? url,
    String? thumbUrl,
  });
}

/// @nodoc
class _$ApprovalAttachmentCopyWithImpl<$Res, $Val extends ApprovalAttachment>
    implements $ApprovalAttachmentCopyWith<$Res> {
  _$ApprovalAttachmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApprovalAttachment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? approvalId = null,
    Object? fileKey = null,
    Object? thumbKey = freezed,
    Object? mimeType = null,
    Object? sizeBytes = null,
    Object? url = freezed,
    Object? thumbUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            approvalId: null == approvalId
                ? _value.approvalId
                : approvalId // ignore: cast_nullable_to_non_nullable
                      as String,
            fileKey: null == fileKey
                ? _value.fileKey
                : fileKey // ignore: cast_nullable_to_non_nullable
                      as String,
            thumbKey: freezed == thumbKey
                ? _value.thumbKey
                : thumbKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            mimeType: null == mimeType
                ? _value.mimeType
                : mimeType // ignore: cast_nullable_to_non_nullable
                      as String,
            sizeBytes: null == sizeBytes
                ? _value.sizeBytes
                : sizeBytes // ignore: cast_nullable_to_non_nullable
                      as int,
            url: freezed == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String?,
            thumbUrl: freezed == thumbUrl
                ? _value.thumbUrl
                : thumbUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ApprovalAttachmentImplCopyWith<$Res>
    implements $ApprovalAttachmentCopyWith<$Res> {
  factory _$$ApprovalAttachmentImplCopyWith(
    _$ApprovalAttachmentImpl value,
    $Res Function(_$ApprovalAttachmentImpl) then,
  ) = __$$ApprovalAttachmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String approvalId,
    String fileKey,
    String? thumbKey,
    String mimeType,
    int sizeBytes,
    String? url,
    String? thumbUrl,
  });
}

/// @nodoc
class __$$ApprovalAttachmentImplCopyWithImpl<$Res>
    extends _$ApprovalAttachmentCopyWithImpl<$Res, _$ApprovalAttachmentImpl>
    implements _$$ApprovalAttachmentImplCopyWith<$Res> {
  __$$ApprovalAttachmentImplCopyWithImpl(
    _$ApprovalAttachmentImpl _value,
    $Res Function(_$ApprovalAttachmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApprovalAttachment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? approvalId = null,
    Object? fileKey = null,
    Object? thumbKey = freezed,
    Object? mimeType = null,
    Object? sizeBytes = null,
    Object? url = freezed,
    Object? thumbUrl = freezed,
  }) {
    return _then(
      _$ApprovalAttachmentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        approvalId: null == approvalId
            ? _value.approvalId
            : approvalId // ignore: cast_nullable_to_non_nullable
                  as String,
        fileKey: null == fileKey
            ? _value.fileKey
            : fileKey // ignore: cast_nullable_to_non_nullable
                  as String,
        thumbKey: freezed == thumbKey
            ? _value.thumbKey
            : thumbKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        mimeType: null == mimeType
            ? _value.mimeType
            : mimeType // ignore: cast_nullable_to_non_nullable
                  as String,
        sizeBytes: null == sizeBytes
            ? _value.sizeBytes
            : sizeBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        url: freezed == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String?,
        thumbUrl: freezed == thumbUrl
            ? _value.thumbUrl
            : thumbUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ApprovalAttachmentImpl implements _ApprovalAttachment {
  const _$ApprovalAttachmentImpl({
    required this.id,
    required this.approvalId,
    required this.fileKey,
    this.thumbKey,
    required this.mimeType,
    required this.sizeBytes,
    this.url,
    this.thumbUrl,
  });

  @override
  final String id;
  @override
  final String approvalId;
  @override
  final String fileKey;
  @override
  final String? thumbKey;
  @override
  final String mimeType;
  @override
  final int sizeBytes;
  @override
  final String? url;
  @override
  final String? thumbUrl;

  @override
  String toString() {
    return 'ApprovalAttachment(id: $id, approvalId: $approvalId, fileKey: $fileKey, thumbKey: $thumbKey, mimeType: $mimeType, sizeBytes: $sizeBytes, url: $url, thumbUrl: $thumbUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApprovalAttachmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.approvalId, approvalId) ||
                other.approvalId == approvalId) &&
            (identical(other.fileKey, fileKey) || other.fileKey == fileKey) &&
            (identical(other.thumbKey, thumbKey) ||
                other.thumbKey == thumbKey) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.thumbUrl, thumbUrl) ||
                other.thumbUrl == thumbUrl));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    approvalId,
    fileKey,
    thumbKey,
    mimeType,
    sizeBytes,
    url,
    thumbUrl,
  );

  /// Create a copy of ApprovalAttachment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApprovalAttachmentImplCopyWith<_$ApprovalAttachmentImpl> get copyWith =>
      __$$ApprovalAttachmentImplCopyWithImpl<_$ApprovalAttachmentImpl>(
        this,
        _$identity,
      );
}

abstract class _ApprovalAttachment implements ApprovalAttachment {
  const factory _ApprovalAttachment({
    required final String id,
    required final String approvalId,
    required final String fileKey,
    final String? thumbKey,
    required final String mimeType,
    required final int sizeBytes,
    final String? url,
    final String? thumbUrl,
  }) = _$ApprovalAttachmentImpl;

  @override
  String get id;
  @override
  String get approvalId;
  @override
  String get fileKey;
  @override
  String? get thumbKey;
  @override
  String get mimeType;
  @override
  int get sizeBytes;
  @override
  String? get url;
  @override
  String? get thumbUrl;

  /// Create a copy of ApprovalAttachment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApprovalAttachmentImplCopyWith<_$ApprovalAttachmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Approval {
  String get id => throw _privateConstructorUsedError;
  ApprovalScope get scope => throw _privateConstructorUsedError;
  String get projectId => throw _privateConstructorUsedError;
  String? get stageId => throw _privateConstructorUsedError;
  String? get stepId => throw _privateConstructorUsedError;
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;
  String get requestedById => throw _privateConstructorUsedError;
  String get addresseeId => throw _privateConstructorUsedError;

  /// П2.6 — роль адресата текущей ступени; null для approvals из старой
  /// схемы (без actorRole). Если null — fallback на addresseeId-проверку.
  ApprovalActorRole? get actorRole => throw _privateConstructorUsedError;
  ApprovalStatus get status => throw _privateConstructorUsedError;
  int get attemptNumber => throw _privateConstructorUsedError;
  bool get requiresReassign => throw _privateConstructorUsedError;
  DateTime? get decidedAt => throw _privateConstructorUsedError;
  String? get decidedById => throw _privateConstructorUsedError;
  String? get decisionComment => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  List<ApprovalAttempt> get attempts => throw _privateConstructorUsedError;
  List<ApprovalAttachment> get attachments =>
      throw _privateConstructorUsedError;

  /// Create a copy of Approval
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApprovalCopyWith<Approval> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApprovalCopyWith<$Res> {
  factory $ApprovalCopyWith(Approval value, $Res Function(Approval) then) =
      _$ApprovalCopyWithImpl<$Res, Approval>;
  @useResult
  $Res call({
    String id,
    ApprovalScope scope,
    String projectId,
    String? stageId,
    String? stepId,
    Map<String, dynamic> payload,
    String requestedById,
    String addresseeId,
    ApprovalActorRole? actorRole,
    ApprovalStatus status,
    int attemptNumber,
    bool requiresReassign,
    DateTime? decidedAt,
    String? decidedById,
    String? decisionComment,
    DateTime createdAt,
    DateTime updatedAt,
    List<ApprovalAttempt> attempts,
    List<ApprovalAttachment> attachments,
  });
}

/// @nodoc
class _$ApprovalCopyWithImpl<$Res, $Val extends Approval>
    implements $ApprovalCopyWith<$Res> {
  _$ApprovalCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Approval
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? scope = null,
    Object? projectId = null,
    Object? stageId = freezed,
    Object? stepId = freezed,
    Object? payload = null,
    Object? requestedById = null,
    Object? addresseeId = null,
    Object? actorRole = freezed,
    Object? status = null,
    Object? attemptNumber = null,
    Object? requiresReassign = null,
    Object? decidedAt = freezed,
    Object? decidedById = freezed,
    Object? decisionComment = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? attempts = null,
    Object? attachments = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            scope: null == scope
                ? _value.scope
                : scope // ignore: cast_nullable_to_non_nullable
                      as ApprovalScope,
            projectId: null == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String,
            stageId: freezed == stageId
                ? _value.stageId
                : stageId // ignore: cast_nullable_to_non_nullable
                      as String?,
            stepId: freezed == stepId
                ? _value.stepId
                : stepId // ignore: cast_nullable_to_non_nullable
                      as String?,
            payload: null == payload
                ? _value.payload
                : payload // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            requestedById: null == requestedById
                ? _value.requestedById
                : requestedById // ignore: cast_nullable_to_non_nullable
                      as String,
            addresseeId: null == addresseeId
                ? _value.addresseeId
                : addresseeId // ignore: cast_nullable_to_non_nullable
                      as String,
            actorRole: freezed == actorRole
                ? _value.actorRole
                : actorRole // ignore: cast_nullable_to_non_nullable
                      as ApprovalActorRole?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ApprovalStatus,
            attemptNumber: null == attemptNumber
                ? _value.attemptNumber
                : attemptNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            requiresReassign: null == requiresReassign
                ? _value.requiresReassign
                : requiresReassign // ignore: cast_nullable_to_non_nullable
                      as bool,
            decidedAt: freezed == decidedAt
                ? _value.decidedAt
                : decidedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            decidedById: freezed == decidedById
                ? _value.decidedById
                : decidedById // ignore: cast_nullable_to_non_nullable
                      as String?,
            decisionComment: freezed == decisionComment
                ? _value.decisionComment
                : decisionComment // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            attempts: null == attempts
                ? _value.attempts
                : attempts // ignore: cast_nullable_to_non_nullable
                      as List<ApprovalAttempt>,
            attachments: null == attachments
                ? _value.attachments
                : attachments // ignore: cast_nullable_to_non_nullable
                      as List<ApprovalAttachment>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ApprovalImplCopyWith<$Res>
    implements $ApprovalCopyWith<$Res> {
  factory _$$ApprovalImplCopyWith(
    _$ApprovalImpl value,
    $Res Function(_$ApprovalImpl) then,
  ) = __$$ApprovalImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    ApprovalScope scope,
    String projectId,
    String? stageId,
    String? stepId,
    Map<String, dynamic> payload,
    String requestedById,
    String addresseeId,
    ApprovalActorRole? actorRole,
    ApprovalStatus status,
    int attemptNumber,
    bool requiresReassign,
    DateTime? decidedAt,
    String? decidedById,
    String? decisionComment,
    DateTime createdAt,
    DateTime updatedAt,
    List<ApprovalAttempt> attempts,
    List<ApprovalAttachment> attachments,
  });
}

/// @nodoc
class __$$ApprovalImplCopyWithImpl<$Res>
    extends _$ApprovalCopyWithImpl<$Res, _$ApprovalImpl>
    implements _$$ApprovalImplCopyWith<$Res> {
  __$$ApprovalImplCopyWithImpl(
    _$ApprovalImpl _value,
    $Res Function(_$ApprovalImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Approval
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? scope = null,
    Object? projectId = null,
    Object? stageId = freezed,
    Object? stepId = freezed,
    Object? payload = null,
    Object? requestedById = null,
    Object? addresseeId = null,
    Object? actorRole = freezed,
    Object? status = null,
    Object? attemptNumber = null,
    Object? requiresReassign = null,
    Object? decidedAt = freezed,
    Object? decidedById = freezed,
    Object? decisionComment = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? attempts = null,
    Object? attachments = null,
  }) {
    return _then(
      _$ApprovalImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        scope: null == scope
            ? _value.scope
            : scope // ignore: cast_nullable_to_non_nullable
                  as ApprovalScope,
        projectId: null == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String,
        stageId: freezed == stageId
            ? _value.stageId
            : stageId // ignore: cast_nullable_to_non_nullable
                  as String?,
        stepId: freezed == stepId
            ? _value.stepId
            : stepId // ignore: cast_nullable_to_non_nullable
                  as String?,
        payload: null == payload
            ? _value._payload
            : payload // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        requestedById: null == requestedById
            ? _value.requestedById
            : requestedById // ignore: cast_nullable_to_non_nullable
                  as String,
        addresseeId: null == addresseeId
            ? _value.addresseeId
            : addresseeId // ignore: cast_nullable_to_non_nullable
                  as String,
        actorRole: freezed == actorRole
            ? _value.actorRole
            : actorRole // ignore: cast_nullable_to_non_nullable
                  as ApprovalActorRole?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ApprovalStatus,
        attemptNumber: null == attemptNumber
            ? _value.attemptNumber
            : attemptNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        requiresReassign: null == requiresReassign
            ? _value.requiresReassign
            : requiresReassign // ignore: cast_nullable_to_non_nullable
                  as bool,
        decidedAt: freezed == decidedAt
            ? _value.decidedAt
            : decidedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        decidedById: freezed == decidedById
            ? _value.decidedById
            : decidedById // ignore: cast_nullable_to_non_nullable
                  as String?,
        decisionComment: freezed == decisionComment
            ? _value.decisionComment
            : decisionComment // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        attempts: null == attempts
            ? _value._attempts
            : attempts // ignore: cast_nullable_to_non_nullable
                  as List<ApprovalAttempt>,
        attachments: null == attachments
            ? _value._attachments
            : attachments // ignore: cast_nullable_to_non_nullable
                  as List<ApprovalAttachment>,
      ),
    );
  }
}

/// @nodoc

class _$ApprovalImpl implements _Approval {
  const _$ApprovalImpl({
    required this.id,
    required this.scope,
    required this.projectId,
    this.stageId,
    this.stepId,
    final Map<String, dynamic> payload = const <String, dynamic>{},
    required this.requestedById,
    required this.addresseeId,
    this.actorRole,
    required this.status,
    required this.attemptNumber,
    this.requiresReassign = false,
    this.decidedAt,
    this.decidedById,
    this.decisionComment,
    required this.createdAt,
    required this.updatedAt,
    final List<ApprovalAttempt> attempts = const <ApprovalAttempt>[],
    final List<ApprovalAttachment> attachments = const <ApprovalAttachment>[],
  }) : _payload = payload,
       _attempts = attempts,
       _attachments = attachments;

  @override
  final String id;
  @override
  final ApprovalScope scope;
  @override
  final String projectId;
  @override
  final String? stageId;
  @override
  final String? stepId;
  final Map<String, dynamic> _payload;
  @override
  @JsonKey()
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  final String requestedById;
  @override
  final String addresseeId;

  /// П2.6 — роль адресата текущей ступени; null для approvals из старой
  /// схемы (без actorRole). Если null — fallback на addresseeId-проверку.
  @override
  final ApprovalActorRole? actorRole;
  @override
  final ApprovalStatus status;
  @override
  final int attemptNumber;
  @override
  @JsonKey()
  final bool requiresReassign;
  @override
  final DateTime? decidedAt;
  @override
  final String? decidedById;
  @override
  final String? decisionComment;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final List<ApprovalAttempt> _attempts;
  @override
  @JsonKey()
  List<ApprovalAttempt> get attempts {
    if (_attempts is EqualUnmodifiableListView) return _attempts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attempts);
  }

  final List<ApprovalAttachment> _attachments;
  @override
  @JsonKey()
  List<ApprovalAttachment> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  @override
  String toString() {
    return 'Approval(id: $id, scope: $scope, projectId: $projectId, stageId: $stageId, stepId: $stepId, payload: $payload, requestedById: $requestedById, addresseeId: $addresseeId, actorRole: $actorRole, status: $status, attemptNumber: $attemptNumber, requiresReassign: $requiresReassign, decidedAt: $decidedAt, decidedById: $decidedById, decisionComment: $decisionComment, createdAt: $createdAt, updatedAt: $updatedAt, attempts: $attempts, attachments: $attachments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApprovalImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.scope, scope) || other.scope == scope) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.stageId, stageId) || other.stageId == stageId) &&
            (identical(other.stepId, stepId) || other.stepId == stepId) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.requestedById, requestedById) ||
                other.requestedById == requestedById) &&
            (identical(other.addresseeId, addresseeId) ||
                other.addresseeId == addresseeId) &&
            (identical(other.actorRole, actorRole) ||
                other.actorRole == actorRole) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.attemptNumber, attemptNumber) ||
                other.attemptNumber == attemptNumber) &&
            (identical(other.requiresReassign, requiresReassign) ||
                other.requiresReassign == requiresReassign) &&
            (identical(other.decidedAt, decidedAt) ||
                other.decidedAt == decidedAt) &&
            (identical(other.decidedById, decidedById) ||
                other.decidedById == decidedById) &&
            (identical(other.decisionComment, decisionComment) ||
                other.decisionComment == decisionComment) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._attempts, _attempts) &&
            const DeepCollectionEquality().equals(
              other._attachments,
              _attachments,
            ));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    scope,
    projectId,
    stageId,
    stepId,
    const DeepCollectionEquality().hash(_payload),
    requestedById,
    addresseeId,
    actorRole,
    status,
    attemptNumber,
    requiresReassign,
    decidedAt,
    decidedById,
    decisionComment,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_attempts),
    const DeepCollectionEquality().hash(_attachments),
  ]);

  /// Create a copy of Approval
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApprovalImplCopyWith<_$ApprovalImpl> get copyWith =>
      __$$ApprovalImplCopyWithImpl<_$ApprovalImpl>(this, _$identity);
}

abstract class _Approval implements Approval {
  const factory _Approval({
    required final String id,
    required final ApprovalScope scope,
    required final String projectId,
    final String? stageId,
    final String? stepId,
    final Map<String, dynamic> payload,
    required final String requestedById,
    required final String addresseeId,
    final ApprovalActorRole? actorRole,
    required final ApprovalStatus status,
    required final int attemptNumber,
    final bool requiresReassign,
    final DateTime? decidedAt,
    final String? decidedById,
    final String? decisionComment,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final List<ApprovalAttempt> attempts,
    final List<ApprovalAttachment> attachments,
  }) = _$ApprovalImpl;

  @override
  String get id;
  @override
  ApprovalScope get scope;
  @override
  String get projectId;
  @override
  String? get stageId;
  @override
  String? get stepId;
  @override
  Map<String, dynamic> get payload;
  @override
  String get requestedById;
  @override
  String get addresseeId;

  /// П2.6 — роль адресата текущей ступени; null для approvals из старой
  /// схемы (без actorRole). Если null — fallback на addresseeId-проверку.
  @override
  ApprovalActorRole? get actorRole;
  @override
  ApprovalStatus get status;
  @override
  int get attemptNumber;
  @override
  bool get requiresReassign;
  @override
  DateTime? get decidedAt;
  @override
  String? get decidedById;
  @override
  String? get decisionComment;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  List<ApprovalAttempt> get attempts;
  @override
  List<ApprovalAttachment> get attachments;

  /// Create a copy of Approval
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApprovalImplCopyWith<_$ApprovalImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
