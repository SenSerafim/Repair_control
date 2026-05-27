// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Payment {
  String get id => throw _privateConstructorUsedError;
  String get projectId => throw _privateConstructorUsedError;
  String? get stageId => throw _privateConstructorUsedError;
  String? get parentPaymentId => throw _privateConstructorUsedError;
  PaymentKind get kind => throw _privateConstructorUsedError;
  String get fromUserId => throw _privateConstructorUsedError;
  String get toUserId => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  String? get comment => throw _privateConstructorUsedError;
  String? get photoKey => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  List<Payment> get children => throw _privateConstructorUsedError;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentCopyWith<Payment> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentCopyWith<$Res> {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) then) =
      _$PaymentCopyWithImpl<$Res, Payment>;
  @useResult
  $Res call({
    String id,
    String projectId,
    String? stageId,
    String? parentPaymentId,
    PaymentKind kind,
    String fromUserId,
    String toUserId,
    int amount,
    String? comment,
    String? photoKey,
    DateTime createdAt,
    DateTime updatedAt,
    List<Payment> children,
  });
}

/// @nodoc
class _$PaymentCopyWithImpl<$Res, $Val extends Payment>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? stageId = freezed,
    Object? parentPaymentId = freezed,
    Object? kind = null,
    Object? fromUserId = null,
    Object? toUserId = null,
    Object? amount = null,
    Object? comment = freezed,
    Object? photoKey = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? children = null,
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
            parentPaymentId: freezed == parentPaymentId
                ? _value.parentPaymentId
                : parentPaymentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as PaymentKind,
            fromUserId: null == fromUserId
                ? _value.fromUserId
                : fromUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            toUserId: null == toUserId
                ? _value.toUserId
                : toUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as int,
            comment: freezed == comment
                ? _value.comment
                : comment // ignore: cast_nullable_to_non_nullable
                      as String?,
            photoKey: freezed == photoKey
                ? _value.photoKey
                : photoKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            children: null == children
                ? _value.children
                : children // ignore: cast_nullable_to_non_nullable
                      as List<Payment>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaymentImplCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$$PaymentImplCopyWith(
    _$PaymentImpl value,
    $Res Function(_$PaymentImpl) then,
  ) = __$$PaymentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String projectId,
    String? stageId,
    String? parentPaymentId,
    PaymentKind kind,
    String fromUserId,
    String toUserId,
    int amount,
    String? comment,
    String? photoKey,
    DateTime createdAt,
    DateTime updatedAt,
    List<Payment> children,
  });
}

/// @nodoc
class __$$PaymentImplCopyWithImpl<$Res>
    extends _$PaymentCopyWithImpl<$Res, _$PaymentImpl>
    implements _$$PaymentImplCopyWith<$Res> {
  __$$PaymentImplCopyWithImpl(
    _$PaymentImpl _value,
    $Res Function(_$PaymentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? stageId = freezed,
    Object? parentPaymentId = freezed,
    Object? kind = null,
    Object? fromUserId = null,
    Object? toUserId = null,
    Object? amount = null,
    Object? comment = freezed,
    Object? photoKey = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? children = null,
  }) {
    return _then(
      _$PaymentImpl(
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
        parentPaymentId: freezed == parentPaymentId
            ? _value.parentPaymentId
            : parentPaymentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as PaymentKind,
        fromUserId: null == fromUserId
            ? _value.fromUserId
            : fromUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        toUserId: null == toUserId
            ? _value.toUserId
            : toUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int,
        comment: freezed == comment
            ? _value.comment
            : comment // ignore: cast_nullable_to_non_nullable
                  as String?,
        photoKey: freezed == photoKey
            ? _value.photoKey
            : photoKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        children: null == children
            ? _value._children
            : children // ignore: cast_nullable_to_non_nullable
                  as List<Payment>,
      ),
    );
  }
}

/// @nodoc

class _$PaymentImpl implements _Payment {
  const _$PaymentImpl({
    required this.id,
    required this.projectId,
    this.stageId,
    this.parentPaymentId,
    required this.kind,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    this.comment,
    this.photoKey,
    required this.createdAt,
    required this.updatedAt,
    final List<Payment> children = const <Payment>[],
  }) : _children = children;

  @override
  final String id;
  @override
  final String projectId;
  @override
  final String? stageId;
  @override
  final String? parentPaymentId;
  @override
  final PaymentKind kind;
  @override
  final String fromUserId;
  @override
  final String toUserId;
  @override
  final int amount;
  @override
  final String? comment;
  @override
  final String? photoKey;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final List<Payment> _children;
  @override
  @JsonKey()
  List<Payment> get children {
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_children);
  }

  @override
  String toString() {
    return 'Payment(id: $id, projectId: $projectId, stageId: $stageId, parentPaymentId: $parentPaymentId, kind: $kind, fromUserId: $fromUserId, toUserId: $toUserId, amount: $amount, comment: $comment, photoKey: $photoKey, createdAt: $createdAt, updatedAt: $updatedAt, children: $children)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.stageId, stageId) || other.stageId == stageId) &&
            (identical(other.parentPaymentId, parentPaymentId) ||
                other.parentPaymentId == parentPaymentId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.fromUserId, fromUserId) ||
                other.fromUserId == fromUserId) &&
            (identical(other.toUserId, toUserId) ||
                other.toUserId == toUserId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.photoKey, photoKey) ||
                other.photoKey == photoKey) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._children, _children));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    projectId,
    stageId,
    parentPaymentId,
    kind,
    fromUserId,
    toUserId,
    amount,
    comment,
    photoKey,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_children),
  );

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      __$$PaymentImplCopyWithImpl<_$PaymentImpl>(this, _$identity);
}

abstract class _Payment implements Payment {
  const factory _Payment({
    required final String id,
    required final String projectId,
    final String? stageId,
    final String? parentPaymentId,
    required final PaymentKind kind,
    required final String fromUserId,
    required final String toUserId,
    required final int amount,
    final String? comment,
    final String? photoKey,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final List<Payment> children,
  }) = _$PaymentImpl;

  @override
  String get id;
  @override
  String get projectId;
  @override
  String? get stageId;
  @override
  String? get parentPaymentId;
  @override
  PaymentKind get kind;
  @override
  String get fromUserId;
  @override
  String get toUserId;
  @override
  int get amount;
  @override
  String? get comment;
  @override
  String? get photoKey;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  List<Payment> get children;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
