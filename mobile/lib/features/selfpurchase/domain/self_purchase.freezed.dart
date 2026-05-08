// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'self_purchase.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SelfPurchase {
  String get id => throw _privateConstructorUsedError;
  String get projectId => throw _privateConstructorUsedError;
  String? get stageId => throw _privateConstructorUsedError;
  String get byUserId => throw _privateConstructorUsedError;
  SelfPurchaseBy get byRole => throw _privateConstructorUsedError;
  String get addresseeId => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  String? get comment => throw _privateConstructorUsedError;
  List<String> get photoKeys => throw _privateConstructorUsedError;
  SelfPurchaseStatus get status => throw _privateConstructorUsedError;
  DateTime? get decidedAt => throw _privateConstructorUsedError;
  String? get decidedById => throw _privateConstructorUsedError;
  String? get decisionComment => throw _privateConstructorUsedError;

  /// 3-tier forwarding: id master-самозакупа, на основе которого создан этот
  /// foreman→customer forward. null для оригинальных одноступенчатых записей.
  String? get forwardedFromId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of SelfPurchase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SelfPurchaseCopyWith<SelfPurchase> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SelfPurchaseCopyWith<$Res> {
  factory $SelfPurchaseCopyWith(
    SelfPurchase value,
    $Res Function(SelfPurchase) then,
  ) = _$SelfPurchaseCopyWithImpl<$Res, SelfPurchase>;
  @useResult
  $Res call({
    String id,
    String projectId,
    String? stageId,
    String byUserId,
    SelfPurchaseBy byRole,
    String addresseeId,
    int amount,
    String? comment,
    List<String> photoKeys,
    SelfPurchaseStatus status,
    DateTime? decidedAt,
    String? decidedById,
    String? decisionComment,
    String? forwardedFromId,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$SelfPurchaseCopyWithImpl<$Res, $Val extends SelfPurchase>
    implements $SelfPurchaseCopyWith<$Res> {
  _$SelfPurchaseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SelfPurchase
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? stageId = freezed,
    Object? byUserId = null,
    Object? byRole = null,
    Object? addresseeId = null,
    Object? amount = null,
    Object? comment = freezed,
    Object? photoKeys = null,
    Object? status = null,
    Object? decidedAt = freezed,
    Object? decidedById = freezed,
    Object? decisionComment = freezed,
    Object? forwardedFromId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
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
            stageId: freezed == stageId
                ? _value.stageId
                : stageId // ignore: cast_nullable_to_non_nullable
                      as String?,
            byUserId: null == byUserId
                ? _value.byUserId
                : byUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            byRole: null == byRole
                ? _value.byRole
                : byRole // ignore: cast_nullable_to_non_nullable
                      as SelfPurchaseBy,
            addresseeId: null == addresseeId
                ? _value.addresseeId
                : addresseeId // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as int,
            comment: freezed == comment
                ? _value.comment
                : comment // ignore: cast_nullable_to_non_nullable
                      as String?,
            photoKeys: null == photoKeys
                ? _value.photoKeys
                : photoKeys // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as SelfPurchaseStatus,
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
            forwardedFromId: freezed == forwardedFromId
                ? _value.forwardedFromId
                : forwardedFromId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SelfPurchaseImplCopyWith<$Res>
    implements $SelfPurchaseCopyWith<$Res> {
  factory _$$SelfPurchaseImplCopyWith(
    _$SelfPurchaseImpl value,
    $Res Function(_$SelfPurchaseImpl) then,
  ) = __$$SelfPurchaseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String projectId,
    String? stageId,
    String byUserId,
    SelfPurchaseBy byRole,
    String addresseeId,
    int amount,
    String? comment,
    List<String> photoKeys,
    SelfPurchaseStatus status,
    DateTime? decidedAt,
    String? decidedById,
    String? decisionComment,
    String? forwardedFromId,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$SelfPurchaseImplCopyWithImpl<$Res>
    extends _$SelfPurchaseCopyWithImpl<$Res, _$SelfPurchaseImpl>
    implements _$$SelfPurchaseImplCopyWith<$Res> {
  __$$SelfPurchaseImplCopyWithImpl(
    _$SelfPurchaseImpl _value,
    $Res Function(_$SelfPurchaseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SelfPurchase
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? stageId = freezed,
    Object? byUserId = null,
    Object? byRole = null,
    Object? addresseeId = null,
    Object? amount = null,
    Object? comment = freezed,
    Object? photoKeys = null,
    Object? status = null,
    Object? decidedAt = freezed,
    Object? decidedById = freezed,
    Object? decisionComment = freezed,
    Object? forwardedFromId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$SelfPurchaseImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        projectId: null == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String,
        stageId: freezed == stageId
            ? _value.stageId
            : stageId // ignore: cast_nullable_to_non_nullable
                  as String?,
        byUserId: null == byUserId
            ? _value.byUserId
            : byUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        byRole: null == byRole
            ? _value.byRole
            : byRole // ignore: cast_nullable_to_non_nullable
                  as SelfPurchaseBy,
        addresseeId: null == addresseeId
            ? _value.addresseeId
            : addresseeId // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int,
        comment: freezed == comment
            ? _value.comment
            : comment // ignore: cast_nullable_to_non_nullable
                  as String?,
        photoKeys: null == photoKeys
            ? _value._photoKeys
            : photoKeys // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as SelfPurchaseStatus,
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
        forwardedFromId: freezed == forwardedFromId
            ? _value.forwardedFromId
            : forwardedFromId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$SelfPurchaseImpl implements _SelfPurchase {
  const _$SelfPurchaseImpl({
    required this.id,
    required this.projectId,
    this.stageId,
    required this.byUserId,
    required this.byRole,
    required this.addresseeId,
    required this.amount,
    this.comment,
    final List<String> photoKeys = const <String>[],
    required this.status,
    this.decidedAt,
    this.decidedById,
    this.decisionComment,
    this.forwardedFromId,
    required this.createdAt,
    required this.updatedAt,
  }) : _photoKeys = photoKeys;

  @override
  final String id;
  @override
  final String projectId;
  @override
  final String? stageId;
  @override
  final String byUserId;
  @override
  final SelfPurchaseBy byRole;
  @override
  final String addresseeId;
  @override
  final int amount;
  @override
  final String? comment;
  final List<String> _photoKeys;
  @override
  @JsonKey()
  List<String> get photoKeys {
    if (_photoKeys is EqualUnmodifiableListView) return _photoKeys;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photoKeys);
  }

  @override
  final SelfPurchaseStatus status;
  @override
  final DateTime? decidedAt;
  @override
  final String? decidedById;
  @override
  final String? decisionComment;

  /// 3-tier forwarding: id master-самозакупа, на основе которого создан этот
  /// foreman→customer forward. null для оригинальных одноступенчатых записей.
  @override
  final String? forwardedFromId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'SelfPurchase(id: $id, projectId: $projectId, stageId: $stageId, byUserId: $byUserId, byRole: $byRole, addresseeId: $addresseeId, amount: $amount, comment: $comment, photoKeys: $photoKeys, status: $status, decidedAt: $decidedAt, decidedById: $decidedById, decisionComment: $decisionComment, forwardedFromId: $forwardedFromId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SelfPurchaseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.stageId, stageId) || other.stageId == stageId) &&
            (identical(other.byUserId, byUserId) ||
                other.byUserId == byUserId) &&
            (identical(other.byRole, byRole) || other.byRole == byRole) &&
            (identical(other.addresseeId, addresseeId) ||
                other.addresseeId == addresseeId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            const DeepCollectionEquality().equals(
              other._photoKeys,
              _photoKeys,
            ) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.decidedAt, decidedAt) ||
                other.decidedAt == decidedAt) &&
            (identical(other.decidedById, decidedById) ||
                other.decidedById == decidedById) &&
            (identical(other.decisionComment, decisionComment) ||
                other.decisionComment == decisionComment) &&
            (identical(other.forwardedFromId, forwardedFromId) ||
                other.forwardedFromId == forwardedFromId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    projectId,
    stageId,
    byUserId,
    byRole,
    addresseeId,
    amount,
    comment,
    const DeepCollectionEquality().hash(_photoKeys),
    status,
    decidedAt,
    decidedById,
    decisionComment,
    forwardedFromId,
    createdAt,
    updatedAt,
  );

  /// Create a copy of SelfPurchase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SelfPurchaseImplCopyWith<_$SelfPurchaseImpl> get copyWith =>
      __$$SelfPurchaseImplCopyWithImpl<_$SelfPurchaseImpl>(this, _$identity);
}

abstract class _SelfPurchase implements SelfPurchase {
  const factory _SelfPurchase({
    required final String id,
    required final String projectId,
    final String? stageId,
    required final String byUserId,
    required final SelfPurchaseBy byRole,
    required final String addresseeId,
    required final int amount,
    final String? comment,
    final List<String> photoKeys,
    required final SelfPurchaseStatus status,
    final DateTime? decidedAt,
    final String? decidedById,
    final String? decisionComment,
    final String? forwardedFromId,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$SelfPurchaseImpl;

  @override
  String get id;
  @override
  String get projectId;
  @override
  String? get stageId;
  @override
  String get byUserId;
  @override
  SelfPurchaseBy get byRole;
  @override
  String get addresseeId;
  @override
  int get amount;
  @override
  String? get comment;
  @override
  List<String> get photoKeys;
  @override
  SelfPurchaseStatus get status;
  @override
  DateTime? get decidedAt;
  @override
  String? get decidedById;
  @override
  String? get decisionComment;

  /// 3-tier forwarding: id master-самозакупа, на основе которого создан этот
  /// foreman→customer forward. null для оригинальных одноступенчатых записей.
  @override
  String? get forwardedFromId;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of SelfPurchase
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SelfPurchaseImplCopyWith<_$SelfPurchaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
