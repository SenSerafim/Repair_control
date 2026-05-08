// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'step.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Step {
  String get id => throw _privateConstructorUsedError;
  String get stageId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  StepType get type => throw _privateConstructorUsedError;
  StepStatus get status => throw _privateConstructorUsedError;
  int? get price => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get authorId => throw _privateConstructorUsedError;
  List<String> get assigneeIds => throw _privateConstructorUsedError;
  DateTime? get doneAt => throw _privateConstructorUsedError;
  String? get doneById => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  int get substepsCount => throw _privateConstructorUsedError;
  int get substepsDone => throw _privateConstructorUsedError;
  int get photosCount => throw _privateConstructorUsedError;

  /// Опциональная ссылка на статью методички. Если бэк прислал id —
  /// `StepDetailScreen` показывает кнопку «Открыть методичку»
  /// (deep-link на `/methodology/articles/:id`).
  String? get methodologyArticleId => throw _privateConstructorUsedError;

  /// П2.8 — отчёт мастера/бригадира при закрытии шага. Опциональные текстовые
  /// поля «что делал» / «как делал». Прочитать в UI: ReportSection.
  String? get whatDid => throw _privateConstructorUsedError;
  String? get howDid => throw _privateConstructorUsedError;

  /// Create a copy of Step
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StepCopyWith<Step> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StepCopyWith<$Res> {
  factory $StepCopyWith(Step value, $Res Function(Step) then) =
      _$StepCopyWithImpl<$Res, Step>;
  @useResult
  $Res call({
    String id,
    String stageId,
    String title,
    int orderIndex,
    StepType type,
    StepStatus status,
    int? price,
    String? description,
    String authorId,
    List<String> assigneeIds,
    DateTime? doneAt,
    String? doneById,
    DateTime createdAt,
    DateTime updatedAt,
    int substepsCount,
    int substepsDone,
    int photosCount,
    String? methodologyArticleId,
    String? whatDid,
    String? howDid,
  });
}

/// @nodoc
class _$StepCopyWithImpl<$Res, $Val extends Step>
    implements $StepCopyWith<$Res> {
  _$StepCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Step
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? stageId = null,
    Object? title = null,
    Object? orderIndex = null,
    Object? type = null,
    Object? status = null,
    Object? price = freezed,
    Object? description = freezed,
    Object? authorId = null,
    Object? assigneeIds = null,
    Object? doneAt = freezed,
    Object? doneById = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? substepsCount = null,
    Object? substepsDone = null,
    Object? photosCount = null,
    Object? methodologyArticleId = freezed,
    Object? whatDid = freezed,
    Object? howDid = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            stageId: null == stageId
                ? _value.stageId
                : stageId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            orderIndex: null == orderIndex
                ? _value.orderIndex
                : orderIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as StepType,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as StepStatus,
            price: freezed == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as int?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            authorId: null == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String,
            assigneeIds: null == assigneeIds
                ? _value.assigneeIds
                : assigneeIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
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
            substepsCount: null == substepsCount
                ? _value.substepsCount
                : substepsCount // ignore: cast_nullable_to_non_nullable
                      as int,
            substepsDone: null == substepsDone
                ? _value.substepsDone
                : substepsDone // ignore: cast_nullable_to_non_nullable
                      as int,
            photosCount: null == photosCount
                ? _value.photosCount
                : photosCount // ignore: cast_nullable_to_non_nullable
                      as int,
            methodologyArticleId: freezed == methodologyArticleId
                ? _value.methodologyArticleId
                : methodologyArticleId // ignore: cast_nullable_to_non_nullable
                      as String?,
            whatDid: freezed == whatDid
                ? _value.whatDid
                : whatDid // ignore: cast_nullable_to_non_nullable
                      as String?,
            howDid: freezed == howDid
                ? _value.howDid
                : howDid // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StepImplCopyWith<$Res> implements $StepCopyWith<$Res> {
  factory _$$StepImplCopyWith(
    _$StepImpl value,
    $Res Function(_$StepImpl) then,
  ) = __$$StepImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String stageId,
    String title,
    int orderIndex,
    StepType type,
    StepStatus status,
    int? price,
    String? description,
    String authorId,
    List<String> assigneeIds,
    DateTime? doneAt,
    String? doneById,
    DateTime createdAt,
    DateTime updatedAt,
    int substepsCount,
    int substepsDone,
    int photosCount,
    String? methodologyArticleId,
    String? whatDid,
    String? howDid,
  });
}

