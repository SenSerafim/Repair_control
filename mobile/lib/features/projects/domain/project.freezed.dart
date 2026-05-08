// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Project {
  String get id => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  DateTime? get plannedStart => throw _privateConstructorUsedError;
  DateTime? get plannedEnd => throw _privateConstructorUsedError;
  ProjectStatus get status => throw _privateConstructorUsedError;
  int get workBudget => throw _privateConstructorUsedError;
  int get materialsBudget => throw _privateConstructorUsedError;
  int get progressCache => throw _privateConstructorUsedError;
  Semaphore get semaphore => throw _privateConstructorUsedError;
  bool get planApproved => throw _privateConstructorUsedError;
  bool get requiresPlanApproval => throw _privateConstructorUsedError;
  DateTime? get archivedAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectCopyWith<Project> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectCopyWith<$Res> {
  factory $ProjectCopyWith(Project value, $Res Function(Project) then) =
      _$ProjectCopyWithImpl<$Res, Project>;
  @useResult
  $Res call({
    String id,
    String ownerId,
    String title,
    String? address,
    String? description,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    ProjectStatus status,
    int workBudget,
    int materialsBudget,
    int progressCache,
    Semaphore semaphore,
    bool planApproved,
    bool requiresPlanApproval,
    DateTime? archivedAt,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$ProjectCopyWithImpl<$Res, $Val extends Project>
    implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? title = null,
    Object? address = freezed,
    Object? description = freezed,
    Object? plannedStart = freezed,
    Object? plannedEnd = freezed,
    Object? status = null,
    Object? workBudget = null,
    Object? materialsBudget = null,
    Object? progressCache = null,
    Object? semaphore = null,
    Object? planApproved = null,
    Object? requiresPlanApproval = null,
    Object? archivedAt = freezed,
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
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            plannedStart: freezed == plannedStart
                ? _value.plannedStart
                : plannedStart // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            plannedEnd: freezed == plannedEnd
                ? _value.plannedEnd
                : plannedEnd // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ProjectStatus,
            workBudget: null == workBudget
                ? _value.workBudget
                : workBudget // ignore: cast_nullable_to_non_nullable
                      as int,
            materialsBudget: null == materialsBudget
                ? _value.materialsBudget
                : materialsBudget // ignore: cast_nullable_to_non_nullable
                      as int,
            progressCache: null == progressCache
                ? _value.progressCache
                : progressCache // ignore: cast_nullable_to_non_nullable
                      as int,
            semaphore: null == semaphore
                ? _value.semaphore
                : semaphore // ignore: cast_nullable_to_non_nullable
                      as Semaphore,
            planApproved: null == planApproved
                ? _value.planApproved
                : planApproved // ignore: cast_nullable_to_non_nullable
                      as bool,
            requiresPlanApproval: null == requiresPlanApproval
                ? _value.requiresPlanApproval
                : requiresPlanApproval // ignore: cast_nullable_to_non_nullable
                      as bool,
            archivedAt: freezed == archivedAt
                ? _value.archivedAt
                : archivedAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ProjectImplCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$$ProjectImplCopyWith(
    _$ProjectImpl value,
    $Res Function(_$ProjectImpl) then,
  ) = __$$ProjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String ownerId,
    String title,
    String? address,
    String? description,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    ProjectStatus status,
    int workBudget,
    int materialsBudget,
    int progressCache,
    Semaphore semaphore,
    bool planApproved,
    bool requiresPlanApproval,
    DateTime? archivedAt,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$ProjectImplCopyWithImpl<$Res>
    extends _$ProjectCopyWithImpl<$Res, _$ProjectImpl>
    implements _$$ProjectImplCopyWith<$Res> {
  __$$ProjectImplCopyWithImpl(
    _$ProjectImpl _value,
    $Res Function(_$ProjectImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? title = null,
    Object? address = freezed,
    Object? description = freezed,
    Object? plannedStart = freezed,
    Object? plannedEnd = freezed,
    Object? status = null,
    Object? workBudget = null,
    Object? materialsBudget = null,
    Object? progressCache = null,
    Object? semaphore = null,
    Object? planApproved = null,
    Object? requiresPlanApproval = null,
    Object? archivedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$ProjectImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerId: null == ownerId
            ? _value.ownerId
            : ownerId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        plannedStart: freezed == plannedStart
            ? _value.plannedStart
            : plannedStart // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        plannedEnd: freezed == plannedEnd
            ? _value.plannedEnd
            : plannedEnd // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ProjectStatus,
        workBudget: null == workBudget
            ? _value.workBudget
            : workBudget // ignore: cast_nullable_to_non_nullable
                  as int,
        materialsBudget: null == materialsBudget
            ? _value.materialsBudget
            : materialsBudget // ignore: cast_nullable_to_non_nullable
                  as int,
        progressCache: null == progressCache
            ? _value.progressCache
            : progressCache // ignore: cast_nullable_to_non_nullable
                  as int,
        semaphore: null == semaphore
            ? _value.semaphore
            : semaphore // ignore: cast_nullable_to_non_nullable
                  as Semaphore,
        planApproved: null == planApproved
            ? _value.planApproved
            : planApproved // ignore: cast_nullable_to_non_nullable
                  as bool,
        requiresPlanApproval: null == requiresPlanApproval
            ? _value.requiresPlanApproval
            : requiresPlanApproval // ignore: cast_nullable_to_non_nullable
                  as bool,
        archivedAt: freezed == archivedAt
            ? _value.archivedAt
            : archivedAt // ignore: cast_nullable_to_non_nullable
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

class _$ProjectImpl implements _Project {
  const _$ProjectImpl({
    required this.id,
    required this.ownerId,
    required this.title,
    this.address,
    this.description,
    this.plannedStart,
    this.plannedEnd,
    required this.status,
    required this.workBudget,
    required this.materialsBudget,
    required this.progressCache,
    required this.semaphore,
    required this.planApproved,
    required this.requiresPlanApproval,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  final String id;
  @override
  final String ownerId;
  @override
  final String title;
  @override
  final String? address;
  @override
  final String? description;
  @override
  final DateTime? plannedStart;
  @override
  final DateTime? plannedEnd;
  @override
  final ProjectStatus status;
  @override
  final int workBudget;
  @override
  final int materialsBudget;
  @override
  final int progressCache;
  @override
  final Semaphore semaphore;
  @override
  final bool planApproved;
  @override
  final bool requiresPlanApproval;
  @override
  final DateTime? archivedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Project(id: $id, ownerId: $ownerId, title: $title, address: $address, description: $description, plannedStart: $plannedStart, plannedEnd: $plannedEnd, status: $status, workBudget: $workBudget, materialsBudget: $materialsBudget, progressCache: $progressCache, semaphore: $semaphore, planApproved: $planApproved, requiresPlanApproval: $requiresPlanApproval, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.plannedStart, plannedStart) ||
                other.plannedStart == plannedStart) &&
            (identical(other.plannedEnd, plannedEnd) ||
                other.plannedEnd == plannedEnd) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.workBudget, workBudget) ||
                other.workBudget == workBudget) &&
            (identical(other.materialsBudget, materialsBudget) ||
                other.materialsBudget == materialsBudget) &&
            (identical(other.progressCache, progressCache) ||
                other.progressCache == progressCache) &&
            (identical(other.semaphore, semaphore) ||
                other.semaphore == semaphore) &&
            (identical(other.planApproved, planApproved) ||
                other.planApproved == planApproved) &&
            (identical(other.requiresPlanApproval, requiresPlanApproval) ||
                other.requiresPlanApproval == requiresPlanApproval) &&
            (identical(other.archivedAt, archivedAt) ||
                other.archivedAt == archivedAt) &&
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
    title,
    address,
    description,
    plannedStart,
    plannedEnd,
    status,
    workBudget,
    materialsBudget,
    progressCache,
    semaphore,
    planApproved,
    requiresPlanApproval,
    archivedAt,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      __$$ProjectImplCopyWithImpl<_$ProjectImpl>(this, _$identity);
}

abstract class _Project implements Project {
  const factory _Project({
    required final String id,
    required final String ownerId,
    required final String title,
    final String? address,
    final String? description,
    final DateTime? plannedStart,
    final DateTime? plannedEnd,
    required final ProjectStatus status,
    required final int workBudget,
    required final int materialsBudget,
    required final int progressCache,
    required final Semaphore semaphore,
    required final bool planApproved,
    required final bool requiresPlanApproval,
    final DateTime? archivedAt,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$ProjectImpl;

  @override
  String get id;
  @override
  String get ownerId;
  @override
  String get title;
  @override
  String? get address;
  @override
  String? get description;
  @override
  DateTime? get plannedStart;
  @override
  DateTime? get plannedEnd;
  @override
  ProjectStatus get status;
  @override
  int get workBudget;
  @override
  int get materialsBudget;
  @override
  int get progressCache;
  @override
  Semaphore get semaphore;
  @override
  bool get planApproved;
  @override
  bool get requiresPlanApproval;
  @override
  DateTime? get archivedAt;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
