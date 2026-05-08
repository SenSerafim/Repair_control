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
mixin _$PaymentDispute {
  String get id => throw _privateConstructorUsedError;
  String get paymentId => throw _privateConstructorUsedError;
  String get openedById => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get resolution => throw _privateConstructorUsedError;
  DateTime? get resolvedAt => throw _privateConstructorUsedError;
  String? get resolvedBy => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of PaymentDispute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentDisputeCopyWith<PaymentDispute> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentDisputeCopyWith<$Res> {
  factory $PaymentDisputeCopyWith(
    PaymentDispute value,
    $Res Function(PaymentDispute) then,
  ) = _$PaymentDisputeCopyWithImpl<$Res, PaymentDispute>;
  @useResult
  $Res call({
    String id,
    String paymentId,
    String openedById,
    String reason,
    String status,
    String? resolution,
    DateTime? resolvedAt,
    String? resolvedBy,
    DateTime createdAt,
  });
}

/// @nodoc
class _$PaymentDisputeCopyWithImpl<$Res, $Val extends PaymentDispute>
    implements $PaymentDisputeCopyWith<$Res> {
  _$PaymentDisputeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentDispute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? paymentId = null,
    Object? openedById = null,
    Object? reason = null,
    Object? status = null,
    Object? resolution = freezed,
    Object? resolvedAt = freezed,
    Object? resolvedBy = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            paymentId: null == paymentId
                ? _value.paymentId
                : paymentId // ignore: cast_nullable_to_non_nullable
                      as String,
            openedById: null == openedById
                ? _value.openedById
                : openedById // ignore: cast_nullable_to_non_nullable
                      as String,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            resolution: freezed == resolution
                ? _value.resolution
                : resolution // ignore: cast_nullable_to_non_nullable
                      as String?,
            resolvedAt: freezed == resolvedAt
                ? _value.resolvedAt
                : resolvedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            resolvedBy: freezed == resolvedBy
                ? _value.resolvedBy
                : resolvedBy // ignore: cast_nullable_to_non_nullable
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
abstract class _$$PaymentDisputeImplCopyWith<$Res>
    implements $PaymentDisputeCopyWith<$Res> {
  factory _$$PaymentDisputeImplCopyWith(
    _$PaymentDisputeImpl value,
    $Res Function(_$PaymentDisputeImpl) then,
  ) = __$$PaymentDisputeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String paymentId,
    String openedById,
    String reason,
    String status,
    String? resolution,
    DateTime? resolvedAt,
    String? resolvedBy,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$PaymentDisputeImplCopyWithImpl<$Res>
    extends _$PaymentDisputeCopyWithImpl<$Res, _$PaymentDisputeImpl>
    implements _$$PaymentDisputeImplCopyWith<$Res> {
  __$$PaymentDisputeImplCopyWithImpl(
    _$PaymentDisputeImpl _value,
    $Res Function(_$PaymentDisputeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PaymentDispute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? paymentId = null,
    Object? openedById = null,
    Object? reason = null,
    Object? status = null,
    Object? resolution = freezed,
    Object? resolvedAt = freezed,
    Object? resolvedBy = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$PaymentDisputeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        paymentId: null == paymentId
            ? _value.paymentId
            : paymentId // ignore: cast_nullable_to_non_nullable
                  as String,
        openedById: null == openedById
            ? _value.openedById
            : openedById // ignore: cast_nullable_to_non_nullable
                  as String,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        resolution: freezed == resolution
            ? _value.resolution
            : resolution // ignore: cast_nullable_to_non_nullable
                  as String?,
        resolvedAt: freezed == resolvedAt
            ? _value.resolvedAt
            : resolvedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        resolvedBy: freezed == resolvedBy
            ? _value.resolvedBy
            : resolvedBy // ignore: cast_nullable_to_non_nullable
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

class _$PaymentDisputeImpl implements _PaymentDispute {
  const _$PaymentDisputeImpl({
    required this.id,
    required this.paymentId,
    required this.openedById,
    required this.reason,
    required this.status,
    this.resolution,
    this.resolvedAt,
    this.resolvedBy,
    required this.createdAt,
  });

  @override
  final String id;
  @override
  final String paymentId;
  @override
  final String openedById;
  @override
  final String reason;
  @override
  final String status;
  @override
  final String? resolution;
  @override
  final DateTime? resolvedAt;
  @override
  final String? resolvedBy;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'PaymentDispute(id: $id, paymentId: $paymentId, openedById: $openedById, reason: $reason, status: $status, resolution: $resolution, resolvedAt: $resolvedAt, resolvedBy: $resolvedBy, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentDisputeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.paymentId, paymentId) ||
                other.paymentId == paymentId) &&
            (identical(other.openedById, openedById) ||
                other.openedById == openedById) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.resolution, resolution) ||
                other.resolution == resolution) &&
            (identical(other.resolvedAt, resolvedAt) ||
                other.resolvedAt == resolvedAt) &&
            (identical(other.resolvedBy, resolvedBy) ||
                other.resolvedBy == resolvedBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    paymentId,
    openedById,
    reason,
    status,
    resolution,
    resolvedAt,
    resolvedBy,
    createdAt,
  );

  /// Create a copy of PaymentDispute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentDisputeImplCopyWith<_$PaymentDisputeImpl> get copyWith =>
      __$$PaymentDisputeImplCopyWithImpl<_$PaymentDisputeImpl>(
        this,
        _$identity,
      );
}

abstract class _PaymentDispute implements PaymentDispute {
  const factory _PaymentDispute({
    required final String id,
    required final String paymentId,
    required final String openedById,
    required final String reason,
    required final String status,
    final String? resolution,
    final DateTime? resolvedAt,
    final String? resolvedBy,
    required final DateTime createdAt,
  }) = _$PaymentDisputeImpl;

  @override
  String get id;
  @override
  String get paymentId;
  @override
  String get openedById;
  @override
  String get reason;
  @override
  String get status;
  @override
  String? get resolution;
  @override
  DateTime? get resolvedAt;
  @override
  String? get resolvedBy;
  @override
  DateTime get createdAt;

  /// Create a copy of PaymentDispute
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentDisputeImplCopyWith<_$PaymentDisputeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

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
  int? get resolvedAmount => throw _privateConstructorUsedError;
  String? get comment => throw _privateConstructorUsedError;
  String? get photoKey => throw _privateConstructorUsedError;
  PaymentStatus get status => throw _privateConstructorUsedError;
  DateTime? get confirmedAt => throw _privateConstructorUsedError;
  DateTime? get disputedAt => throw _privateConstructorUsedError;
  DateTime? get resolvedAt => throw _privateConstructorUsedError;
  DateTime? get cancelledAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  List<Payment> get children => throw _privateConstructorUsedError;
  List<PaymentDispute> get disputes => throw _privateConstructorUsedError;

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
    int? resolvedAmount,
    String? comment,
    String? photoKey,
    PaymentStatus status,
    DateTime? confirmedAt,
    DateTime? disputedAt,
    DateTime? resolvedAt,
    DateTime? cancelledAt,
    DateTime createdAt,
    DateTime updatedAt,
    List<Payment> children,
    List<PaymentDispute> disputes,
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
    Object? resolvedAmount = freezed,
    Object? comment = freezed,
    Object? photoKey = freezed,
    Object? status = null,
    Object? confirmedAt = freezed,
    Object? disputedAt = freezed,
    Object? resolvedAt = freezed,
    Object? cancelledAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? children = null,
    Object? disputes = null,
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
            resolvedAmount: freezed == resolvedAmount
                ? _value.resolvedAmount
                : resolvedAmount // ignore: cast_nullable_to_non_nullable
                      as int?,
            comment: freezed == comment
                ? _value.comment
                : comment // ignore: cast_nullable_to_non_nullable
                      as String?,
            photoKey: freezed == photoKey
                ? _value.photoKey
                : photoKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as PaymentStatus,
            confirmedAt: freezed == confirmedAt
                ? _value.confirmedAt
                : confirmedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            disputedAt: freezed == disputedAt
                ? _value.disputedAt
                : disputedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            resolvedAt: freezed == resolvedAt
                ? _value.resolvedAt
                : resolvedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            cancelledAt: freezed == cancelledAt
                ? _value.cancelledAt
                : cancelledAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
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
            disputes: null == disputes
                ? _value.disputes
                : disputes // ignore: cast_nullable_to_non_nullable
                      as List<PaymentDispute>,
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
    int? resolvedAmount,
    String? comment,
    String? photoKey,
    PaymentStatus status,
    DateTime? confirmedAt,
    DateTime? disputedAt,
    DateTime? resolvedAt,
    DateTime? cancelledAt,
    DateTime createdAt,
    DateTime updatedAt,
    List<Payment> children,
    List<PaymentDispute> disputes,
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
    Object? resolvedAmount = freezed,
    Object? comment = freezed,
    Object? photoKey = freezed,
    Object? status = null,
    Object? confirmedAt = freezed,
    Object? disputedAt = freezed,
    Object? resolvedAt = freezed,
    Object? cancelledAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? children = null,
    Object? disputes = null,
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
        resolvedAmount: freezed == resolvedAmount
            ? _value.resolvedAmount
            : resolvedAmount // ignore: cast_nullable_to_non_nullable
                  as int?,
        comment: freezed == comment
            ? _value.comment
            : comment // ignore: cast_nullable_to_non_nullable
                  as String?,
        photoKey: freezed == photoKey
            ? _value.photoKey
            : photoKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PaymentStatus,
        confirmedAt: freezed == confirmedAt
            ? _value.confirmedAt
            : confirmedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        disputedAt: freezed == disputedAt
            ? _value.disputedAt
            : disputedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        resolvedAt: freezed == resolvedAt
            ? _value.resolvedAt
            : resolvedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        cancelledAt: freezed == cancelledAt
            ? _value.cancelledAt
            : cancelledAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
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
        disputes: null == disputes
            ? _value._disputes
            : disputes // ignore: cast_nullable_to_non_nullable
                  as List<PaymentDispute>,
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
    this.resolvedAmount,
    this.comment,
    this.photoKey,
    required this.status,
    this.confirmedAt,
    this.disputedAt,
    this.resolvedAt,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
    final List<Payment> children = const <Payment>[],
    final List<PaymentDispute> disputes = const <PaymentDispute>[],
  }) : _children = children,
       _disputes = disputes;

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
  final int? resolvedAmount;
  @override
  final String? comment;
  @override
  final String? photoKey;
  @override
  final PaymentStatus status;
  @override
  final DateTime? confirmedAt;
  @override
  final DateTime? disputedAt;
  @override
  final DateTime? resolvedAt;
  @override
  final DateTime? cancelledAt;
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

  final List<PaymentDispute> _disputes;
  @override
  @JsonKey()
  List<PaymentDispute> get disputes {
    if (_disputes is EqualUnmodifiableListView) return _disputes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_disputes);
  }

  @override
  String toString() {
    return 'Payment(id: $id, projectId: $projectId, stageId: $stageId, parentPaymentId: $parentPaymentId, kind: $kind, fromUserId: $fromUserId, toUserId: $toUserId, amount: $amount, resolvedAmount: $resolvedAmount, comment: $comment, photoKey: $photoKey, status: $status, confirmedAt: $confirmedAt, disputedAt: $disputedAt, resolvedAt: $resolvedAt, cancelledAt: $cancelledAt, createdAt: $createdAt, updatedAt: $updatedAt, children: $children, disputes: $disputes)';
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
            (identical(other.resolvedAmount, resolvedAmount) ||
                other.resolvedAmount == resolvedAmount) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.photoKey, photoKey) ||
                other.photoKey == photoKey) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt) &&
            (identical(other.disputedAt, disputedAt) ||
                other.disputedAt == disputedAt) &&
            (identical(other.resolvedAt, resolvedAt) ||
                other.resolvedAt == resolvedAt) &&
            (identical(other.cancelledAt, cancelledAt) ||
                other.cancelledAt == cancelledAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._children, _children) &&
            const DeepCollectionEquality().equals(other._disputes, _disputes));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    projectId,
    stageId,
    parentPaymentId,
    kind,
    fromUserId,
    toUserId,
    amount,
    resolvedAmount,
    comment,
    photoKey,
    status,
    confirmedAt,
    disputedAt,
    resolvedAt,
    cancelledAt,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_children),
    const DeepCollectionEquality().hash(_disputes),
  ]);

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
    final int? resolvedAmount,
    final String? comment,
    final String? photoKey,
    required final PaymentStatus status,
    final DateTime? confirmedAt,
    final DateTime? disputedAt,
    final DateTime? resolvedAt,
    final DateTime? cancelledAt,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final List<Payment> children,
    final List<PaymentDispute> disputes,
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
  int? get resolvedAmount;
  @override
  String? get comment;
  @override
  String? get photoKey;
  @override
  PaymentStatus get status;
  @override
  DateTime? get confirmedAt;
  @override
  DateTime? get disputedAt;
  @override
  DateTime? get resolvedAt;
  @override
  DateTime? get cancelledAt;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  List<Payment> get children;
  @override
  List<PaymentDispute> get disputes;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