/// @nodoc
class __$$StepImplCopyWithImpl<$Res>
    extends _$StepCopyWithImpl<$Res, _$StepImpl>
    implements _$$StepImplCopyWith<$Res> {
  __$$StepImplCopyWithImpl(_$StepImpl _value, $Res Function(_$StepImpl) _then)
    : super(_value, _then);

  /// Create a copy of Step
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? stageId = null,
    Object? title = null,
    Object? orderIndex = null,
    Object? type = null,
    Object? status = null,
    Object? price = freezed,
    Object? description = freezed,
    Object? authorId = null,
    Object? assigneeIds = null,
    Object? doneAt = freezed,
    Object? doneById = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? substepsCount = null,
    Object? substepsDone = null,
    Object? photosCount = null,
    Object? methodologyArticleId = freezed,
    Object? whatDid = freezed,
    Object? howDid = freezed,
  }) {
    return _then(
      _$StepImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        stageId: null == stageId
            ? _value.stageId
            : stageId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        orderIndex: null == orderIndex
            ? _value.orderIndex
            : orderIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as StepType,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as StepStatus,
        price: freezed == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as int?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        authorId: null == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String,
        assigneeIds: null == assigneeIds
            ? _value._assigneeIds
            : assigneeIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
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
        substepsCount: null == substepsCount
            ? _value.substepsCount
            : substepsCount // ignore: cast_nullable_to_non_nullable
                  as int,
        substepsDone: null == substepsDone
            ? _value.substepsDone
            : substepsDone // ignore: cast_nullable_to_non_nullable
                  as int,
        photosCount: null == photosCount
            ? _value.photosCount
            : photosCount // ignore: cast_nullable_to_non_nullable
                  as int,
        methodologyArticleId: freezed == methodologyArticleId
            ? _value.methodologyArticleId
            : methodologyArticleId // ignore: cast_nullable_to_non_nullable
                  as String?,
        whatDid: freezed == whatDid
            ? _value.whatDid
            : whatDid // ignore: cast_nullable_to_non_nullable
                  as String?,
        howDid: freezed == howDid
            ? _value.howDid
            : howDid // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$StepImpl implements _Step {
  const _$StepImpl({
    required this.id,
    required this.stageId,
    required this.title,
    required this.orderIndex,
    required this.type,
    required this.status,
    this.price,
    this.description,
    required this.authorId,
    final List<String> assigneeIds = const <String>[],
    this.doneAt,
    this.doneById,
    required this.createdAt,
    required this.updatedAt,
    this.substepsCount = 0,
    this.substepsDone = 0,
    this.photosCount = 0,
    this.methodologyArticleId,
    this.whatDid,
    this.howDid,
  }) : _assigneeIds = assigneeIds;

  @override
  final String id;
  @override
  final String stageId;
  @override
  final String title;
  @override
  final int orderIndex;
  @override
  final StepType type;
  @override
  final StepStatus status;
  @override
  final int? price;
  @override
  final String? description;
  @override
  final String authorId;
  final List<String> _assigneeIds;
  @override
  @JsonKey()
  List<String> get assigneeIds {
    if (_assigneeIds is EqualUnmodifiableListView) return _assigneeIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assigneeIds);
  }

  @override
  final DateTime? doneAt;
  @override
  final String? doneById;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final int substepsCount;
  @override
  @JsonKey()
  final int substepsDone;
  @override
  @JsonKey()
  final int photosCount;

  /// Опциональная ссылка на статью методички. Если бэк прислал id —
  /// `StepDetailScreen` показывает кнопку «Открыть методичку»
  /// (deep-link на `/methodology/articles/:id`).
  @override
  final String? methodologyArticleId;

  /// П2.8 — отчёт мастера/бригадира при закрытии шага. Опциональные текстовые
  /// поля «что делал» / «как делал». Прочитать в UI: ReportSection.
  @override
  final String? whatDid;
  @override
  final String? howDid;

  @override
  String toString() {
    return 'Step(id: $id, stageId: $stageId, title: $title, orderIndex: $orderIndex, type: $type, status: $status, price: $price, description: $description, authorId: $authorId, assigneeIds: $assigneeIds, doneAt: $doneAt, doneById: $doneById, createdAt: $createdAt, updatedAt: $updatedAt, substepsCount: $substepsCount, substepsDone: $substepsDone, photosCount: $photosCount, methodologyArticleId: $methodologyArticleId, whatDid: $whatDid, howDid: $howDid)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StepImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.stageId, stageId) || other.stageId == stageId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            const DeepCollectionEquality().equals(
              other._assigneeIds,
              _assigneeIds,
            ) &&
            (identical(other.doneAt, doneAt) || other.doneAt == doneAt) &&
            (identical(other.doneById, doneById) ||
                other.doneById == doneById) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.substepsCount, substepsCount) ||
                other.substepsCount == substepsCount) &&
            (identical(other.substepsDone, substepsDone) ||
                other.substepsDone == substepsDone) &&
            (identical(other.photosCount, photosCount) ||
                other.photosCount == photosCount) &&
            (identical(other.methodologyArticleId, methodologyArticleId) ||
                other.methodologyArticleId == methodologyArticleId) &&
            (identical(other.whatDid, whatDid) || other.whatDid == whatDid) &&
            (identical(other.howDid, howDid) || other.howDid == howDid));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    stageId,
    title,
    orderIndex,
    type,
    status,
    price,
    description,
    authorId,
    const DeepCollectionEquality().hash(_assigneeIds),
    doneAt,
    doneById,
    createdAt,
    updatedAt,
    substepsCount,
    substepsDone,
    photosCount,
    methodologyArticleId,
    whatDid,
    howDid,
  ]);

  /// Create a copy of Step
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StepImplCopyWith<_$StepImpl> get copyWith =>
      __$$StepImplCopyWithImpl<_$StepImpl>(this, _$identity);
}

