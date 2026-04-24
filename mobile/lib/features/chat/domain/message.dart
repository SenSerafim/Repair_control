import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';

/// Окно редактирования сообщений — 15 минут из backend messages.service.
const kMessageEditWindow = Duration(minutes: 15);

@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String chatId,
    required String authorId,
    String? text,
    @Default(<String>[]) List<String> attachmentKeys,
    String? forwardedFromId,
    DateTime? editedAt,
    DateTime? deletedAt,
    required DateTime createdAt,
  }) = _Message;

  static Message parse(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        chatId: json['chatId'] as String,
        authorId: json['authorId'] as String? ?? '',
        text: json['text'] as String?,
        attachmentKeys: (json['attachmentKeys'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        forwardedFromId: json['forwardedFromId'] as String?,
        editedAt: _d(json['editedAt']),
        deletedAt: _d(json['deletedAt']),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

DateTime? _d(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;

extension MessageX on Message {
  bool get isDeleted => deletedAt != null;
  bool get isEdited => editedAt != null;
  bool get isForwarded => forwardedFromId != null;
  bool get hasAttachments => attachmentKeys.isNotEmpty;

  /// Можно ли ещё редактировать (backend edit-window).
  bool canEdit({required String byUserId, DateTime? now}) {
    if (authorId != byUserId) return false;
    if (isDeleted) return false;
    final t = now ?? DateTime.now();
    return t.difference(createdAt) <= kMessageEditWindow;
  }
}
