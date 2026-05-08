// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tool.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ToolItem {
  String get id => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get totalQty => throw _privateConstructorUsedError;
  int get issuedQty => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;
  String? get photoKey => throw _privateConstructorUsedError;

  /// П2.14 — серийный/инвентарный номер.
  String? get serial => throw _privateConstructorUsedError;

  /// П2.15 — если задан, инструмент привязан к проекту (виден в реестре).
  String? get projectId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of ToolItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ToolItemCopyWith<ToolItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToolItemCopyWith<$Res> {
  factory $ToolItemCopyWith(ToolItem value, $Res Function(ToolItem) then) =
      _$ToolItemCopyWithImpl<$Res, ToolItem>;
  @useResult
  $Res call({
    String id,
    String ownerId,
    String name,
    int totalQty,
    int issuedQty,
    String? unit,
    String? photoKey,
    String? serial,
    String? projectId,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$ToolItemCopyWithImpl<$Res, $Val extends ToolItem>
    implements $ToolItemCopyWith<$Res> {
  _$ToolItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ToolItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? name = null,
    Object? totalQty = null,
    Object? issuedQty = null,
    Object? unit = freezed,
    Object? photoKey = freezed,
    Object? serial = freezed,
    Object? projectId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            ownerId: null == ownerId
                ? _value.ownerId
                : ownerId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            totalQty: null == totalQty
                ? _value.totalQty
                : totalQty // ignore: cast_nullable_to_non_nullable
                      as int,
            issuedQty: null == issuedQty
                ? _value.issuedQty
                : issuedQty // ignore: cast_nullable_to_non_nullable
                      as int,
            unit: freezed == unit
                ? _value.unit
                : unit // ignore: cast_nullable_to_non_nullable
                      as String?,
            photoKey: freezed == photoKey
                ? _value.photoKey
                : photoKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            serial: freezed == serial
                ? _value.serial
                : serial // ignore: cast_nullable_to_non_nullable
                      as String?,
            projectId: freezed == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ToolItemImplCopyWith<$Res>
    implements $ToolItemCopyWith<$Res> {
  factory _$$ToolItemImplCopyWith(
    _$ToolItemImpl value,
    $Res Function(_$ToolItemImpl) then,
  ) = __$$ToolItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String ownerId,
    String name,
    int totalQty,
    int issuedQty,
    String? unit,
    String? photoKey,
    String? serial,
    String? projectId,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$ToolItemImplCopyWithImpl<$Res>
    extends _$ToolItemCopyWithImpl<$Res, _$ToolItemImpl>
    implements _$$ToolItemImplCopyWith<$Res> {
  __$$ToolItemImplCopyWithImpl(
    _$ToolItemImpl _value,
    $Res Function(_$ToolItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ToolItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? name = null,
    Object? totalQty = null,
    Object? issuedQty = null,
    Object? unit = freezed,
    Object? photoKey = freezed,
    Object? serial = freezed,
    Object? projectId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$ToolItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerId: null == ownerId
            ? _value.ownerId
            : ownerId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        totalQty: null == totalQty
            ? _value.totalQty
            : totalQty // ignore: cast_nullable_to_non_nullable
                  as int,
        issuedQty: null == issuedQty
            ? _value.issuedQty
            : issuedQty // ignore: cast_nullable_to_non_nullable
                  as int,
        unit: freezed == unit
            ? _value.unit
            : unit // ignore: cast_nullable_to_non_nullable
                  as String?,
        photoKey: freezed == photoKey
            ? _value.photoKey
            : photoKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        serial: freezed == serial
            ? _value.serial
            : serial // ignore: cast_nullable_to_non_nullable
                  as String?,
        projectId: freezed == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
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

class _$ToolItemImpl implements _ToolItem {
  const _$ToolItemImpl({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.totalQty,
    required this.issuedQty,
    this.unit,
    this.photoKey,
    this.serial,
    this.projectId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  final String id;
  @override
  final String ownerId;
  @override
  final String name;
  @override
  final int totalQty;
  @override
  final int issuedQty;
  @override
  final String? unit;
  @override
  final String? photoKey;

  /// П2.14 — серийный/инвентарный номер.
  @override
  final String? serial;

  /// П2.15 — если задан, инструмент привязан к проекту (виден в реестре).
  @override
  final String? projectId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ToolItem(id: $id, ownerId: $ownerId, name: $name, totalQty: $totalQty, issuedQty: $issuedQty, unit: $unit, photoKey: $photoKey, serial: $serial, projectId: $projectId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.totalQty, totalQty) ||
                other.totalQty == totalQty) &&
            (identical(other.issuedQty, issuedQty) ||
                other.issuedQty == issuedQty) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.photoKey, photoKey) ||
                other.photoKey == photoKey) &&
            (identical(other.serial, serial) || other.serial == serial) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    ownerId,
    name,
    totalQty,
    issuedQty,
    unit,
    photoKey,
    serial,
    projectId,
    createdAt,
    updatedAt,
  );

  /// Create a copy of ToolItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolItemImplCopyWith<_$ToolItemImpl> get copyWith =>
      __$$ToolItemImplCopyWithImpl<_$ToolItemImpl>(this, _$identity);
}

abstract class _ToolItem implements ToolItem {
  const factory _ToolItem({
    required final String id,
    required final String ownerId,
    required final String name,
    required final int totalQty,
    required final int issuedQty,
    final String? unit,
    final String? photoKey,
    final String? serial,
    final String? projectId,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$ToolItemImpl;

  @override
  String get id;
  @override
  String get ownerId;
  @override
  String get name;
  @override
  int get totalQty;
  @override
  int get issuedQty;
  @override
  String? get unit;
  @override
  String? get photoKey;

  /// П2.14 — серийный/инвентарный номер.
  @override
  String? get serial;

  /// П2.15 — если задан, инструмент привязан к проекту (виден в реестре).
  @override
  String? get projectId;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of ToolItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ToolItemImplCopyWith<_$ToolItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ToolIssuance {
  String get id => throw _privateConstructorUsedError;
  String get toolItemId => throw _privateConstructorUsedError;
  String? get projectId => throw _privateConstructorUsedError;
  String? get stageId => throw _privateConstructorUsedError;
  String get toUserId => throw _privateConstructorUsedError;
  String get issuedById => throw _privateConstructorUsedError;
  int get qty => throw _privateConstructorUsedError;
  int? get returnedQty => throw _privateConstructorUsedError;
  ToolIssuanceStatus get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  ToolItem? get tool => throw _privateConstructorUsedError;

  /// Create a copy of ToolIssuance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ToolIssuanceCopyWith<ToolIssuance> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToolIssuanceCopyWith<$Res> {
  factory $ToolIssuanceCopyWith(
    ToolIssuance value,
    $Res Function(ToolIssuance) then,
  ) = _$ToolIssuanceCopyWithImpl<$Res, ToolIssuance>;
  @useResult
  $Res call({
    String id,
    String toolItemId,
    String? projectId,
    String? stageId,
    String toUserId,
    String issuedById,
    int qty,
    int? returnedQty,
    ToolIssuanceStatus status,
    DateTime createdAt,
    DateTime updatedAt,
    ToolItem? tool,
  });

  $ToolItemCopyWith<$Res>? get tool;
}

/// @nodoc
class _$ToolIssuanceCopyWithImpl<$Res, $Val extends ToolIssuance>
    implements $ToolIssuanceCopyWith<$Res> {
  _$ToolIssuanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ToolIssuance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? toolItemId = null,
    Object? projectId = freezed,
    Object? stageId = freezed,
    Object? toUserId = null,
    Object? issuedById = null,
    Object? qty = null,
    Object? returnedQty = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? tool = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            toolItemId: null == toolItemId
                ? _value.toolItemId
                : toolItemId // ignore: cast_nullable_to_non_nullable
                      as String,
            projectId: freezed == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String?,
            stageId: freezed == stageId
                ? _value.stageId
                : stageId // ignore: cast_nullable_to_non_nullable
                      as String?,
            toUserId: null == toUserId
                ? _value.toUserId
                : toUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            issuedById: null == issuedById
                ? _value.issuedById
                : issuedById // ignore: cast_nullable_to_non_nullable
                      as String,
            qty: null == qty
                ? _value.qty
                : qty // ignore: cast_nullable_to_non_nullable
                      as int,
            returnedQty: freezed == returnedQty
                ? _value.returnedQty
                : returnedQty // ignore: cast_nullable_to_non_nullable
                      as int?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ToolIssuanceStatus,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            tool: freezed == tool
                ? _value.tool
                : tool // ignore: cast_nullable_to_non_nullable
                      as ToolItem?,
          )
          as $Val,
    );
  }

  /// Create a copy of ToolIssuance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ToolItemCopyWith<$Res>? get tool {
    if (_value.tool == null) {
      return null;
    }

    return $ToolItemCopyWith<$Res>(_value.tool!, (value) {
      return _then(_value.copyWith(tool: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ToolIssuanceImplCopyWith<$Res>
    implements $ToolIssuanceCopyWith<$Res> {
  factory _$$ToolIssuanceImplCopyWith(
    _$ToolIssuanceImpl value,
    $Res Function(_$ToolIssuanceImpl) then,
  ) = __$$ToolIssuanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String toolItemId,
    String? projectId,
    String? stageId,
    String toUserId,
    String issuedById,
    int qty,
    int? returnedQty,
    ToolIssuanceStatus status,
    DateTime createdAt,
    DateTime updatedAt,
    ToolItem? tool,
  });

  @override
  $ToolItemCopyWith<$Res>? get tool;
}

/// @nodoc
class __$$ToolIssuanceImplCopyWithImpl<$Res>
    extends _$ToolIssuanceCopyWithImpl<$Res, _$ToolIssuanceImpl>
    implements _$$ToolIssuanceImplCopyWith<$Res> {
  __$$ToolIssuanceImplCopyWithImpl(
    _$ToolIssuanceImpl _value,
    $Res Function(_$ToolIssuanceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ToolIssuance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? toolItemId = null,
    Object? projectId = freezed,
    Object? stageId = freezed,
    Object? toUserId = null,
    Object? issuedById = null,
    Object? qty = null,
    Object? returnedQty = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? tool = freezed,
  }) {
    return _then(
      _$ToolIssuanceImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        toolItemId: null == toolItemId
            ? _value.toolItemId
            : toolItemId // ignore: cast_nullable_to_non_nullable
                  as String,
        projectId: freezed == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String?,
        stageId: freezed == stageId
            ? _value.stageId
            : stageId // ignore: cast_nullable_to_non_nullable
                  as String?,
        toUserId: null == toUserId
            ? _value.toUserId
            : toUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        issuedById: null == issuedById
            ? _value.issuedById
            : issuedById // ignore: cast_nullable_to_non_nullable
                  as String,
        qty: null == qty
            ? _value.qty
            : qty // ignore: cast_nullable_to_non_nullable
                  as int,
        returnedQty: freezed == returnedQty
            ? _value.returnedQty
            : returnedQty // ignore: cast_nullable_to_non_nullable
                  as int?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ToolIssuanceStatus,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        tool: freezed == tool
            ? _value.tool
            : tool // ignore: cast_nullable_to_non_nullable
                  as ToolItem?,
      ),
    );
  }
}

/// @nodoc

class _$ToolIssuanceImpl implements _ToolIssuance {
  const _$ToolIssuanceImpl({
    required this.id,
    required this.toolItemId,
    this.projectId,
    this.stageId,
    required this.toUserId,
    required this.issuedById,
    required this.qty,
    this.returnedQty,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.tool,
  });

  @override
  final String id;
  @override
  final String toolItemId;
  @override
  final String? projectId;
  @override
  final String? stageId;
  @override
  final String toUserId;
  @override
  final String issuedById;
  @override
  final int qty;
  @override
  final int? returnedQty;
  @override
  final ToolIssuanceStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final ToolItem? tool;

  @override
  String toString() {
    return 'ToolIssuance(id: $id, toolItemId: $toolItemId, projectId: $projectId, stageId: $stageId, toUserId: $toUserId, issuedById: $issuedById, qty: $qty, returnedQty: $returnedQty, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, tool: $tool)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolIssuanceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.toolItemId, toolItemId) ||
                other.toolItemId == toolItemId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.stageId, stageId) || other.stageId == stageId) &&
            (identical(other.toUserId, toUserId) ||
                other.toUserId == toUserId) &&
            (identical(other.issuedById, issuedById) ||
                other.issuedById == issuedById) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.returnedQty, returnedQty) ||
                other.returnedQty == returnedQty) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.tool, tool) || other.tool == tool));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    toolItemId,
    projectId,
    stageId,
    toUserId,
    issuedById,
    qty,
    returnedQty,
    status,
    createdAt,
    updatedAt,
    tool,
  );

  /// Create a copy of ToolIssuance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolIssuanceImplCopyWith<_$ToolIssuanceImpl> get copyWith =>
      __$$ToolIssuanceImplCopyWithImpl<_$ToolIssuanceImpl>(this, _$identity);
}

abstract class _ToolIssuance implements ToolIssuance {
  const factory _ToolIssuance({
    required final String id,
    required final String toolItemId,
    final String? projectId,
    final String? stageId,
    required final String toUserId,
    required final String issuedById,
    required final int qty,
    final int? returnedQty,
    required final ToolIssuanceStatus status,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final ToolItem? tool,
  }) = _$ToolIssuanceImpl;

  @override
  String get id;
  @override
  String get toolItemId;
  @override
  String? get projectId;
  @override
  String? get stageId;
  @override
  String get toUserId;
  @override
  String get issuedById;
  @override
  int get qty;
  @override
  int? get returnedQty;
  @override
  ToolIssuanceStatus get status;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  ToolItem? get tool;

  /// Create a copy of ToolIssuance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ToolIssuanceImplCopyWith<_$ToolIssuanceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
