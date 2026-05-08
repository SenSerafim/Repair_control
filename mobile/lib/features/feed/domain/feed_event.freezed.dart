// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$FeedEvent {
  String get id => throw _privateConstructorUsedError;
  String get projectId => throw _privateConstructorUsedError;
  String? get stageId => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;
  String get actorId => throw _privateConstructorUsedError;
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of FeedEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeedEventCopyWith<FeedEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedEventCopyWith<$Res> {
  factory $FeedEventCopyWith(FeedEvent value, $Res Function(FeedEvent) then) =
      _$FeedEventCopyWithImpl<$Res, FeedEvent>;
  @useResult
  $Res call({
    String id,
    String projectId,
    String? stageId,
    String kind,
    String actorId,
    Map<String, dynamic> payload,
    DateTime createdAt,
  });
}

/// @nodoc
class _$FeedEventCopyWithImpl<$Res, $Val extends FeedEvent>
    implements $FeedEventCopyWith<$Res> {
  _$FeedEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeedEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? stageId = freezed,
    Object? kind = null,
    Object? actorId = null,
    Object? payload = null,
    Object? createdAt = null,
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
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as String,
            actorId: null == actorId
                ? _value.actorId
                : actorId // ignore: cast_nullable_to_non_nullable
                      as String,
            payload: null == payload
                ? _value.payload
                : payload // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
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
abstract class _$$FeedEventImplCopyWith<$Res>
    implements $FeedEventCopyWith<$Res> {
  factory _$$FeedEventImplCopyWith(
    _$FeedEventImpl value,
    $Res Function(_$FeedEventImpl) then,
  ) = __$$FeedEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String projectId,
    String? stageId,
    String kind,
    String actorId,
    Map<String, dynamic> payload,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$FeedEventImplCopyWithImpl<$Res>
    extends _$FeedEventCopyWithImpl<$Res, _$FeedEventImpl>
    implements _$$FeedEventImplCopyWith<$Res> {
  __$$FeedEventImplCopyWithImpl(
    _$FeedEventImpl _value,
    $Res Function(_$FeedEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FeedEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? stageId = freezed,
    Object? kind = null,
    Object? actorId = null,
    Object? payload = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$FeedEventImpl(
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
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as String,
        actorId: null == actorId
            ? _value.actorId
            : actorId // ignore: cast_nullable_to_non_nullable
                  as String,
        payload: null == payload
            ? _value._payload
            : payload // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$FeedEventImpl implements _FeedEvent {
  const _$FeedEventImpl({
    required this.id,
    required this.projectId,
    this.stageId,
    required this.kind,
    required this.actorId,
    final Map<String, dynamic> payload = const <String, dynamic>{},
    required this.createdAt,
  }) : _payload = payload;

  @override
  final String id;
  @override
  final String projectId;
  @override
  final String? stageId;
  @override
  final String kind;
  @override
  final String actorId;
  final Map<String, dynamic> _payload;
  @override
  @JsonKey()
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'FeedEvent(id: $id, projectId: $projectId, stageId: $stageId, kind: $kind, actorId: $actorId, payload: $payload, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.stageId, stageId) || other.stageId == stageId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.actorId, actorId) || other.actorId == actorId) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    projectId,
    stageId,
    kind,
    actorId,
    const DeepCollectionEquality().hash(_payload),
    createdAt,
  );

  /// Create a copy of FeedEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedEventImplCopyWith<_$FeedEventImpl> get copyWith =>
      __$$FeedEventImplCopyWithImpl<_$FeedEventImpl>(this, _$identity);
}

abstract class _FeedEvent implements FeedEvent {
  const factory _FeedEvent({
    required final String id,
    required final String projectId,
    final String? stageId,
    required final String kind,
    required final String actorId,
    final Map<String, dynamic> payload,
    required final DateTime createdAt,
  }) = _$FeedEventImpl;

  @override
  String get id;
  @override
  String get projectId;
  @override
  String? get stageId;
  @override
  String get kind;
  @override
  String get actorId;
  @override
  Map<String, dynamic> get payload;
  @override
  DateTime get createdAt;

  /// Create a copy of FeedEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeedEventImplCopyWith<_$FeedEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
