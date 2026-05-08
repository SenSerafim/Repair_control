// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Message {
  String get id => throw _privateConstructorUsedError;
  String get chatId => throw _privateConstructorUsedError;
  String get authorId => throw _privateConstructorUsedError;
  String? get text => throw _privateConstructorUsedError;
  List<String> get attachmentKeys => throw _privateConstructorUsedError;
  String? get forwardedFromId => throw _privateConstructorUsedError;
  DateTime? get editedAt => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageCopyWith<Message> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageCopyWith<$Res> {
  factory $MessageCopyWith(Message value, $Res Function(Message) then) =
      _$MessageCopyWithImpl<$Res, Message>;
  @useResult
  $Res call({
    String id,
    String chatId,
    String authorId,
    String? text,
    List<String> attachmentKeys,
    String? forwardedFromId,
    DateTime? editedAt,
    DateTime? deletedAt,
    DateTime createdAt,
  });
}

/// @nodoc
class _$MessageCopyWithImpl<$Res, $Val extends Message>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? chatId = null,
    Object? authorId = null,
    Object? text = freezed,
    Object? attachmentKeys = null,
    Object? forwardedFromId = freezed,
    Object? editedAt = freezed,
    Object? deletedAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            chatId: null == chatId
                ? _value.chatId
                : chatId // ignore: cast_nullable_to_non_nullable
                      as String,
            authorId: null == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String,
            text: freezed == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String?,
            attachmentKeys: null == attachmentKeys
                ? _value.attachmentKeys
                : attachmentKeys // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            forwardedFromId: freezed == forwardedFromId
                ? _value.forwardedFromId
                : forwardedFromId // ignore: cast_nullable_to_non_nullable
                      as String?,
            editedAt: freezed == editedAt
                ? _value.editedAt
                : editedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            deletedAt: freezed == deletedAt
                ? _value.deletedAt
                : deletedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageImplCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$$MessageImplCopyWith(
    _$MessageImpl value,
    $Res Function(_$MessageImpl) then,
  ) = __$$MessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String chatId,
    String authorId,
    String? text,
    List<String> attachmentKeys,
    String? forwardedFromId,
    DateTime? editedAt,
    DateTime? deletedAt,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$MessageImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$MessageImpl>
    implements _$$MessageImplCopyWith<$Res> {
  __$$MessageImplCopyWithImpl(
    _$MessageImpl _value,
    $Res Function(_$MessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? chatId = null,
    Object? authorId = null,
    Object? text = freezed,
    Object? attachmentKeys = null,
    Object? forwardedFromId = freezed,
    Object? editedAt = freezed,
    Object? deletedAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$MessageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        chatId: null == chatId
            ? _value.chatId
            : chatId // ignore: cast_nullable_to_non_nullable
                  as String,
        authorId: null == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String,
        text: freezed == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String?,
        attachmentKeys: null == attachmentKeys
            ? _value._attachmentKeys
            : attachmentKeys // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        forwardedFromId: freezed == forwardedFromId
            ? _value.forwardedFromId
            : forwardedFromId // ignore: cast_nullable_to_non_nullable
                  as String?,
        editedAt: freezed == editedAt
            ? _value.editedAt
            : editedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        deletedAt: freezed == deletedAt
            ? _value.deletedAt
            : deletedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$MessageImpl implements _Message {
  const _$MessageImpl({
    required this.id,
    required this.chatId,
    required this.authorId,
    this.text,
    final List<String> attachmentKeys = const <String>[],
    this.forwardedFromId,
    this.editedAt,
    this.deletedAt,
    required this.createdAt,
  }) : _attachmentKeys = attachmentKeys;

  @override
  final String id;
  @override
  final String chatId;
  @override
  final String authorId;
  @override
  final String? text;
  final List<String> _attachmentKeys;
  @override
  @JsonKey()
  List<String> get attachmentKeys {
    if (_attachmentKeys is EqualUnmodifiableListView) return _attachmentKeys;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachmentKeys);
  }

  @override
  final String? forwardedFromId;
  @override
  final DateTime? editedAt;
  @override
  final DateTime? deletedAt;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Message(id: $id, chatId: $chatId, authorId: $authorId, text: $text, attachmentKeys: $attachmentKeys, forwardedFromId: $forwardedFromId, editedAt: $editedAt, deletedAt: $deletedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(
              other._attachmentKeys,
              _attachmentKeys,
            ) &&
            (identical(other.forwardedFromId, forwardedFromId) ||
                other.forwardedFromId == forwardedFromId) &&
            (identical(other.editedAt, editedAt) ||
                other.editedAt == editedAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    chatId,
    authorId,
    text,
    const DeepCollectionEquality().hash(_attachmentKeys),
    forwardedFromId,
    editedAt,
    deletedAt,
    createdAt,
  );

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      __$$MessageImplCopyWithImpl<_$MessageImpl>(this, _$identity);
}

abstract class _Message implements Message {
  const factory _Message({
    required final String id,
    required final String chatId,
    required final String authorId,
    final String? text,
    final List<String> attachmentKeys,
    final String? forwardedFromId,
    final DateTime? editedAt,
    final DateTime? deletedAt,
    required final DateTime createdAt,
  }) = _$MessageImpl;

  @override
  String get id;
  @override
  String get chatId;
  @override
  String get authorId;
  @override
  String? get text;
  @override
  List<String> get attachmentKeys;
  @override
  String? get forwardedFromId;
  @override
  DateTime? get editedAt;
  @override
  DateTime? get deletedAt;
  @override
  DateTime get createdAt;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
