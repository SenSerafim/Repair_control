import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat.freezed.dart';

enum ChatType {
  project,
  stage,
  personal,
  group;

  static ChatType fromString(String? raw) {
    switch (raw) {
      case 'stage':
        return ChatType.stage;
      case 'personal':
        return ChatType.personal;
      case 'group':
        return ChatType.group;
      case 'project':
      default:
        return ChatType.project;
    }
  }

  String get apiValue => switch (this) {
        ChatType.project => 'project',
        ChatType.stage => 'stage',
        ChatType.personal => 'personal',
        ChatType.group => 'group',
      };

  String get displayName => switch (this) {
        ChatType.project => 'Проект',
        ChatType.stage => 'Этап',
        ChatType.personal => 'Личный',
        ChatType.group => 'Группа',
      };
}

@freezed
class ChatParticipant with _$ChatParticipant {
  const factory ChatParticipant({
    required String userId,
    required DateTime joinedAt,
    DateTime? leftAt,
  }) = _ChatParticipant;

  static ChatParticipant parse(Map<String, dynamic> json) => ChatParticipant(
        userId: json['userId'] as String,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        leftAt: _d(json['leftAt']),
      );
}

@freezed
class Chat with _$Chat {
  const factory Chat({
    required String id,
    required ChatType type,
    String? projectId,
    String? stageId,
    String? title,
    required bool visibleToCustomer,
    required String createdById,
    required DateTime createdAt,
    @Default(<ChatParticipant>[]) List<ChatParticipant> participants,
    @Default(0) int unreadCount,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
  }) = _Chat;

  static Chat parse(Map<String, dynamic> json) => Chat(
        id: json['id'] as String,
        type: ChatType.fromString(json['type'] as String?),
        projectId: json['projectId'] as String?,
        stageId: json['stageId'] as String?,
        title: json['title'] as String?,
        visibleToCustomer: json['visibleToCustomer'] as bool? ?? true,
        createdById: json['createdById'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        participants:
            (json['participants'] as List<dynamic>? ?? const [])
                .map((e) => ChatParticipant.parse(e as Map<String, dynamic>))
                .toList(),
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
        lastMessagePreview: json['lastMessagePreview'] as String?,
        lastMessageAt: _d(json['lastMessageAt']),
      );
}

DateTime? _d(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;
