// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'methodology.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MethodologySection {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  List<MethodologyArticleSummary> get articles =>
      throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of MethodologySection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MethodologySectionCopyWith<MethodologySection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MethodologySectionCopyWith<$Res> {
  factory $MethodologySectionCopyWith(
    MethodologySection value,
    $Res Function(MethodologySection) then,
  ) = _$MethodologySectionCopyWithImpl<$Res, MethodologySection>;
  @useResult
  $Res call({
    String id,
    String title,
    int orderIndex,
    List<MethodologyArticleSummary> articles,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$MethodologySectionCopyWithImpl<$Res, $Val extends MethodologySection>
    implements $MethodologySectionCopyWith<$Res> {
  _$MethodologySectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MethodologySection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? orderIndex = null,
    Object? articles = null,
    Object? createdAt = null,
    Object? updatedAt = null,
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
            articles: null == articles
                ? _value.articles
                : articles // ignore: cast_nullable_to_non_nullable
                      as List<MethodologyArticleSummary>,
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
abstract class _$$MethodologySectionImplCopyWith<$Res>
    implements $MethodologySectionCopyWith<$Res> {
  factory _$$MethodologySectionImplCopyWith(
    _$MethodologySectionImpl value,
    $Res Function(_$MethodologySectionImpl) then,
  ) = __$$MethodologySectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    int orderIndex,
    List<MethodologyArticleSummary> articles,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$MethodologySectionImplCopyWithImpl<$Res>
    extends _$MethodologySectionCopyWithImpl<$Res, _$MethodologySectionImpl>
    implements _$$MethodologySectionImplCopyWith<$Res> {
  __$$MethodologySectionImplCopyWithImpl(
    _$MethodologySectionImpl _value,
    $Res Function(_$MethodologySectionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MethodologySection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? orderIndex = null,
    Object? articles = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$MethodologySectionImpl(
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
        articles: null == articles
            ? _value._articles
            : articles // ignore: cast_nullable_to_non_nullable
                  as List<MethodologyArticleSummary>,
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

class _$MethodologySectionImpl implements _MethodologySection {
  const _$MethodologySectionImpl({
    required this.id,
    required this.title,
    required this.orderIndex,
    final List<MethodologyArticleSummary> articles =
        const <MethodologyArticleSummary>[],
    required this.createdAt,
    required this.updatedAt,
  }) : _articles = articles;

  @override
  final String id;
  @override
  final String title;
  @override
  final int orderIndex;
  final List<MethodologyArticleSummary> _articles;
  @override
  @JsonKey()
  List<MethodologyArticleSummary> get articles {
    if (_articles is EqualUnmodifiableListView) return _articles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_articles);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'MethodologySection(id: $id, title: $title, orderIndex: $orderIndex, articles: $articles, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MethodologySectionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            const DeepCollectionEquality().equals(other._articles, _articles) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    orderIndex,
    const DeepCollectionEquality().hash(_articles),
    createdAt,
    updatedAt,
  );

  /// Create a copy of MethodologySection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MethodologySectionImplCopyWith<_$MethodologySectionImpl> get copyWith =>
      __$$MethodologySectionImplCopyWithImpl<_$MethodologySectionImpl>(
        this,
        _$identity,
      );
}

abstract class _MethodologySection implements MethodologySection {
  const factory _MethodologySection({
    required final String id,
    required final String title,
    required final int orderIndex,
    final List<MethodologyArticleSummary> articles,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$MethodologySectionImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  int get orderIndex;
  @override
  List<MethodologyArticleSummary> get articles;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of MethodologySection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MethodologySectionImplCopyWith<_$MethodologySectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MethodologyArticleSummary {
  String get id => throw _privateConstructorUsedError;
  String get sectionId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;

  /// Create a copy of MethodologyArticleSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MethodologyArticleSummaryCopyWith<MethodologyArticleSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MethodologyArticleSummaryCopyWith<$Res> {
  factory $MethodologyArticleSummaryCopyWith(
    MethodologyArticleSummary value,
    $Res Function(MethodologyArticleSummary) then,
  ) = _$MethodologyArticleSummaryCopyWithImpl<$Res, MethodologyArticleSummary>;
  @useResult
  $Res call({
    String id,
    String sectionId,
    String title,
    int orderIndex,
    int version,
  });
}

/// @nodoc
class _$MethodologyArticleSummaryCopyWithImpl<
  $Res,
  $Val extends MethodologyArticleSummary
>
    implements $MethodologyArticleSummaryCopyWith<$Res> {
  _$MethodologyArticleSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MethodologyArticleSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sectionId = null,
    Object? title = null,
    Object? orderIndex = null,
    Object? version = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            sectionId: null == sectionId
                ? _value.sectionId
                : sectionId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            orderIndex: null == orderIndex
                ? _value.orderIndex
                : orderIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            version: null == version
                ? _value.version
                : version // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MethodologyArticleSummaryImplCopyWith<$Res>
    implements $MethodologyArticleSummaryCopyWith<$Res> {
  factory _$$MethodologyArticleSummaryImplCopyWith(
    _$MethodologyArticleSummaryImpl value,
    $Res Function(_$MethodologyArticleSummaryImpl) then,
  ) = __$$MethodologyArticleSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String sectionId,
    String title,
    int orderIndex,
    int version,
  });
}

/// @nodoc
class __$$MethodologyArticleSummaryImplCopyWithImpl<$Res>
    extends
        _$MethodologyArticleSummaryCopyWithImpl<
          $Res,
          _$MethodologyArticleSummaryImpl
        >
    implements _$$MethodologyArticleSummaryImplCopyWith<$Res> {
  __$$MethodologyArticleSummaryImplCopyWithImpl(
    _$MethodologyArticleSummaryImpl _value,
    $Res Function(_$MethodologyArticleSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MethodologyArticleSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sectionId = null,
    Object? title = null,
    Object? orderIndex = null,
    Object? version = null,
  }) {
    return _then(
      _$MethodologyArticleSummaryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        sectionId: null == sectionId
            ? _value.sectionId
            : sectionId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        orderIndex: null == orderIndex
            ? _value.orderIndex
            : orderIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        version: null == version
            ? _value.version
            : version // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$MethodologyArticleSummaryImpl implements _MethodologyArticleSummary {
  const _$MethodologyArticleSummaryImpl({
    required this.id,
    required this.sectionId,
    required this.title,
    required this.orderIndex,
    required this.version,
  });

  @override
  final String id;
  @override
  final String sectionId;
  @override
  final String title;
  @override
  final int orderIndex;
  @override
  final int version;

  @override
  String toString() {
    return 'MethodologyArticleSummary(id: $id, sectionId: $sectionId, title: $title, orderIndex: $orderIndex, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MethodologyArticleSummaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.version, version) || other.version == version));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, sectionId, title, orderIndex, version);

  /// Create a copy of MethodologyArticleSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MethodologyArticleSummaryImplCopyWith<_$MethodologyArticleSummaryImpl>
  get copyWith =>
      __$$MethodologyArticleSummaryImplCopyWithImpl<
        _$MethodologyArticleSummaryImpl
      >(this, _$identity);
}

abstract class _MethodologyArticleSummary implements MethodologyArticleSummary {
  const factory _MethodologyArticleSummary({
    required final String id,
    required final String sectionId,
    required final String title,
    required final int orderIndex,
    required final int version,
  }) = _$MethodologyArticleSummaryImpl;

  @override
  String get id;
  @override
  String get sectionId;
  @override
  String get title;
  @override
  int get orderIndex;
  @override
  int get version;

  /// Create a copy of MethodologyArticleSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MethodologyArticleSummaryImplCopyWith<_$MethodologyArticleSummaryImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MethodologyArticle {
  String get id => throw _privateConstructorUsedError;
  String get sectionId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  String get etag => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of MethodologyArticle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MethodologyArticleCopyWith<MethodologyArticle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MethodologyArticleCopyWith<$Res> {
  factory $MethodologyArticleCopyWith(
    MethodologyArticle value,
    $Res Function(MethodologyArticle) then,
  ) = _$MethodologyArticleCopyWithImpl<$Res, MethodologyArticle>;
  @useResult
  $Res call({
    String id,
    String sectionId,
    String title,
    String body,
    int orderIndex,
    int version,
    String etag,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$MethodologyArticleCopyWithImpl<$Res, $Val extends MethodologyArticle>
    implements $MethodologyArticleCopyWith<$Res> {
  _$MethodologyArticleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MethodologyArticle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sectionId = null,
    Object? title = null,
    Object? body = null,
    Object? orderIndex = null,
    Object? version = null,
    Object? etag = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            sectionId: null == sectionId
                ? _value.sectionId
                : sectionId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String,
            orderIndex: null == orderIndex
                ? _value.orderIndex
                : orderIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            version: null == version
                ? _value.version
                : version // ignore: cast_nullable_to_non_nullable
                      as int,
            etag: null == etag
                ? _value.etag
                : etag // ignore: cast_nullable_to_non_nullable
                      as String,
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
abstract class _$$MethodologyArticleImplCopyWith<$Res>
    implements $MethodologyArticleCopyWith<$Res> {
  factory _$$MethodologyArticleImplCopyWith(
    _$MethodologyArticleImpl value,
    $Res Function(_$MethodologyArticleImpl) then,
  ) = __$$MethodologyArticleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String sectionId,
    String title,
    String body,
    int orderIndex,
    int version,
    String etag,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$MethodologyArticleImplCopyWithImpl<$Res>
    extends _$MethodologyArticleCopyWithImpl<$Res, _$MethodologyArticleImpl>
    implements _$$MethodologyArticleImplCopyWith<$Res> {
  __$$MethodologyArticleImplCopyWithImpl(
    _$MethodologyArticleImpl _value,
    $Res Function(_$MethodologyArticleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MethodologyArticle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sectionId = null,
    Object? title = null,
    Object? body = null,
    Object? orderIndex = null,
    Object? version = null,
    Object? etag = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$MethodologyArticleImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        sectionId: null == sectionId
            ? _value.sectionId
            : sectionId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
        orderIndex: null == orderIndex
            ? _value.orderIndex
            : orderIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        version: null == version
            ? _value.version
            : version // ignore: cast_nullable_to_non_nullable
                  as int,
        etag: null == etag
            ? _value.etag
            : etag // ignore: cast_nullable_to_non_nullable
                  as String,
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

class _$MethodologyArticleImpl implements _MethodologyArticle {
  const _$MethodologyArticleImpl({
    required this.id,
    required this.sectionId,
    required this.title,
    required this.body,
    required this.orderIndex,
    required this.version,
    required this.etag,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  final String id;
  @override
  final String sectionId;
  @override
  final String title;
  @override
  final String body;
  @override
  final int orderIndex;
  @override
  final int version;
  @override
  final String etag;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'MethodologyArticle(id: $id, sectionId: $sectionId, title: $title, body: $body, orderIndex: $orderIndex, version: $version, etag: $etag, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MethodologyArticleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.etag, etag) || other.etag == etag) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    sectionId,
    title,
    body,
    orderIndex,
    version,
    etag,
    createdAt,
    updatedAt,
  );

  /// Create a copy of MethodologyArticle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MethodologyArticleImplCopyWith<_$MethodologyArticleImpl> get copyWith =>
      __$$MethodologyArticleImplCopyWithImpl<_$MethodologyArticleImpl>(
        this,
        _$identity,
      );
}

abstract class _MethodologyArticle implements MethodologyArticle {
  const factory _MethodologyArticle({
    required final String id,
    required final String sectionId,
    required final String title,
    required final String body,
    required final int orderIndex,
    required final int version,
    required final String etag,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$MethodologyArticleImpl;

  @override
  String get id;
  @override
  String get sectionId;
  @override
  String get title;
  @override
  String get body;
  @override
  int get orderIndex;
  @override
  int get version;
  @override
  String get etag;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of MethodologyArticle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MethodologyArticleImplCopyWith<_$MethodologyArticleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MethodologySearchHit {
  String get id => throw _privateConstructorUsedError;
  String get sectionId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get snippet => throw _privateConstructorUsedError;
  double get rank => throw _privateConstructorUsedError;

  /// Create a copy of MethodologySearchHit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MethodologySearchHitCopyWith<MethodologySearchHit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MethodologySearchHitCopyWith<$Res> {
  factory $MethodologySearchHitCopyWith(
    MethodologySearchHit value,
    $Res Function(MethodologySearchHit) then,
  ) = _$MethodologySearchHitCopyWithImpl<$Res, MethodologySearchHit>;
  @useResult
  $Res call({
    String id,
    String sectionId,
    String title,
    String snippet,
    double rank,
  });
}

/// @nodoc
class _$MethodologySearchHitCopyWithImpl<
  $Res,
  $Val extends MethodologySearchHit
>
    implements $MethodologySearchHitCopyWith<$Res> {
  _$MethodologySearchHitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MethodologySearchHit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sectionId = null,
    Object? title = null,
    Object? snippet = null,
    Object? rank = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            sectionId: null == sectionId
                ? _value.sectionId
                : sectionId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            snippet: null == snippet
                ? _value.snippet
                : snippet // ignore: cast_nullable_to_non_nullable
                      as String,
            rank: null == rank
                ? _value.rank
                : rank // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MethodologySearchHitImplCopyWith<$Res>
    implements $MethodologySearchHitCopyWith<$Res> {
  factory _$$MethodologySearchHitImplCopyWith(
    _$MethodologySearchHitImpl value,
    $Res Function(_$MethodologySearchHitImpl) then,
  ) = __$$MethodologySearchHitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String sectionId,
    String title,
    String snippet,
    double rank,
  });
}

/// @nodoc
class __$$MethodologySearchHitImplCopyWithImpl<$Res>
    extends _$MethodologySearchHitCopyWithImpl<$Res, _$MethodologySearchHitImpl>
    implements _$$MethodologySearchHitImplCopyWith<$Res> {
  __$$MethodologySearchHitImplCopyWithImpl(
    _$MethodologySearchHitImpl _value,
    $Res Function(_$MethodologySearchHitImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MethodologySearchHit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sectionId = null,
    Object? title = null,
    Object? snippet = null,
    Object? rank = null,
  }) {
    return _then(
      _$MethodologySearchHitImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        sectionId: null == sectionId
            ? _value.sectionId
            : sectionId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        snippet: null == snippet
            ? _value.snippet
            : snippet // ignore: cast_nullable_to_non_nullable
                  as String,
        rank: null == rank
            ? _value.rank
            : rank // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$MethodologySearchHitImpl implements _MethodologySearchHit {
  const _$MethodologySearchHitImpl({
    required this.id,
    required this.sectionId,
    required this.title,
    required this.snippet,
    required this.rank,
  });

  @override
  final String id;
  @override
  final String sectionId;
  @override
  final String title;
  @override
  final String snippet;
  @override
  final double rank;

  @override
  String toString() {
    return 'MethodologySearchHit(id: $id, sectionId: $sectionId, title: $title, snippet: $snippet, rank: $rank)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MethodologySearchHitImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.snippet, snippet) || other.snippet == snippet) &&
            (identical(other.rank, rank) || other.rank == rank));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, sectionId, title, snippet, rank);

  /// Create a copy of MethodologySearchHit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MethodologySearchHitImplCopyWith<_$MethodologySearchHitImpl>
  get copyWith =>
      __$$MethodologySearchHitImplCopyWithImpl<_$MethodologySearchHitImpl>(
        this,
        _$identity,
      );
}

abstract class _MethodologySearchHit implements MethodologySearchHit {
  const factory _MethodologySearchHit({
    required final String id,
    required final String sectionId,
    required final String title,
    required final String snippet,
    required final double rank,
  }) = _$MethodologySearchHitImpl;

  @override
  String get id;
  @override
  String get sectionId;
  @override
  String get title;
  @override
  String get snippet;
  @override
  double get rank;

  /// Create a copy of MethodologySearchHit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MethodologySearchHitImplCopyWith<_$MethodologySearchHitImpl>
  get copyWith => throw _privateConstructorUsedError;
}
