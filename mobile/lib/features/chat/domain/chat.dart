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
class ChatProjectContext with _$ChatProjectContext {
  const factory ChatProjectContext({
    required String id,
    required String title,
  }) = _ChatProjectContext;

  static ChatProjectContext? parse(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return ChatProjectContext(
      id: raw['id'] as String? ?? '',
      title: raw['title'] as String? ?? '',
    );
  }
}

@freezed
class ChatStageContext with _$ChatStageContext {
  const factory ChatStageContext({
    required String id,
    required String title,
    required int orderIndex,
  }) = _ChatStageContext;

  static ChatStageContext? parse(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return ChatStageContext(
      id: raw['id'] as String? ?? '',
      title: raw['title'] as String? ?? '',
      orderIndex: (raw['orderIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

@freezed
class Chat with _$Chat {
  const factory Chat({
    required String id,
    required ChatType type,
    String? projectId,
    String? stageId,
    ChatProjectContext? project,
    ChatStageContext? stage,
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
    project: ChatProjectContext.parse(json['project']),
    stage: ChatStageContext.parse(json['stage']),
    title: json['title'] as String?,
    visibleToCustomer: json['visibleToCustomer'] as bool? ?? true,
    createdById: json['createdById'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    participants: (json['participants'] as List<dynamic>? ?? const [])
        .map((e) => ChatParticipant.parse(e as Map<String, dynamic>))
        .toList(),
    unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    lastMessagePreview: json['lastMessagePreview'] as String?,
    lastMessageAt: _d(json['lastMessageAt']),
  );
}

extension ChatDisplayTitle on Chat {
  String displayTitle({
    String? projectTitleFallback,
    String? stageTitleFallback,
    String? personalTitleFallback,
  }) {
    final customTitle = title?.trim();

    switch (type) {
      case ChatType.project:
        if (customTitle != null && customTitle.isNotEmpty) return customTitle;
        return 'Общий чат проекта';
      case ChatType.stage:
        final stageTitle = (stage?.title ?? stageTitleFallback)?.trim();
        final stageLabel = stageTitle != null && stageTitle.isNotEmpty
            ? stageTitle
            : stage != null
            ? 'Этап ${stage!.orderIndex + 1}'
            : null;
        if (stageLabel != null) return stageLabel;
        if (customTitle != null && customTitle.isNotEmpty) {
          return _stageTitleFromLegacyChatTitle(customTitle);
        }
        return 'Чат этапа';
      case ChatType.group:
        if (customTitle != null && customTitle.isNotEmpty) return customTitle;
        return 'Группа';
      case ChatType.personal:
        if (customTitle != null && customTitle.isNotEmpty) return customTitle;
        final personalTitle = personalTitleFallback?.trim();
        return personalTitle != null && personalTitle.isNotEmpty
            ? personalTitle
            : 'Личный чат';
    }
  }
}

String _stageTitleFromLegacyChatTitle(String title) {
  final parts = title.split(RegExp(r'\s+-\s+'));
  final last = parts.isEmpty ? title : parts.last.trim();
  return last.isEmpty ? title : last;
}

DateTime? _d(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;
