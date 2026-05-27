// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Document {
  String get id => throw _privateConstructorUsedError;
  String get projectId => throw _privateConstructorUsedError;
  String? get stageId => throw _privateConstructorUsedError;
  String? get stepId => throw _privateConstructorUsedError;
  DocumentCategory get category => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  DateTime? get documentDate => throw _privateConstructorUsedError;
  String get fileKey => throw _privateConstructorUsedError;
  String? get thumbKey => throw _privateConstructorUsedError;
  String get mimeType => throw _privateConstructorUsedError;
  int get sizeBytes => throw _privateConstructorUsedError;
  String get uploadedBy => throw _privateConstructorUsedError;
  bool get confirmed => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get url => throw _privateConstructorUsedError;
  String? get thumbUrl => throw _privateConstructorUsedError;

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DocumentCopyWith<Document> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocumentCopyWith<$Res> {
  factory $DocumentCopyWith(Document value, $Res Function(Document) then) =
      _$DocumentCopyWithImpl<$Res, Document>;
  @useResult
  $Res call({
    String id,
    String projectId,
    String? stageId,
    String? stepId,
    DocumentCategory category,
    String title,
    String? description,
    DateTime? documentDate,
    String fileKey,
    String? thumbKey,
    String mimeType,
    int sizeBytes,
    String uploadedBy,
    bool confirmed,
    DateTime createdAt,
    DateTime updatedAt,
    String? url,
    String? thumbUrl,
  });
}

/// @nodoc
class _$DocumentCopyWithImpl<$Res, $Val extends Document>
    implements $DocumentCopyWith<$Res> {
  _$DocumentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? stageId = freezed,
    Object? stepId = freezed,
    Object? category = null,
    Object? title = null,
    Object? description = freezed,
    Object? documentDate = freezed,
    Object? fileKey = null,
    Object? thumbKey = freezed,
    Object? mimeType = null,
    Object? sizeBytes = null,
    Object? uploadedBy = null,
    Object? confirmed = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? url = freezed,
    Object? thumbUrl = freezed,
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
            stepId: freezed == stepId
                ? _value.stepId
                : stepId // ignore: cast_nullable_to_non_nullable
                      as String?,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as DocumentCategory,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            documentDate: freezed == documentDate
                ? _value.documentDate
                : documentDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            fileKey: null == fileKey
                ? _value.fileKey
                : fileKey // ignore: cast_nullable_to_non_nullable
                      as String,
            thumbKey: freezed == thumbKey
                ? _value.thumbKey
                : thumbKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            mimeType: null == mimeType
                ? _value.mimeType
                : mimeType // ignore: cast_nullable_to_non_nullable
                      as String,
            sizeBytes: null == sizeBytes
                ? _value.sizeBytes
                : sizeBytes // ignore: cast_nullable_to_non_nullable
                      as int,
            uploadedBy: null == uploadedBy
                ? _value.uploadedBy
                : uploadedBy // ignore: cast_nullable_to_non_nullable
                      as String,
            confirmed: null == confirmed
                ? _value.confirmed
                : confirmed // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            url: freezed == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String?,
            thumbUrl: freezed == thumbUrl
                ? _value.thumbUrl
                : thumbUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DocumentImplCopyWith<$Res>
    implements $DocumentCopyWith<$Res> {
  factory _$$DocumentImplCopyWith(
    _$DocumentImpl value,
    $Res Function(_$DocumentImpl) then,
  ) = __$$DocumentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String projectId,
    String? stageId,
    String? stepId,
    DocumentCategory category,
    String title,
    String? description,
    DateTime? documentDate,
    String fileKey,
    String? thumbKey,
    String mimeType,
    int sizeBytes,
    String uploadedBy,
    bool confirmed,
    DateTime createdAt,
    DateTime updatedAt,
    String? url,
    String? thumbUrl,
  });
}

