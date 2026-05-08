// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'faq.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$FaqItem {
  String get id => throw _privateConstructorUsedError;
  String get question => throw _privateConstructorUsedError;
  String get answer => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;

  /// Create a copy of FaqItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FaqItemCopyWith<FaqItem> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FaqItemCopyWith<$Res> {
  factory $FaqItemCopyWith(FaqItem value, $Res Function(FaqItem) then) =
      _$FaqItemCopyWithImpl<$Res, FaqItem>;
  @useResult
  $Res call({String id, String question, String answer, int orderIndex});
}

/// @nodoc
class _$FaqItemCopyWithImpl<$Res, $Val extends FaqItem>
    implements $FaqItemCopyWith<$Res> {
  _$FaqItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FaqItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? question = null,
    Object? answer = null,
    Object? orderIndex = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            question: null == question
                ? _value.question
                : question // ignore: cast_nullable_to_non_nullable
                      as String,
            answer: null == answer
                ? _value.answer
                : answer // ignore: cast_nullable_to_non_nullable
                      as String,
            orderIndex: null == orderIndex
                ? _value.orderIndex
                : orderIndex // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FaqItemImplCopyWith<$Res> implements $FaqItemCopyWith<$Res> {
  factory _$$FaqItemImplCopyWith(
    _$FaqItemImpl value,
    $Res Function(_$FaqItemImpl) then,
  ) = __$$FaqItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String question, String answer, int orderIndex});
}

/// @nodoc
class __$$FaqItemImplCopyWithImpl<$Res>
    extends _$FaqItemCopyWithImpl<$Res, _$FaqItemImpl>
    implements _$$FaqItemImplCopyWith<$Res> {
  __$$FaqItemImplCopyWithImpl(
    _$FaqItemImpl _value,
    $Res Function(_$FaqItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FaqItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? question = null,
    Object? answer = null,
    Object? orderIndex = null,
  }) {
    return _then(
      _$FaqItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        question: null == question
            ? _value.question
            : question // ignore: cast_nullable_to_non_nullable
                  as String,
        answer: null == answer
            ? _value.answer
            : answer // ignore: cast_nullable_to_non_nullable
                  as String,
        orderIndex: null == orderIndex
            ? _value.orderIndex
            : orderIndex // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$FaqItemImpl implements _FaqItem {
  const _$FaqItemImpl({
    required this.id,
    required this.question,
    required this.answer,
    required this.orderIndex,
  });

  @override
  final String id;
  @override
  final String question;
  @override
  final String answer;
  @override
  final int orderIndex;

  @override
  String toString() {
    return 'FaqItem(id: $id, question: $question, answer: $answer, orderIndex: $orderIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FaqItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.question, question) ||
                other.question == question) &&
            (identical(other.answer, answer) || other.answer == answer) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, question, answer, orderIndex);

  /// Create a copy of FaqItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FaqItemImplCopyWith<_$FaqItemImpl> get copyWith =>
      __$$FaqItemImplCopyWithImpl<_$FaqItemImpl>(this, _$identity);
}

abstract class _FaqItem implements FaqItem {
  const factory _FaqItem({
    required final String id,
    required final String question,
    required final String answer,
    required final int orderIndex,
  }) = _$FaqItemImpl;

  @override
  String get id;
  @override
  String get question;
  @override
  String get answer;
  @override
  int get orderIndex;

  /// Create a copy of FaqItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FaqItemImplCopyWith<_$FaqItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$FaqSection {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  List<FaqItem> get items => throw _privateConstructorUsedError;

  /// Create a copy of FaqSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FaqSectionCopyWith<FaqSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FaqSectionCopyWith<$Res> {
  factory $FaqSectionCopyWith(
    FaqSection value,
    $Res Function(FaqSection) then,
  ) = _$FaqSectionCopyWithImpl<$Res, FaqSection>;
  @useResult
  $Res call({String id, String title, int orderIndex, List<FaqItem> items});
}

/// @nodoc
class _$FaqSectionCopyWithImpl<$Res, $Val extends FaqSection>
    implements $FaqSectionCopyWith<$Res> {
  _$FaqSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FaqSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? orderIndex = null,
    Object? items = null,
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
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<FaqItem>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FaqSectionImplCopyWith<$Res>
    implements $FaqSectionCopyWith<$Res> {
  factory _$$FaqSectionImplCopyWith(
    _$FaqSectionImpl value,
    $Res Function(_$FaqSectionImpl) then,
  ) = __$$FaqSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String title, int orderIndex, List<FaqItem> items});
}

/// @nodoc
class __$$FaqSectionImplCopyWithImpl<$Res>
    extends _$FaqSectionCopyWithImpl<$Res, _$FaqSectionImpl>
    implements _$$FaqSectionImplCopyWith<$Res> {
  __$$FaqSectionImplCopyWithImpl(
    _$FaqSectionImpl _value,
    $Res Function(_$FaqSectionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FaqSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? orderIndex = null,
    Object? items = null,
  }) {
    return _then(
      _$FaqSectionImpl(
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
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<FaqItem>,
      ),
    );
  }
}

/// @nodoc

class _$FaqSectionImpl implements _FaqSection {
  const _$FaqSectionImpl({
    required this.id,
    required this.title,
    required this.orderIndex,
    final List<FaqItem> items = const <FaqItem>[],
  }) : _items = items;

  @override
  final String id;
  @override
  final String title;
  @override
  final int orderIndex;
  final List<FaqItem> _items;
  @override
  @JsonKey()
  List<FaqItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'FaqSection(id: $id, title: $title, orderIndex: $orderIndex, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FaqSectionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    orderIndex,
    const DeepCollectionEquality().hash(_items),
  );

  /// Create a copy of FaqSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FaqSectionImplCopyWith<_$FaqSectionImpl> get copyWith =>
      __$$FaqSectionImplCopyWithImpl<_$FaqSectionImpl>(this, _$identity);
}

abstract class _FaqSection implements FaqSection {
  const factory _FaqSection({
    required final String id,
    required final String title,
    required final int orderIndex,
    final List<FaqItem> items,
  }) = _$FaqSectionImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  int get orderIndex;
  @override
  List<FaqItem> get items;

  /// Create a copy of FaqSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FaqSectionImplCopyWith<_$FaqSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
