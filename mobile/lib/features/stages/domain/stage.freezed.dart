// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Stage {
  String get id => throw _privateConstructorUsedError;
  String get projectId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  StageStatus get status => throw _privateConstructorUsedError;
  DateTime? get plannedStart => throw _privateConstructorUsedError;
  DateTime? get plannedEnd => throw _privateConstructorUsedError;
  DateTime? get originalEnd => throw _privateConstructorUsedError;
  int get pauseDurationMs => throw _privateConstructorUsedError;
  int get workBudget => throw _privateConstructorUsedError;
  int get materialsBudget => throw _privateConstructorUsedError;
  List<String> get foremanIds => throw _privateConstructorUsedError;
  int get progressCache => throw _privateConstructorUsedError;
  bool get planApproved => throw _privateConstructorUsedError;
  DateTime? get startedAt => throw _privateConstructorUsedError;
  DateTime? get sentToReviewAt => throw _privateConstructorUsedError;
  DateTime? get doneAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of Stage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StageCopyWith<Stage> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StageCopyWith<$Res> {
  factory $StageCopyWith(Stage value, $Res Function(Stage) then) =
      _$StageCopyWithImpl<$Res, Stage>;
  @useResult
  $Res call({
    String id,
    String projectId,
    String title,
    int orderIndex,
    StageStatus status,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    DateTime? originalEnd,
    int pauseDurationMs,
    int workBudget,
    int materialsBudget,
    List<String> foremanIds,
    int progressCache,
    bool planApproved,
    DateTime? startedAt,
    DateTime? sentToReviewAt,
    DateTime? doneAt,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$StageCopyWithImpl<$Res, $Val extends Stage>
    implements $StageCopyWith<$Res> {
  _$StageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Stage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? title = null,
    Object? orderIndex = null,
    Object? status = null,
    Object? plannedStart = freezed,
    Object? plannedEnd = freezed,
    Object? originalEnd = freezed,
    Object? pauseDurationMs = null,
    Object? workBudget = null,
    Object? materialsBudget = null,
    Object? foremanIds = null,
    Object? progressCache = null,
    Object? planApproved = null,
    Object? startedAt = freezed,
    Object? sentToReviewAt = freezed,
    Object? doneAt = freezed,
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
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            orderIndex: null == orderIndex
                ? _value.orderIndex
                : orderIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as StageStatus,
            plannedStart: freezed == plannedStart
                ? _value.plannedStart
                : plannedStart // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            plannedEnd: freezed == plannedEnd
                ? _value.plannedEnd
                : plannedEnd // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            originalEnd: freezed == originalEnd
                ? _value.originalEnd
                : originalEnd // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            pauseDurationMs: null == pauseDurationMs
                ? _value.pauseDurationMs
                : pauseDurationMs // ignore: cast_nullable_to_non_nullable
                      as int,
            workBudget: null == workBudget
                ? _value.workBudget
                : workBudget // ignore: cast_nullable_to_non_nullable
                      as int,
            materialsBudget: null == materialsBudget
                ? _value.materialsBudget
                : materialsBudget // ignore: cast_nullable_to_non_nullable
                      as int,
            foremanIds: null == foremanIds
                ? _value.foremanIds
                : foremanIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            progressCache: null == progressCache
                ? _value.progressCache
                : progressCache // ignore: cast_nullable_to_non_nullable
                      as int,
            planApproved: null == planApproved
                ? _value.planApproved
                : planApproved // ignore: cast_nullable_to_non_nullable
                      as bool,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            sentToReviewAt: freezed == sentToReviewAt
                ? _value.sentToReviewAt
                : sentToReviewAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            doneAt: freezed == doneAt
                ? _value.doneAt
                : doneAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
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
abstract class _$$StageImplCopyWith<$Res> implements $StageCopyWith<$Res> {
  factory _$$StageImplCopyWith(
    _$StageImpl value,
    $Res Function(_$StageImpl) then,
  ) = __$$StageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String projectId,
    String title,
    int orderIndex,
    StageStatus status,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    DateTime? originalEnd,
    int pauseDurationMs,
    int workBudget,
    int materialsBudget,
    List<String> foremanIds,
    int progressCache,
    bool planApproved,
    DateTime? startedAt,
    DateTime? sentToReviewAt,
    DateTime? doneAt,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$StageImplCopyWithImpl<$Res>
    extends _$StageCopyWithImpl<$Res, _$StageImpl>
    implements _$$StageImplCopyWith<$Res> {
  __$$StageImplCopyWithImpl(
    _$StageImpl _value,
    $Res Function(_$StageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Stage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? title = null,
    Object? orderIndex = null,
    Object? status = null,
    Object? plannedStart = freezed,
    Object? plannedEnd = freezed,
    Object? originalEnd = freezed,
    Object? pauseDurationMs = null,
    Object? workBudget = null,
    Object? materialsBudget = null,
    Object? foremanIds = null,
    Object? progressCache = null,
    Object? planApproved = null,
    Object? startedAt = freezed,
    Object? sentToReviewAt = freezed,
    Object? doneAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$StageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        projectId: null == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        orderIndex: null == orderIndex
            ? _value.orderIndex
            : orderIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as StageStatus,
        plannedStart: freezed == plannedStart
            ? _value.plannedStart
            : plannedStart // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        plannedEnd: freezed == plannedEnd
            ? _value.plannedEnd
            : plannedEnd // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        originalEnd: freezed == originalEnd
            ? _value.originalEnd
            : originalEnd // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        pauseDurationMs: null == pauseDurationMs
            ? _value.pauseDurationMs
            : pauseDurationMs // ignore: cast_nullable_to_non_nullable
                  as int,
        workBudget: null == workBudget
            ? _value.workBudget
            : workBudget // ignore: cast_nullable_to_non_nullable
                  as int,
        materialsBudget: null == materialsBudget
            ? _value.materialsBudget
            : materialsBudget // ignore: cast_nullable_to_non_nullable
                  as int,
        foremanIds: null == foremanIds
            ? _value._foremanIds
            : foremanIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        progressCache: null == progressCache
            ? _value.progressCache
            : progressCache // ignore: cast_nullable_to_non_nullable
                  as int,
        planApproved: null == planApproved
            ? _value.planApproved
            : planApproved // ignore: cast_nullable_to_non_nullable
                  as bool,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        sentToReviewAt: freezed == sentToReviewAt
            ? _value.sentToReviewAt
            : sentToReviewAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        doneAt: freezed == doneAt
            ? _value.doneAt
            : doneAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
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

class _$StageImpl implements _Stage {
  const _$StageImpl({
    required this.id,
    required this.projectId,
    required this.title,
    required this.orderIndex,
    required this.status,
    this.plannedStart,
    this.plannedEnd,
    this.originalEnd,
    required this.pauseDurationMs,
    required this.workBudget,
    required this.materialsBudget,
    final List<String> foremanIds = const <String>[],
    required this.progressCache,
    required this.planApproved,
    this.startedAt,
    this.sentToReviewAt,
    this.doneAt,
    required this.createdAt,
    required this.updatedAt,
  }) : _foremanIds = foremanIds;

  @override
  final String id;
  @override
  final String projectId;
  @override
  final String title;
  @override
  final int orderIndex;
  @override
  final StageStatus status;
  @override
  final DateTime? plannedStart;
  @override
  final DateTime? plannedEnd;
  @override
  final DateTime? originalEnd;
  @override
  final int pauseDurationMs;
  @override
  final int workBudget;
  @override
  final int materialsBudget;
  final List<String> _foremanIds;
  @override
  @JsonKey()
  List<String> get foremanIds {
    if (_foremanIds is EqualUnmodifiableListView) return _foremanIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_foremanIds);
  }

  @override
  final int progressCache;
  @override
  final bool planApproved;
  @override
  final DateTime? startedAt;
  @override
  final DateTime? sentToReviewAt;
  @override
  final DateTime? doneAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Stage(id: $id, projectId: $projectId, title: $title, orderIndex: $orderIndex, status: $status, plannedStart: $plannedStart, plannedEnd: $plannedEnd, originalEnd: $originalEnd, pauseDurationMs: $pauseDurationMs, workBudget: $workBudget, materialsBudget: $materialsBudget, foremanIds: $foremanIds, progressCache: $progressCache, planApproved: $planApproved, startedAt: $startedAt, sentToReviewAt: $sentToReviewAt, doneAt: $doneAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.plannedStart, plannedStart) ||
                other.plannedStart == plannedStart) &&
            (identical(other.plannedEnd, plannedEnd) ||
                other.plannedEnd == plannedEnd) &&
            (identical(other.originalEnd, originalEnd) ||
                other.originalEnd == originalEnd) &&
            (identical(other.pauseDurationMs, pauseDurationMs) ||
                other.pauseDurationMs == pauseDurationMs) &&
            (identical(other.workBudget, workBudget) ||
                other.workBudget == workBudget) &&
            (identical(other.materialsBudget, materialsBudget) ||
                other.materialsBudget == materialsBudget) &&
            const DeepCollectionEquality().equals(
              other._foremanIds,
              _foremanIds,
            ) &&
            (identical(other.progressCache, progressCache) ||
                other.progressCache == progressCache) &&
            (identical(other.planApproved, planApproved) ||
                other.planApproved == planApproved) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.sentToReviewAt, sentToReviewAt) ||
                other.sentToReviewAt == sentToReviewAt) &&
            (identical(other.doneAt, doneAt) || other.doneAt == doneAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    projectId,
    title,
    orderIndex,
    status,
    plannedStart,
    plannedEnd,
    originalEnd,
    pauseDurationMs,
    workBudget,
    materialsBudget,
    const DeepCollectionEquality().hash(_foremanIds),
    progressCache,
    planApproved,
    startedAt,
    sentToReviewAt,
    doneAt,
    createdAt,
    updatedAt,
  ]);

  /// Create a copy of Stage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StageImplCopyWith<_$StageImpl> get copyWith =>
      __$$StageImplCopyWithImpl<_$StageImpl>(this, _$identity);
}

abstract class _Stage implements Stage {
  const factory _Stage({
    required final String id,
    required final String projectId,
    required final String title,
    required final int orderIndex,
    required final StageStatus status,
    final DateTime? plannedStart,
    final DateTime? plannedEnd,
    final DateTime? originalEnd,
    required final int pauseDurationMs,
    required final int workBudget,
    required final int materialsBudget,
    final List<String> foremanIds,
    required final int progressCache,
    required final bool planApproved,
    final DateTime? startedAt,
    final DateTime? sentToReviewAt,
    final DateTime? doneAt,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$StageImpl;

  @override
  String get id;
  @override
  String get projectId;
  @override
  String get title;
  @override
  int get orderIndex;
  @override
  StageStatus get status;
  @override
  DateTime? get plannedStart;
  @override
  DateTime? get plannedEnd;
  @override
  DateTime? get originalEnd;
  @override
  int get pauseDurationMs;
  @override
  int get workBudget;
  @override
  int get materialsBudget;
  @override
  List<String> get foremanIds;
  @override
  int get progressCache;
  @override
  bool get planApproved;
  @override
  DateTime? get startedAt;
  @override
  DateTime? get sentToReviewAt;
  @override
  DateTime? get doneAt;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Stage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StageImplCopyWith<_$StageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
