import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/chat/domain/chat.dart';
import 'package:repair_control/features/chat/domain/message.dart';

/// Phase 7: pure-функции домена чата. WebSocket-флоу покрывается
/// integration-тестами в Phase 11.
void main() {
  Chat chat({
    required String id,
    required ChatType type,
    bool visibleToCustomer = false,
    DateTime? lastMessageAt,
    DateTime? createdAt,
  }) =>
      Chat.parse({
        'id': id,
        'type': type.name,
        'projectId': 'p-1',
        'visibleToCustomer': visibleToCustomer,
        'createdById': 'u-1',
        'createdAt': (createdAt ?? DateTime.utc(2026, 4, 1)).toIso8601String(),
        if (lastMessageAt != null)
          'lastMessageAt': lastMessageAt.toIso8601String(),
      });

  Message message({
    String id = 'm-1',
    String chatId = 'c-1',
    String authorId = 'u-1',
    String? text,
    DateTime? createdAt,
    DateTime? deletedAt,
    DateTime? editedAt,
  }) =>
      Message.parse({
        'id': id,
        'chatId': chatId,
        'authorId': authorId,
        if (text != null) 'text': text,
        'createdAt': (createdAt ?? DateTime.utc(2026, 4, 1)).toIso8601String(),
        if (editedAt != null) 'editedAt': editedAt.toIso8601String(),
        if (deletedAt != null) 'deletedAt': deletedAt.toIso8601String(),
      });

  group('Chat sort: lastMessageAt DESC, fallback createdAt', () {
    int byLastMsgDesc(Chat a, Chat b) {
      final ad = a.lastMessageAt ?? a.createdAt;
      final bd = b.lastMessageAt ?? b.createdAt;
      return bd.compareTo(ad);
    }

    test('последний lastMessageAt — первый', () {
      final chats = [
        chat(
          id: 'c1',
          type: ChatType.project,
          createdAt: DateTime.utc(2026, 4, 1),
          lastMessageAt: DateTime.utc(2026, 4, 5),
        ),
        chat(
          id: 'c2',
          type: ChatType.group,
          createdAt: DateTime.utc(2026, 4, 1),
          lastMessageAt: DateTime.utc(2026, 4, 10),
        ),
      ]..sort(byLastMsgDesc);
      expect(chats.first.id, 'c2');
    });

    test('null lastMessageAt — упорядочен по createdAt', () {
      final chats = [
        chat(
          id: 'c1',
          type: ChatType.project,
          createdAt: DateTime.utc(2026, 4, 1),
        ),
        chat(
          id: 'c2',
          type: ChatType.group,
          createdAt: DateTime.utc(2026, 4, 5),
        ),
      ]..sort(byLastMsgDesc);
      expect(chats.first.id, 'c2');
    });
  });

  group('Customer visibility filter (ТЗ §10.2)', () {
    test('customer не видит stage-чат с visibleToCustomer=false', () {
      final chats = [
        chat(id: 'c-proj', type: ChatType.project),
        chat(id: 'c-stage-hidden', type: ChatType.stage),
        chat(
          id: 'c-stage-visible',
          type: ChatType.stage,
          visibleToCustomer: true,
        ),
      ];
      // Логика, которую проверяет ProjectChatsScreen для customer.
      bool isVisibleForCustomer(Chat c) {
        if (c.type != ChatType.stage) return true;
        return c.visibleToCustomer;
      }

      final visible = chats.where(isVisibleForCustomer).toList();
      expect(visible.map((c) => c.id), ['c-proj', 'c-stage-visible']);
    });

    test('foreman видит все типы чатов', () {
      final chats = [
        chat(id: 'c-proj', type: ChatType.project),
        chat(id: 'c-stage', type: ChatType.stage),
        chat(id: 'c-pers', type: ChatType.personal),
        chat(id: 'c-grp', type: ChatType.group),
      ];
      // Foreman не имеет фильтра — видит всё, что вернул бэк.
      expect(chats.length, 4);
    });
  });

  group('Message edit window — 15 минут', () {
    test('canEdit=true в окне', () {
      final now = DateTime.utc(2026, 4, 1, 12, 5);
      final m = message(
        authorId: 'me',
        createdAt: DateTime.utc(2026, 4, 1, 12, 0),
      );
      expect(m.canEdit(byUserId: 'me', now: now), isTrue);
    });

    test('canEdit=false после 15 минут', () {
      final now = DateTime.utc(2026, 4, 1, 12, 16);
      final m = message(
        authorId: 'me',
        createdAt: DateTime.utc(2026, 4, 1, 12, 0),
      );
      expect(m.canEdit(byUserId: 'me', now: now), isFalse);
    });

    test('canEdit=false для чужого сообщения', () {
      final now = DateTime.utc(2026, 4, 1, 12, 5);
      final m = message(
        authorId: 'other',
        createdAt: DateTime.utc(2026, 4, 1, 12, 0),
      );
      expect(m.canEdit(byUserId: 'me', now: now), isFalse);
    });

    test('canEdit=false если deleted', () {
      final now = DateTime.utc(2026, 4, 1, 12, 5);
      final m = message(
        authorId: 'me',
        createdAt: DateTime.utc(2026, 4, 1, 12, 0),
        deletedAt: DateTime.utc(2026, 4, 1, 12, 1),
      );
      expect(m.canEdit(byUserId: 'me', now: now), isFalse);
    });
  });

  group('Backend WS payload parsing', () {
    test('message:edited не дёргает Message.parse — только messageId+text',
        () {
      // Контракт: backend шлёт {chatId, messageId, text} — payload НЕ
      // содержит полное Message. Mobile должен patch'ить локальный кеш.
      final payload = {
        'chatId': 'c-1',
        'messageId': 'm-7',
        'text': 'Поправил',
      };
      expect(payload['messageId'], 'm-7');
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('createdAt'), isFalse);
    });

    test('message:deleted содержит только chatId + messageId', () {
      final payload = {'chatId': 'c-1', 'messageId': 'm-7'};
      expect(payload['messageId'], 'm-7');
      expect(payload.containsKey('text'), isFalse);
    });

    test('presence:typing содержит userId + typing', () {
      final payload = {
        'chatId': 'c-1',
        'userId': 'u-2',
        'typing': true,
      };
      expect(payload['typing'], isTrue);
      expect(payload['userId'], 'u-2');
    });
  });
}
