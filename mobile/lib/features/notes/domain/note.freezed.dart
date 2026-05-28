// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Note {
  String get id => throw _privateConstructorUsedError;
  NoteScope get scope => throw _privateConstructorUsedError;
  NoteKind get kind => throw _privateConstructorUsedError;
  String get authorId => throw _privateConstructorUsedError;
  String? get addresseeId => throw _privateConstructorUsedError;
  String? get projectId => throw _privateConstructorUsedError;
  String? get stageId => throw _privateConstructorUsedError;
  String? get text => throw _privateConstructorUsedError;
  String? get audioKey => throw _privateConstructorUsedError;
  String? get audioMimeType => throw _privateConstructorUsedError;
  int? get audioDurationMs => throw _privateConstructorUsedError;
  String? get audioUrl => throw _privateConstructorUsedError;
  String? get transcript => throw _privateConstructorUsedError;
  TranscriptStatus? get transcriptStatus => throw _privateConstructorUsedError;
  String? get transcriptProvider => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NoteCopyWith<Note> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteCopyWith<$Res> {
  factory $NoteCopyWith(Note value, $Res Function(Note) then) =
      _$NoteCopyWithImpl<$Res, Note>;
  @useResult
  $Res call({
    String id,
    NoteScope scope,
    NoteKind kind,
    String authorId,
    String? addresseeId,
    String? projectId,
    String? stageId,
    String? text,
    String? audioKey,
    String? audioMimeType,
    int? audioDurationMs,
    String? audioUrl,
    String? transcript,
    TranscriptStatus? transcriptStatus,
    String? transcriptProvider,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$NoteCopyWithImpl<$Res, $Val extends Note>
    implements $NoteCopyWith<$Res> {
  _$NoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? scope = null,
    Object? kind = null,
    Object? authorId = null,
    Object? addresseeId = freezed,
    Object? projectId = freezed,
    Object? stageId = freezed,
    Object? text = freezed,
    Object? audioKey = freezed,
    Object? audioMimeType = freezed,
    Object? audioDurationMs = freezed,
    Object? audioUrl = freezed,
    Object? transcript = freezed,
    Object? transcriptStatus = freezed,
    Object? transcriptProvider = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            scope: null == scope
                ? _value.scope
                : scope // ignore: cast_nullable_to_non_nullable
                      as NoteScope,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as NoteKind,
            authorId: null == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String,
            addresseeId: freezed == addresseeId
                ? _value.addresseeId
                : addresseeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            projectId: freezed == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                      as String?,
            stageId: freezed == stageId
                ? _value.stageId
                : stageId // ignore: cast_nullable_to_non_nullable
                      as String?,
            text: freezed == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String?,
            audioKey: freezed == audioKey
                ? _value.audioKey
                : audioKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            audioMimeType: freezed == audioMimeType
                ? _value.audioMimeType
                : audioMimeType // ignore: cast_nullable_to_non_nullable
                      as String?,
            audioDurationMs: freezed == audioDurationMs
                ? _value.audioDurationMs
                : audioDurationMs // ignore: cast_nullable_to_non_nullable
                      as int?,
            audioUrl: freezed == audioUrl
                ? _value.audioUrl
                : audioUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            transcript: freezed == transcript
                ? _value.transcript
                : transcript // ignore: cast_nullable_to_non_nullable
                      as String?,
            transcriptStatus: freezed == transcriptStatus
                ? _value.transcriptStatus
                : transcriptStatus // ignore: cast_nullable_to_non_nullable
                      as TranscriptStatus?,
            transcriptProvider: freezed == transcriptProvider
                ? _value.transcriptProvider
                : transcriptProvider // ignore: cast_nullable_to_non_nullable
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
abstract class _$$NoteImplCopyWith<$Res> implements $NoteCopyWith<$Res> {
  factory _$$NoteImplCopyWith(
    _$NoteImpl value,
    $Res Function(_$NoteImpl) then,
  ) = __$$NoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    NoteScope scope,
    NoteKind kind,
    String authorId,
    String? addresseeId,
    String? projectId,
    String? stageId,
    String? text,
    String? audioKey,
    String? audioMimeType,
    int? audioDurationMs,
    String? audioUrl,
    String? transcript,
    TranscriptStatus? transcriptStatus,
    String? transcriptProvider,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$NoteImplCopyWithImpl<$Res>
    extends _$NoteCopyWithImpl<$Res, _$NoteImpl>
    implements _$$NoteImplCopyWith<$Res> {
  __$$NoteImplCopyWithImpl(_$NoteImpl _value, $Res Function(_$NoteImpl) _then)
    : super(_value, _then);

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? scope = null,
    Object? kind = null,
    Object? authorId = null,
    Object? addresseeId = freezed,
    Object? projectId = freezed,
    Object? stageId = freezed,
    Object? text = freezed,
    Object? audioKey = freezed,
    Object? audioMimeType = freezed,
    Object? audioDurationMs = freezed,
    Object? audioUrl = freezed,
    Object? transcript = freezed,
    Object? transcriptStatus = freezed,
    Object? transcriptProvider = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$NoteImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        scope: null == scope
            ? _value.scope
            : scope // ignore: cast_nullable_to_non_nullable
                  as NoteScope,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as NoteKind,
        authorId: null == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String,
        addresseeId: freezed == addresseeId
            ? _value.addresseeId
            : addresseeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        projectId: freezed == projectId
            ? _value.projectId
            : projectId // ignore: cast_nullable_to_non_nullable
                  as String?,
        stageId: freezed == stageId
            ? _value.stageId
            : stageId // ignore: cast_nullable_to_non_nullable
                  as String?,
        text: freezed == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String?,
        audioKey: freezed == audioKey
            ? _value.audioKey
            : audioKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        audioMimeType: freezed == audioMimeType
            ? _value.audioMimeType
            : audioMimeType // ignore: cast_nullable_to_non_nullable
                  as String?,
        audioDurationMs: freezed == audioDurationMs
            ? _value.audioDurationMs
            : audioDurationMs // ignore: cast_nullable_to_non_nullable
                  as int?,
        audioUrl: freezed == audioUrl
            ? _value.audioUrl
            : audioUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        transcript: freezed == transcript
            ? _value.transcript
            : transcript // ignore: cast_nullable_to_non_nullable
                  as String?,
        transcriptStatus: freezed == transcriptStatus
            ? _value.transcriptStatus
            : transcriptStatus // ignore: cast_nullable_to_non_nullable
                  as TranscriptStatus?,
        transcriptProvider: freezed == transcriptProvider
            ? _value.transcriptProvider
            : transcriptProvider // ignore: cast_nullable_to_non_nullable
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

class _$NoteImpl implements _Note {
  const _$NoteImpl({
    required this.id,
    required this.scope,
    required this.kind,
    required this.authorId,
    this.addresseeId,
    this.projectId,
    this.stageId,
    this.text,
    this.audioKey,
    this.audioMimeType,
    this.audioDurationMs,
    this.audioUrl,
    this.transcript,
    this.transcriptStatus,
    this.transcriptProvider,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  final String id;
  @override
  final NoteScope scope;
  @override
  final NoteKind kind;
  @override
  final String authorId;
  @override
  final String? addresseeId;
  @override
  final String? projectId;
  @override
  final String? stageId;
  @override
  final String? text;
  @override
  final String? audioKey;
  @override
  final String? audioMimeType;
  @override
  final int? audioDurationMs;
  @override
  final String? audioUrl;
  @override
  final String? transcript;
  @override
  final TranscriptStatus? transcriptStatus;
  @override
  final String? transcriptProvider;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Note(id: $id, scope: $scope, kind: $kind, authorId: $authorId, addresseeId: $addresseeId, projectId: $projectId, stageId: $stageId, text: $text, audioKey: $audioKey, audioMimeType: $audioMimeType, audioDurationMs: $audioDurationMs, audioUrl: $audioUrl, transcript: $transcript, transcriptStatus: $transcriptStatus, transcriptProvider: $transcriptProvider, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.scope, scope) || other.scope == scope) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.addresseeId, addresseeId) ||
                other.addresseeId == addresseeId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.stageId, stageId) || other.stageId == stageId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.audioKey, audioKey) ||
                other.audioKey == audioKey) &&
            (identical(other.audioMimeType, audioMimeType) ||
                other.audioMimeType == audioMimeType) &&
            (identical(other.audioDurationMs, audioDurationMs) ||
                other.audioDurationMs == audioDurationMs) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.transcript, transcript) ||
                other.transcript == transcript) &&
            (identical(other.transcriptStatus, transcriptStatus) ||
                other.transcriptStatus == transcriptStatus) &&
            (identical(other.transcriptProvider, transcriptProvider) ||
                other.transcriptProvider == transcriptProvider) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    scope,
    kind,
    authorId,
    addresseeId,
    projectId,
    stageId,
    text,
    audioKey,
    audioMimeType,
    audioDurationMs,
    audioUrl,
    transcript,
    transcriptStatus,
    transcriptProvider,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteImplCopyWith<_$NoteImpl> get copyWith =>
      __$$NoteImplCopyWithImpl<_$NoteImpl>(this, _$identity);
}

abstract class _Note implements Note {
  const factory _Note({
    required final String id,
    required final NoteScope scope,
    required final NoteKind kind,
    required final String authorId,
    final String? addresseeId,
    final String? projectId,
    final String? stageId,
    final String? text,
    final String? audioKey,
    final String? audioMimeType,
    final int? audioDurationMs,
    final String? audioUrl,
    final String? transcript,
    final TranscriptStatus? transcriptStatus,
    final String? transcriptProvider,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$NoteImpl;

  @override
  String get id;
  @override
  NoteScope get scope;
  @override
  NoteKind get kind;
  @override
  String get authorId;
  @override
  String? get addresseeId;
  @override
  String? get projectId;
  @override
  String? get stageId;
  @override
  String? get text;
  @override
  String? get audioKey;
  @override
  String? get audioMimeType;
  @override
  int? get audioDurationMs;
  @override
  String? get audioUrl;
  @override
  String? get transcript;
  @override
  TranscriptStatus? get transcriptStatus;
  @override
  String? get transcriptProvider;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoteImplCopyWith<_$NoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
