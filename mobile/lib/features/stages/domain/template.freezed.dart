// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TemplateStep {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  int? get price => throw _privateConstructorUsedError;

  /// Create a copy of TemplateStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TemplateStepCopyWith<TemplateStep> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TemplateStepCopyWith<$Res> {
  factory $TemplateStepCopyWith(
    TemplateStep value,
    $Res Function(TemplateStep) then,
  ) = _$TemplateStepCopyWithImpl<$Res, TemplateStep>;
  @useResult
  $Res call({String id, String title, int orderIndex, int? price});
}

/// @nodoc
class _$TemplateStepCopyWithImpl<$Res, $Val extends TemplateStep>
    implements $TemplateStepCopyWith<$Res> {
  _$TemplateStepCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TemplateStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? orderIndex = null,
    Object? price = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            orderIndex: null == orderIndex
                ? _value.orderIndex
                : orderIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            price: freezed == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TemplateStepImplCopyWith<$Res>
    implements $TemplateStepCopyWith<$Res> {
  factory _$$TemplateStepImplCopyWith(
    _$TemplateStepImpl value,
    $Res Function(_$TemplateStepImpl) then,
  ) = __$$TemplateStepImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String title, int orderIndex, int? price});
}

/// @nodoc
class __$$TemplateStepImplCopyWithImpl<$Res>
    extends _$TemplateStepCopyWithImpl<$Res, _$TemplateStepImpl>
    implements _$$TemplateStepImplCopyWith<$Res> {
  __$$TemplateStepImplCopyWithImpl(
    _$TemplateStepImpl _value,
    $Res Function(_$TemplateStepImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TemplateStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? orderIndex = null,
    Object? price = freezed,
  }) {
    return _then(
      _$TemplateStepImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        orderIndex: null == orderIndex
            ? _value.orderIndex
            : orderIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        price: freezed == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$TemplateStepImpl implements _TemplateStep {
  const _$TemplateStepImpl({
    required this.id,
    required this.title,
    required this.orderIndex,
    this.price,
  });

  @override
  final String id;
  @override
  final String title;
  @override
  final int orderIndex;
  @override
  final int? price;

  @override
  String toString() {
    return 'TemplateStep(id: $id, title: $title, orderIndex: $orderIndex, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TemplateStepImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.price, price) || other.price == price));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, title, orderIndex, price);

  /// Create a copy of TemplateStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TemplateStepImplCopyWith<_$TemplateStepImpl> get copyWith =>
      __$$TemplateStepImplCopyWithImpl<_$TemplateStepImpl>(this, _$identity);
}

abstract class _TemplateStep implements TemplateStep {
  const factory _TemplateStep({
    required final String id,
    required final String title,
    required final int orderIndex,
    final int? price,
  }) = _$TemplateStepImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  int get orderIndex;
  @override
  int? get price;

  /// Create a copy of TemplateStep
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TemplateStepImplCopyWith<_$TemplateStepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$StageTemplate {
  String get id => throw _privateConstructorUsedError;
  TemplateKind get kind => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get authorId => throw _privateConstructorUsedError;
  List<TemplateStep> get steps => throw _privateConstructorUsedError;

  /// Create a copy of StageTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StageTemplateCopyWith<StageTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StageTemplateCopyWith<$Res> {
  factory $StageTemplateCopyWith(
    StageTemplate value,
    $Res Function(StageTemplate) then,
  ) = _$StageTemplateCopyWithImpl<$Res, StageTemplate>;
  @useResult
  $Res call({
    String id,
    TemplateKind kind,
    String title,
    String? description,
    String? authorId,
    List<TemplateStep> steps,
  });
}

/// @nodoc
class _$StageTemplateCopyWithImpl<$Res, $Val extends StageTemplate>
    implements $StageTemplateCopyWith<$Res> {
  _$StageTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StageTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? title = null,
    Object? description = freezed,
    Object? authorId = freezed,
    Object? steps = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as TemplateKind,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            authorId: freezed == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String?,
            steps: null == steps
                ? _value.steps
                : steps // ignore: cast_nullable_to_non_nullable
                      as List<TemplateStep>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StageTemplateImplCopyWith<$Res>
    implements $StageTemplateCopyWith<$Res> {
  factory _$$StageTemplateImplCopyWith(
    _$StageTemplateImpl value,
    $Res Function(_$StageTemplateImpl) then,
  ) = __$$StageTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    TemplateKind kind,
    String title,
    String? description,
    String? authorId,
    List<TemplateStep> steps,
  });
}

/// @nodoc
class __$$StageTemplateImplCopyWithImpl<$Res>
    extends _$StageTemplateCopyWithImpl<$Res, _$StageTemplateImpl>
    implements _$$StageTemplateImplCopyWith<$Res> {
  __$$StageTemplateImplCopyWithImpl(
    _$StageTemplateImpl _value,
    $Res Function(_$StageTemplateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StageTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? title = null,
    Object? description = freezed,
    Object? authorId = freezed,
    Object? steps = null,
  }) {
    return _then(
      _$StageTemplateImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as TemplateKind,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        authorId: freezed == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String?,
        steps: null == steps
            ? _value._steps
            : steps // ignore: cast_nullable_to_non_nullable
                  as List<TemplateStep>,
      ),
    );
  }
}

/// @nodoc

class _$StageTemplateImpl implements _StageTemplate {
  const _$StageTemplateImpl({
    required this.id,
    required this.kind,
    required this.title,
    this.description,
    this.authorId,
    final List<TemplateStep> steps = const <TemplateStep>[],
  }) : _steps = steps;

  @override
  final String id;
  @override
  final TemplateKind kind;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String? authorId;
  final List<TemplateStep> _steps;
  @override
  @JsonKey()
  List<TemplateStep> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

  @override
  String toString() {
    return 'StageTemplate(id: $id, kind: $kind, title: $title, description: $description, authorId: $authorId, steps: $steps)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            const DeepCollectionEquality().equals(other._steps, _steps));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    kind,
    title,
    description,
    authorId,
    const DeepCollectionEquality().hash(_steps),
  );

  /// Create a copy of StageTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StageTemplateImplCopyWith<_$StageTemplateImpl> get copyWith =>
      __$$StageTemplateImplCopyWithImpl<_$StageTemplateImpl>(this, _$identity);
}

abstract class _StageTemplate implements StageTemplate {
  const factory _StageTemplate({
    required final String id,
    required final TemplateKind kind,
    required final String title,
    final String? description,
    final String? authorId,
    final List<TemplateStep> steps,
  }) = _$StageTemplateImpl;

  @override
  String get id;
  @override
  TemplateKind get kind;
  @override
  String get title;
  @override
  String? get description;
  @override
  String? get authorId;
  @override
  List<TemplateStep> get steps;

  /// Create a copy of StageTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StageTemplateImplCopyWith<_$StageTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
