// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'substep.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Substep {
  String get id => throw _privateConstructorUsedError;
  String get stepId => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  String get authorId => throw _privateConstructorUsedError;
  bool get isDone => throw _privateConstructorUsedError;
  DateTime? get doneAt => throw _privateConstructorUsedError;
  String? get doneById => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of Substep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubstepCopyWith<Substep> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubstepCopyWith<$Res> {
  factory $SubstepCopyWith(Substep value, $Res Function(Substep) then) =
      _$SubstepCopyWithImpl<$Res, Substep>;
  @useResult
  $Res call({
    String id,
    String stepId,
    String text,
    String authorId,
    bool isDone,
    DateTime? doneAt,
    String? doneById,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$SubstepCopyWithImpl<$Res, $Val extends Substep>
    implements $SubstepCopyWith<$Res> {
  _$SubstepCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Substep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? stepId = null,
    Object? text = null,
    Object? authorId = null,
    Object? isDone = null,
    Object? doneAt = freezed,
    Object? doneById = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            stepId: null == stepId
                ? _value.stepId
                : stepId // ignore: cast_nullable_to_non_nullable
                      as String,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            authorId: null == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String,
            isDone: null == isDone
                ? _value.isDone
                : isDone // ignore: cast_nullable_to_non_nullable
                      as bool,
            doneAt: freezed == doneAt
                ? _value.doneAt
                : doneAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            doneById: freezed == doneById
                ? _value.doneById
                : doneById // ignore: cast_nullable_to_non_nullable
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
abstract class _$$SubstepImplCopyWith<$Res> implements $SubstepCopyWith<$Res> {
  factory _$$SubstepImplCopyWith(
    _$SubstepImpl value,
    $Res Function(_$SubstepImpl) then,
  ) = __$$SubstepImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String stepId,
    String text,
    String authorId,
    bool isDone,
    DateTime? doneAt,
    String? doneById,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$SubstepImplCopyWithImpl<$Res>
    extends _$SubstepCopyWithImpl<$Res, _$SubstepImpl>
    implements _$$SubstepImplCopyWith<$Res> {
  __$$SubstepImplCopyWithImpl(
    _$SubstepImpl _value,
    $Res Function(_$SubstepImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Substep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? stepId = null,
    Object? text = null,
    Object? authorId = null,
    Object? isDone = null,
    Object? doneAt = freezed,
    Object? doneById = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$SubstepImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        stepId: null == stepId
            ? _value.stepId
            : stepId // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        authorId: null == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String,
        isDone: null == isDone
            ? _value.isDone
            : isDone // ignore: cast_nullable_to_non_nullable
                  as bool,
        doneAt: freezed == doneAt
            ? _value.doneAt
            : doneAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        doneById: freezed == doneById
            ? _value.doneById
            : doneById // ignore: cast_nullable_to_non_nullable
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

class _$SubstepImpl implements _Substep {
  const _$SubstepImpl({
    required this.id,
    required this.stepId,
    required this.text,
    required this.authorId,
    required this.isDone,
    this.doneAt,
    this.doneById,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  final String id;
  @override
  final String stepId;
  @override
  final String text;
  @override
  final String authorId;
  @override
  final bool isDone;
  @override
  final DateTime? doneAt;
  @override
  final String? doneById;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Substep(id: $id, stepId: $stepId, text: $text, authorId: $authorId, isDone: $isDone, doneAt: $doneAt, doneById: $doneById, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubstepImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.stepId, stepId) || other.stepId == stepId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.isDone, isDone) || other.isDone == isDone) &&
            (identical(other.doneAt, doneAt) || other.doneAt == doneAt) &&
            (identical(other.doneById, doneById) ||
                other.doneById == doneById) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    stepId,
    text,
    authorId,
    isDone,
    doneAt,
    doneById,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Substep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubstepImplCopyWith<_$SubstepImpl> get copyWith =>
      __$$SubstepImplCopyWithImpl<_$SubstepImpl>(this, _$identity);
}

abstract class _Substep implements Substep {
  const factory _Substep({
    required final String id,
    required final String stepId,
    required final String text,
    required final String authorId,
    required final bool isDone,
    final DateTime? doneAt,
    final String? doneById,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$SubstepImpl;

  @override
  String get id;
  @override
  String get stepId;
  @override
  String get text;
  @override
  String get authorId;
  @override
  bool get isDone;
  @override
  DateTime? get doneAt;
  @override
  String? get doneById;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Substep
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubstepImplCopyWith<_$SubstepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
