// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'question.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Question {
  String get id => throw _privateConstructorUsedError;
  String get stepId => throw _privateConstructorUsedError;
  String get authorId => throw _privateConstructorUsedError;
  String get addresseeId => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  QuestionStatus get status => throw _privateConstructorUsedError;
  String? get answer => throw _privateConstructorUsedError;
  DateTime? get answeredAt => throw _privateConstructorUsedError;
  String? get answeredBy => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of Question
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuestionCopyWith<Question> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestionCopyWith<$Res> {
  factory $QuestionCopyWith(Question value, $Res Function(Question) then) =
      _$QuestionCopyWithImpl<$Res, Question>;
  @useResult
  $Res call({
    String id,
    String stepId,
    String authorId,
    String addresseeId,
    String text,
    QuestionStatus status,
    String? answer,
    DateTime? answeredAt,
    String? answeredBy,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$QuestionCopyWithImpl<$Res, $Val extends Question>
    implements $QuestionCopyWith<$Res> {
  _$QuestionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Question
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? stepId = null,
    Object? authorId = null,
    Object? addresseeId = null,
    Object? text = null,
    Object? status = null,
    Object? answer = freezed,
    Object? answeredAt = freezed,
    Object? answeredBy = freezed,
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
            authorId: null == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String,
            addresseeId: null == addresseeId
                ? _value.addresseeId
                : addresseeId // ignore: cast_nullable_to_non_nullable
                      as String,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as QuestionStatus,
            answer: freezed == answer
                ? _value.answer
                : answer // ignore: cast_nullable_to_non_nullable
                      as String?,
            answeredAt: freezed == answeredAt
                ? _value.answeredAt
                : answeredAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            answeredBy: freezed == answeredBy
                ? _value.answeredBy
                : answeredBy // ignore: cast_nullable_to_non_nullable
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
abstract class _$$QuestionImplCopyWith<$Res>
    implements $QuestionCopyWith<$Res> {
  factory _$$QuestionImplCopyWith(
    _$QuestionImpl value,
    $Res Function(_$QuestionImpl) then,
  ) = __$$QuestionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String stepId,
    String authorId,
    String addresseeId,
    String text,
    QuestionStatus status,
    String? answer,
    DateTime? answeredAt,
    String? answeredBy,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$QuestionImplCopyWithImpl<$Res>
    extends _$QuestionCopyWithImpl<$Res, _$QuestionImpl>
    implements _$$QuestionImplCopyWith<$Res> {
  __$$QuestionImplCopyWithImpl(
    _$QuestionImpl _value,
    $Res Function(_$QuestionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Question
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? stepId = null,
    Object? authorId = null,
    Object? addresseeId = null,
    Object? text = null,
    Object? status = null,
    Object? answer = freezed,
    Object? answeredAt = freezed,
    Object? answeredBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$QuestionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        stepId: null == stepId
            ? _value.stepId
            : stepId // ignore: cast_nullable_to_non_nullable
                  as String,
        authorId: null == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String,
        addresseeId: null == addresseeId
            ? _value.addresseeId
            : addresseeId // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as QuestionStatus,
        answer: freezed == answer
            ? _value.answer
            : answer // ignore: cast_nullable_to_non_nullable
                  as String?,
        answeredAt: freezed == answeredAt
            ? _value.answeredAt
            : answeredAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        answeredBy: freezed == answeredBy
            ? _value.answeredBy
            : answeredBy // ignore: cast_nullable_to_non_nullable
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

class _$QuestionImpl implements _Question {
  const _$QuestionImpl({
    required this.id,
    required this.stepId,
    required this.authorId,
    required this.addresseeId,
    required this.text,
    required this.status,
    this.answer,
    this.answeredAt,
    this.answeredBy,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  final String id;
  @override
  final String stepId;
  @override
  final String authorId;
  @override
  final String addresseeId;
  @override
  final String text;
  @override
  final QuestionStatus status;
  @override
  final String? answer;
  @override
  final DateTime? answeredAt;
  @override
  final String? answeredBy;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Question(id: $id, stepId: $stepId, authorId: $authorId, addresseeId: $addresseeId, text: $text, status: $status, answer: $answer, answeredAt: $answeredAt, answeredBy: $answeredBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.stepId, stepId) || other.stepId == stepId) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.addresseeId, addresseeId) ||
                other.addresseeId == addresseeId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.answer, answer) || other.answer == answer) &&
            (identical(other.answeredAt, answeredAt) ||
                other.answeredAt == answeredAt) &&
            (identical(other.answeredBy, answeredBy) ||
                other.answeredBy == answeredBy) &&
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
    authorId,
    addresseeId,
    text,
    status,
    answer,
    answeredAt,
    answeredBy,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Question
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestionImplCopyWith<_$QuestionImpl> get copyWith =>
      __$$QuestionImplCopyWithImpl<_$QuestionImpl>(this, _$identity);
}

abstract class _Question implements Question {
  const factory _Question({
    required final String id,
    required final String stepId,
    required final String authorId,
    required final String addresseeId,
    required final String text,
    required final QuestionStatus status,
    final String? answer,
    final DateTime? answeredAt,
    final String? answeredBy,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$QuestionImpl;

  @override
  String get id;
  @override
  String get stepId;
  @override
  String get authorId;
  @override
  String get addresseeId;
  @override
  String get text;
  @override
  QuestionStatus get status;
  @override
  String? get answer;
  @override
  DateTime? get answeredAt;
  @override
  String? get answeredBy;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Question
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuestionImplCopyWith<_$QuestionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
