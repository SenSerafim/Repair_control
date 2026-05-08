// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BudgetBucket {
  int get planned => throw _privateConstructorUsedError;
  int get spent => throw _privateConstructorUsedError;
  int get remaining => throw _privateConstructorUsedError;

  /// Create a copy of BudgetBucket
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BudgetBucketCopyWith<BudgetBucket> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetBucketCopyWith<$Res> {
  factory $BudgetBucketCopyWith(
    BudgetBucket value,
    $Res Function(BudgetBucket) then,
  ) = _$BudgetBucketCopyWithImpl<$Res, BudgetBucket>;
  @useResult
  $Res call({int planned, int spent, int remaining});
}

/// @nodoc
class _$BudgetBucketCopyWithImpl<$Res, $Val extends BudgetBucket>
    implements $BudgetBucketCopyWith<$Res> {
  _$BudgetBucketCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BudgetBucket
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? planned = null,
    Object? spent = null,
    Object? remaining = null,
  }) {
    return _then(
      _value.copyWith(
            planned: null == planned
                ? _value.planned
                : planned // ignore: cast_nullable_to_non_nullable
                      as int,
            spent: null == spent
                ? _value.spent
                : spent // ignore: cast_nullable_to_non_nullable
                      as int,
            remaining: null == remaining
                ? _value.remaining
                : remaining // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BudgetBucketImplCopyWith<$Res>
    implements $BudgetBucketCopyWith<$Res> {
  factory _$$BudgetBucketImplCopyWith(
    _$BudgetBucketImpl value,
    $Res Function(_$BudgetBucketImpl) then,
  ) = __$$BudgetBucketImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int planned, int spent, int remaining});
}

/// @nodoc
class __$$BudgetBucketImplCopyWithImpl<$Res>
    extends _$BudgetBucketCopyWithImpl<$Res, _$BudgetBucketImpl>
    implements _$$BudgetBucketImplCopyWith<$Res> {
  __$$BudgetBucketImplCopyWithImpl(
    _$BudgetBucketImpl _value,
    $Res Function(_$BudgetBucketImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BudgetBucket
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? planned = null,
    Object? spent = null,
    Object? remaining = null,
  }) {
    return _then(
      _$BudgetBucketImpl(
        planned: null == planned
            ? _value.planned
            : planned // ignore: cast_nullable_to_non_nullable
                  as int,
        spent: null == spent
            ? _value.spent
            : spent // ignore: cast_nullable_to_non_nullable
                  as int,
        remaining: null == remaining
            ? _value.remaining
            : remaining // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$BudgetBucketImpl implements _BudgetBucket {
  const _$BudgetBucketImpl({
    required this.planned,
    required this.spent,
    required this.remaining,
  });

  @override
  final int planned;
  @override
  final int spent;
  @override
  final int remaining;

  @override
  String toString() {
    return 'BudgetBucket(planned: $planned, spent: $spent, remaining: $remaining)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetBucketImpl &&
            (identical(other.planned, planned) || other.planned == planned) &&
            (identical(other.spent, spent) || other.spent == spent) &&
            (identical(other.remaining, remaining) ||
                other.remaining == remaining));
  }

  @override
  int get hashCode => Object.hash(runtimeType, planned, spent, remaining);

  /// Create a copy of BudgetBucket
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetBucketImplCopyWith<_$BudgetBucketImpl> get copyWith =>
      __$$BudgetBucketImplCopyWithImpl<_$BudgetBucketImpl>(this, _$identity);
}

abstract class _BudgetBucket implements BudgetBucket {
  const factory _BudgetBucket({
    required final int planned,
    required final int spent,
    required final int remaining,
  }) = _$BudgetBucketImpl;

  @override
  int get planned;
  @override
  int get spent;
  @override
  int get remaining;

  /// Create a copy of BudgetBucket
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BudgetBucketImplCopyWith<_$BudgetBucketImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$StageBudget {
  String get stageId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  BudgetBucket get work => throw _privateConstructorUsedError;
  BudgetBucket get materials => throw _privateConstructorUsedError;
  BudgetBucket get total => throw _privateConstructorUsedError;

  /// Create a copy of StageBudget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StageBudgetCopyWith<StageBudget> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StageBudgetCopyWith<$Res> {
  factory $StageBudgetCopyWith(
    StageBudget value,
    $Res Function(StageBudget) then,
  ) = _$StageBudgetCopyWithImpl<$Res, StageBudget>;
  @useResult
  $Res call({
    String stageId,
    String title,
    BudgetBucket work,
    BudgetBucket materials,
    BudgetBucket total,
  });

  $BudgetBucketCopyWith<$Res> get work;
  $BudgetBucketCopyWith<$Res> get materials;
  $BudgetBucketCopyWith<$Res> get total;
}

/// @nodoc
class _$StageBudgetCopyWithImpl<$Res, $Val extends StageBudget>
    implements $StageBudgetCopyWith<$Res> {
  _$StageBudgetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StageBudget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stageId = null,
    Object? title = null,
    Object? work = null,
    Object? materials = null,
    Object? total = null,
  }) {
    return _then(
      _value.copyWith(
            stageId: null == stageId
                ? _value.stageId
                : stageId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            work: null == work
                ? _value.work
                : work // ignore: cast_nullable_to_non_nullable
                      as BudgetBucket,
            materials: null == materials
                ? _value.materials
                : materials // ignore: cast_nullable_to_non_nullable
                      as BudgetBucket,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as BudgetBucket,
          )
          as $Val,
    );
  }

  /// Create a copy of StageBudget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BudgetBucketCopyWith<$Res> get work {
    return $BudgetBucketCopyWith<$Res>(_value.work, (value) {
      return _then(_value.copyWith(work: value) as $Val);
    });
  }

  /// Create a copy of StageBudget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BudgetBucketCopyWith<$Res> get materials {
    return $BudgetBucketCopyWith<$Res>(_value.materials, (value) {
      return _then(_value.copyWith(materials: value) as $Val);
    });
  }

  /// Create a copy of StageBudget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BudgetBucketCopyWith<$Res> get total {
    return $BudgetBucketCopyWith<$Res>(_value.total, (value) {
      return _then(_value.copyWith(total: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$StageBudgetImplCopyWith<$Res>
    implements $StageBudgetCopyWith<$Res> {
  factory _$$StageBudgetImplCopyWith(
    _$StageBudgetImpl value,
    $Res Function(_$StageBudgetImpl) then,
  ) = __$$StageBudgetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String stageId,
    String title,
    BudgetBucket work,
    BudgetBucket materials,
    BudgetBucket total,
  });

  @override
  $BudgetBucketCopyWith<$Res> get work;
  @override
  $BudgetBucketCopyWith<$Res> get materials;
  @override
  $BudgetBucketCopyWith<$Res> get total;
}

/// @nodoc
class __$$StageBudgetImplCopyWithImpl<$Res>
    extends _$StageBudgetCopyWithImpl<$Res, _$StageBudgetImpl>
    implements _$$StageBudgetImplCopyWith<$Res> {
  __$$StageBudgetImplCopyWithImpl(
    _$StageBudgetImpl _value,
    $Res Function(_$StageBudgetImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StageBudget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stageId = null,
    Object? title = null,
    Object? work = null,
    Object? materials = null,
    Object? total = null,
  }) {
    return _then(
      _$StageBudgetImpl(
        stageId: null == stageId
            ? _value.stageId
            : stageId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        work: null == work
            ? _value.work
            : work // ignore: cast_nullable_to_non_nullable
                  as BudgetBucket,
        materials: null == materials
            ? _value.materials
            : materials // ignore: cast_nullable_to_non_nullable
                  as BudgetBucket,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as BudgetBucket,
      ),
    );
  }
}

/// @nodoc

class _$StageBudgetImpl implements _StageBudget {
  const _$StageBudgetImpl({
    required this.stageId,
    required this.title,
    required this.work,
    required this.materials,
    required this.total,
  });

  @override
  final String stageId;
  @override
  final String title;
  @override
  final BudgetBucket work;
  @override
  final BudgetBucket materials;
  @override
  final BudgetBucket total;

  @override
  String toString() {
    return 'StageBudget(stageId: $stageId, title: $title, work: $work, materials: $materials, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageBudgetImpl &&
            (identical(other.stageId, stageId) || other.stageId == stageId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.work, work) || other.work == work) &&
            (identical(other.materials, materials) ||
                other.materials == materials) &&
            (identical(other.total, total) || other.total == total));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, stageId, title, work, materials, total);

  /// Create a copy of StageBudget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StageBudgetImplCopyWith<_$StageBudgetImpl> get copyWith =>
      __$$StageBudgetImplCopyWithImpl<_$StageBudgetImpl>(this, _$identity);
}

abstract class _StageBudget implements StageBudget {
  const factory _StageBudget({
    required final String stageId,
    required final String title,
    required final BudgetBucket work,
    required final BudgetBucket materials,
    required final BudgetBucket total,
  }) = _$StageBudgetImpl;

  @override
  String get stageId;
  @override
  String get title;
  @override
  BudgetBucket get work;
  @override
  BudgetBucket get materials;
  @override
  BudgetBucket get total;

  /// Create a copy of StageBudget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StageBudgetImplCopyWith<_$StageBudgetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ProjectBudget {
  BudgetBucket get work => throw _privateConstructorUsedError;
  BudgetBucket get materials => throw _privateConstructorUsedError;
  BudgetBucket get total => throw _privateConstructorUsedError;
  List<StageBudget> get stages => throw _privateConstructorUsedError;

  /// Create a copy of ProjectBudget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectBudgetCopyWith<ProjectBudget> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectBudgetCopyWith<$Res> {
  factory $ProjectBudgetCopyWith(
    ProjectBudget value,
    $Res Function(ProjectBudget) then,
  ) = _$ProjectBudgetCopyWithImpl<$Res, ProjectBudget>;
  @useResult
  $Res call({
    BudgetBucket work,
    BudgetBucket materials,
    BudgetBucket total,
    List<StageBudget> stages,
  });

  $BudgetBucketCopyWith<$Res> get work;
  $BudgetBucketCopyWith<$Res> get materials;
  $BudgetBucketCopyWith<$Res> get total;
}

/// @nodoc
class _$ProjectBudgetCopyWithImpl<$Res, $Val extends ProjectBudget>
    implements $ProjectBudgetCopyWith<$Res> {
  _$ProjectBudgetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectBudget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? work = null,
    Object? materials = null,
    Object? total = null,
    Object? stages = null,
  }) {
    return _then(
      _value.copyWith(
            work: null == work
                ? _value.work
                : work // ignore: cast_nullable_to_non_nullable
                      as BudgetBucket,
            materials: null == materials
                ? _value.materials
                : materials // ignore: cast_nullable_to_non_nullable
                      as BudgetBucket,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as BudgetBucket,
            stages: null == stages
                ? _value.stages
                : stages // ignore: cast_nullable_to_non_nullable
                      as List<StageBudget>,
          )
          as $Val,
    );
  }

  /// Create a copy of ProjectBudget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BudgetBucketCopyWith<$Res> get work {
    return $BudgetBucketCopyWith<$Res>(_value.work, (value) {
      return _then(_value.copyWith(work: value) as $Val);
    });
  }

  /// Create a copy of ProjectBudget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BudgetBucketCopyWith<$Res> get materials {
    return $BudgetBucketCopyWith<$Res>(_value.materials, (value) {
      return _then(_value.copyWith(materials: value) as $Val);
    });
  }

  /// Create a copy of ProjectBudget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BudgetBucketCopyWith<$Res> get total {
    return $BudgetBucketCopyWith<$Res>(_value.total, (value) {
      return _then(_value.copyWith(total: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectBudgetImplCopyWith<$Res>
    implements $ProjectBudgetCopyWith<$Res> {
  factory _$$ProjectBudgetImplCopyWith(
    _$ProjectBudgetImpl value,
    $Res Function(_$ProjectBudgetImpl) then,
  ) = __$$ProjectBudgetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    BudgetBucket work,
    BudgetBucket materials,
    BudgetBucket total,
    List<StageBudget> stages,
  });

  @override
  $BudgetBucketCopyWith<$Res> get work;
  @override
  $BudgetBucketCopyWith<$Res> get materials;
  @override
  $BudgetBucketCopyWith<$Res> get total;
}

/// @nodoc
class __$$ProjectBudgetImplCopyWithImpl<$Res>
    extends _$ProjectBudgetCopyWithImpl<$Res, _$ProjectBudgetImpl>
    implements _$$ProjectBudgetImplCopyWith<$Res> {
  __$$ProjectBudgetImplCopyWithImpl(
    _$ProjectBudgetImpl _value,
    $Res Function(_$ProjectBudgetImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProjectBudget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? work = null,
    Object? materials = null,
    Object? total = null,
    Object? stages = null,
  }) {
    return _then(
      _$ProjectBudgetImpl(
        work: null == work
            ? _value.work
            : work // ignore: cast_nullable_to_non_nullable
                  as BudgetBucket,
        materials: null == materials
            ? _value.materials
            : materials // ignore: cast_nullable_to_non_nullable
                  as BudgetBucket,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as BudgetBucket,
        stages: null == stages
            ? _value._stages
            : stages // ignore: cast_nullable_to_non_nullable
                  as List<StageBudget>,
      ),
    );
  }
}

/// @nodoc

class _$ProjectBudgetImpl implements _ProjectBudget {
  const _$ProjectBudgetImpl({
    required this.work,
    required this.materials,
    required this.total,
    final List<StageBudget> stages = const <StageBudget>[],
  }) : _stages = stages;

  @override
  final BudgetBucket work;
  @override
  final BudgetBucket materials;
  @override
  final BudgetBucket total;
  final List<StageBudget> _stages;
  @override
  @JsonKey()
  List<StageBudget> get stages {
    if (_stages is EqualUnmodifiableListView) return _stages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stages);
  }

  @override
  String toString() {
    return 'ProjectBudget(work: $work, materials: $materials, total: $total, stages: $stages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectBudgetImpl &&
            (identical(other.work, work) || other.work == work) &&
            (identical(other.materials, materials) ||
                other.materials == materials) &&
            (identical(other.total, total) || other.total == total) &&
            const DeepCollectionEquality().equals(other._stages, _stages));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    work,
    materials,
    total,
    const DeepCollectionEquality().hash(_stages),
  );

  /// Create a copy of ProjectBudget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectBudgetImplCopyWith<_$ProjectBudgetImpl> get copyWith =>
      __$$ProjectBudgetImplCopyWithImpl<_$ProjectBudgetImpl>(this, _$identity);
}

abstract class _ProjectBudget implements ProjectBudget {
  const factory _ProjectBudget({
    required final BudgetBucket work,
    required final BudgetBucket materials,
    required final BudgetBucket total,
    final List<StageBudget> stages,
  }) = _$ProjectBudgetImpl;

  @override
  BudgetBucket get work;
  @override
  BudgetBucket get materials;
  @override
  BudgetBucket get total;
  @override
  List<StageBudget> get stages;

  /// Create a copy of ProjectBudget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectBudgetImplCopyWith<_$ProjectBudgetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