abstract class _Step implements Step {
  const factory _Step({
    required final String id,
    required final String stageId,
    required final String title,
    required final int orderIndex,
    required final StepType type,
    required final StepStatus status,
    final int? price,
    final String? description,
    required final String authorId,
    final List<String> assigneeIds,
    final DateTime? doneAt,
    final String? doneById,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final int substepsCount,
    final int substepsDone,
    final int photosCount,
    final String? methodologyArticleId,
    final String? whatDid,
    final String? howDid,
  }) = _$StepImpl;

  @override
  String get id;
  @override
  String get stageId;
  @override
  String get title;
  @override
  int get orderIndex;
  @override
  StepType get type;
  @override
  StepStatus get status;
  @override
  int? get price;
  @override
  String? get description;
  @override
  String get authorId;
  @override
  List<String> get assigneeIds;
  @override
  DateTime? get doneAt;
  @override
  String? get doneById;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  int get substepsCount;
  @override
  int get substepsDone;
  @override
  int get photosCount;

  /// Опциональная ссылка на статью методички. Если бэк прислал id —
  /// `StepDetailScreen` показывает кнопку «Открыть методичку»
  /// (deep-link на `/methodology/articles/:id`).
  @override
  String? get methodologyArticleId;

  /// П2.8 — отчёт мастера/бригадира при закрытии шага. Опциональные текстовые
  /// поля «что делал» / «как делал». Прочитать в UI: ReportSection.
  @override
  String? get whatDid;
  @override
  String? get howDid;

  /// Create a copy of Step
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StepImplCopyWith<_$StepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