/// @nodoc
class __$$DocumentImplCopyWithImpl<$Res>
    extends _$DocumentCopyWithImpl<$Res, _$DocumentImpl>
    implements _$$DocumentImplCopyWith<$Res> {
  __$$DocumentImplCopyWithImpl(
    _$DocumentImpl _value,
    $Res Function(_$DocumentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? stageId = freezed,
    Object? stepId = freezed,
    Object? category = null,
    Object? title = null,
    Object? description = freezed,
    Object? documentDate = freezed,
    Object? fileKey = null,
    Object? thumbKey = freezed,
    Object? mimeType = null,
    Object? sizeBytes = null,
    Object? uploadedBy = null,
    Object? confirmed = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? url = freezed,
    Object? thumbUrl = freezed,
  }) {
    return _then(
      _$DocumentImpl(
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
        stepId: freezed == stepId
            ? _value.stepId
            : stepId // ignore: cast_nullable_to_non_nullable
                  as String?,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as DocumentCategory,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        documentDate: freezed == documentDate
            ? _value.documentDate
            : documentDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        fileKey: null == fileKey
            ? _value.fileKey
            : fileKey // ignore: cast_nullable_to_non_nullable
                  as String,
        thumbKey: freezed == thumbKey
            ? _value.thumbKey
            : thumbKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        mimeType: null == mimeType
            ? _value.mimeType
            : mimeType // ignore: cast_nullable_to_non_nullable
                  as String,
        sizeBytes: null == sizeBytes
            ? _value.sizeBytes
            : sizeBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        uploadedBy: null == uploadedBy
            ? _value.uploadedBy
            : uploadedBy // ignore: cast_nullable_to_non_nullable
                  as String,
        confirmed: null == confirmed
            ? _value.confirmed
            : confirmed // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        url: freezed == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String?,
        thumbUrl: freezed == thumbUrl
            ? _value.thumbUrl
            : thumbUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$DocumentImpl implements _Document {
  const _$DocumentImpl({
    required this.id,
    required this.projectId,
    this.stageId,
    this.stepId,
    required this.category,
    required this.title,
    this.description,
    this.documentDate,
    required this.fileKey,
    this.thumbKey,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedBy,
    required this.confirmed,
    required this.createdAt,
    required this.updatedAt,
    this.url,
    this.thumbUrl,
  });

  @override
  final String id;
  @override
  final String projectId;
  @override
  final String? stageId;
  @override
  final String? stepId;
  @override
  final DocumentCategory category;
  @override
  final String title;
  @override
  final String? description;
  @override
  final DateTime? documentDate;
  @override
  final String fileKey;
  @override
  final String? thumbKey;
  @override
  final String mimeType;
  @override
  final int sizeBytes;
  @override
  final String uploadedBy;
  @override
  final bool confirmed;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? url;
  @override
  final String? thumbUrl;

  @override
  String toString() {
    return 'Document(id: $id, projectId: $projectId, stageId: $stageId, stepId: $stepId, category: $category, title: $title, description: $description, documentDate: $documentDate, fileKey: $fileKey, thumbKey: $thumbKey, mimeType: $mimeType, sizeBytes: $sizeBytes, uploadedBy: $uploadedBy, confirmed: $confirmed, createdAt: $createdAt, updatedAt: $updatedAt, url: $url, thumbUrl: $thumbUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocumentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.stageId, stageId) || other.stageId == stageId) &&
            (identical(other.stepId, stepId) || other.stepId == stepId) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.documentDate, documentDate) ||
                other.documentDate == documentDate) &&
            (identical(other.fileKey, fileKey) || other.fileKey == fileKey) &&
            (identical(other.thumbKey, thumbKey) ||
                other.thumbKey == thumbKey) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.uploadedBy, uploadedBy) ||
                other.uploadedBy == uploadedBy) &&
            (identical(other.confirmed, confirmed) ||
                other.confirmed == confirmed) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.thumbUrl, thumbUrl) ||
                other.thumbUrl == thumbUrl));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    projectId,
    stageId,
    stepId,
    category,
    title,
    description,
    documentDate,
    fileKey,
    thumbKey,
    mimeType,
    sizeBytes,
    uploadedBy,
    confirmed,
    createdAt,
    updatedAt,
    url,
    thumbUrl,
  );

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DocumentImplCopyWith<_$DocumentImpl> get copyWith =>
      __$$DocumentImplCopyWithImpl<_$DocumentImpl>(this, _$identity);
}

abstract class _Document implements Document {
  const factory _Document({
    required final String id,
    required final String projectId,
    final String? stageId,
    final String? stepId,
    required final DocumentCategory category,
    required final String title,
    final String? description,
    final DateTime? documentDate,
    required final String fileKey,
    final String? thumbKey,
    required final String mimeType,
    required final int sizeBytes,
    required final String uploadedBy,
    required final bool confirmed,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final String? url,
    final String? thumbUrl,
  }) = _$DocumentImpl;

  @override
  String get id;
  @override
  String get projectId;
  @override
  String? get stageId;
  @override
  String? get stepId;
  @override
  DocumentCategory get category;
  @override
  String get title;
  @override
  String? get description;
  @override
  DateTime? get documentDate;
  @override
  String get fileKey;
  @override
  String? get thumbKey;
  @override
  String get mimeType;
  @override
  int get sizeBytes;
  @override
  String get uploadedBy;
  @override
  bool get confirmed;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String? get url;
  @override
  String? get thumbUrl;

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DocumentImplCopyWith<_$DocumentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
