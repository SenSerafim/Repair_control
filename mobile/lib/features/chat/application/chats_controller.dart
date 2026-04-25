import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/socket_service.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_failure.dart';
import '../data/chats_repository.dart';
import '../domain/chat.dart';
import '../domain/message.dart';

/// Сортировка чатов по `lastMessageAt DESC`, при равных или null — `createdAt`.
List<Chat> _sortChats(List<Chat> input) {
  return [...input]..sort((a, b) {
      final ad = a.lastMessageAt ?? a.createdAt;
      final bd = b.lastMessageAt ?? b.createdAt;
      return bd.compareTo(ad);
    });
}

final projectChatsProvider = AsyncNotifierProvider.family<
    ProjectChatsController, List<Chat>, String>(
  ProjectChatsController.new,
);

class ProjectChatsController
    extends FamilyAsyncNotifier<List<Chat>, String> {
  @override
  Future<List<Chat>> build(String projectId) async {
    final raw =
        await ref.read(chatsRepositoryProvider).listProject(projectId);
    return _sortChats(raw);
  }

  Future<AuthFailure?> createPersonal(String withUserId) async {
    try {
      final c = await ref
          .read(chatsRepositoryProvider)
          .createPersonal(projectId: arg, withUserId: withUserId);
      state = AsyncData(_sortChats([c, ...(state.value ?? const [])]));
      return null;
    } on ChatsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> createGroup({
    required String title,
    required List<String> participantUserIds,
  }) async {
    try {
      final c = await ref.read(chatsRepositoryProvider).createGroup(
            projectId: arg,
            title: title,
            participantUserIds: participantUserIds,
          );
      state = AsyncData(_sortChats([c, ...(state.value ?? const [])]));
      return null;
    } on ChatsException catch (e) {
      return e.failure;
    }
  }
}

/// Текущий открытый чат — для подавления foreground-push'ей.
/// FcmService при `kind=chat_message_new` сверяет `chatId` с этим
/// провайдером и не показывает local-notification если совпадает.
final currentChatIdProvider = StateProvider<String?>((ref) => null);

/// Set userId-ов, которые сейчас «печатают» в чате `chatId`.
/// Очищается при `typing=false` или таймауте 5 секунд.
final typingUsersProvider = StateProvider.autoDispose
    .family<Set<String>, String>((ref, _) => const <String>{});

/// Сообщения одного чата с WS-подписками. Также управляет typing-set
/// через `typingUsersProvider(chatId)` и mark-read при первой загрузке.
final messagesProvider = AsyncNotifierProvider.family<
    MessagesController, List<Message>, String>(
  MessagesController.new,
);

class MessagesController
    extends FamilyAsyncNotifier<List<Message>, String> {
  StreamSubscription<dynamic>? _newSub;
  StreamSubscription<dynamic>? _editSub;
  StreamSubscription<dynamic>? _delSub;
  StreamSubscription<dynamic>? _typingSub;
  final Map<String, Timer> _typingTimers = {};

  String? _nextCursor;

  @override
  Future<List<Message>> build(String chatId) async {
    final socket = ref.read(socketServiceProvider);
    await socket.connect();
    // Backend emit'ит ack с `{ok: true, joined: [...]}`. Если false —
    // продолжаем слушать поток, но возможно не получим broadcast'ы.
    unawaited(socket.joinChat(chatId));

    _newSub = socket.on(SocketEvents.messageNew).listen((payload) {
      // Backend payload: { chatId, message: SerializedMessage }
      if (payload is! Map) return;
      if (payload['chatId'] != chatId) return;
      final raw = payload['message'];
      if (raw is! Map) return;
      _handleIncoming(Message.parse(Map<String, dynamic>.from(raw)));
    });
    _editSub = socket.on(SocketEvents.messageEdited).listen((payload) {
      // Backend payload: { chatId, messageId, text: string | null }
      if (payload is! Map) return;
      if (payload['chatId'] != chatId) return;
      final messageId = payload['messageId'] as String?;
      if (messageId == null) return;
      final newText = payload['text'] as String?;
      _patchMessage(
        messageId,
        (m) => m.copyWith(text: newText, editedAt: DateTime.now()),
      );
    });
    _delSub = socket.on(SocketEvents.messageDeleted).listen((payload) {
      // Backend payload: { chatId, messageId }
      if (payload is! Map) return;
      if (payload['chatId'] != chatId) return;
      final messageId = payload['messageId'] as String?;
      if (messageId == null) return;
      _patchMessage(
        messageId,
        (m) => m.copyWith(text: null, deletedAt: DateTime.now()),
      );
    });
    _typingSub = socket.on(SocketEvents.presenceTyping).listen((payload) {
      // Backend payload: { chatId, userId, typing }
      if (payload is! Map) return;
      if (payload['chatId'] != chatId) return;
      final userId = payload['userId'] as String?;
      if (userId == null) return;
      final typing = payload['typing'] == true;
      _bumpTyping(chatId, userId, typing: typing);
    });

    ref.onDispose(() {
      _newSub?.cancel();
      _editSub?.cancel();
      _delSub?.cancel();
      _typingSub?.cancel();
      for (final t in _typingTimers.values) {
        t.cancel();
      }
      _typingTimers.clear();
      socket.leaveChat(chatId);
    });

    final page = await ref
        .read(chatsRepositoryProvider)
        .listMessages(chatId: chatId);
    _nextCursor = page.nextCursor;

    // Auto mark-read: при открытии чата помечаем последнее «не своё»
    // сообщение прочитанным. Бэк увеличит lastReadAt и эмитит `message:read`.
    final me = ref.read(authControllerProvider).userId;
    final lastNotMineIdx = page.items.indexWhere(
      (m) => m.authorId != me && !m.isDeleted,
    );
    if (lastNotMineIdx >= 0) {
      unawaited(markRead(page.items[lastNotMineIdx].id));
    }
    return page.items;
  }

  void _handleIncoming(Message m, {bool replace = false}) {
    final current = state.value ?? const <Message>[];
    final exists = current.any((x) => x.id == m.id);
    if (replace && exists) {
      state = AsyncData(
        current.map((x) => x.id == m.id ? m : x).toList(),
      );
    } else if (!exists) {
      state = AsyncData([m, ...current]);
    }
  }

  void _patchMessage(String messageId, Message Function(Message) patch) {
    final current = state.value ?? const <Message>[];
    if (!current.any((m) => m.id == messageId)) return;
    state = AsyncData(
      current.map((m) => m.id == messageId ? patch(m) : m).toList(),
    );
  }

  void _bumpTyping(String chatId, String userId, {required bool typing}) {
    final notifier = ref.read(typingUsersProvider(chatId).notifier);
    final current = ref.read(typingUsersProvider(chatId));
    if (typing) {
      if (!current.contains(userId)) {
        notifier.state = {...current, userId};
      }
      // Авто-сброс через 5 сек если новый typing=true не пришёл.
      _typingTimers[userId]?.cancel();
      _typingTimers[userId] = Timer(const Duration(seconds: 5), () {
        _bumpTyping(chatId, userId, typing: false);
      });
    } else {
      _typingTimers[userId]?.cancel();
      _typingTimers.remove(userId);
      if (current.contains(userId)) {
        notifier.state = current.where((u) => u != userId).toSet();
      }
    }
  }

  Future<AuthFailure?> send({
    required String text,
    List<String>? attachmentKeys,
  }) async {
    try {
      final m = await ref.read(chatsRepositoryProvider).sendMessage(
            chatId: arg,
            text: text.isEmpty ? null : text,
            attachmentKeys: attachmentKeys,
          );
      // WS должен прислать — но вставим сразу для латентности.
      _handleIncoming(m);
      return null;
    } on ChatsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> edit({
    required String messageId,
    required String text,
  }) async {
    try {
      final m = await ref.read(chatsRepositoryProvider).editMessage(
            chatId: arg,
            messageId: messageId,
            text: text,
          );
      _handleIncoming(m, replace: true);
      return null;
    } on ChatsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> delete(String messageId) async {
    try {
      await ref.read(chatsRepositoryProvider).deleteMessage(
            chatId: arg,
            messageId: messageId,
          );
      _patchMessage(
        messageId,
        (m) => m.copyWith(text: null, deletedAt: DateTime.now()),
      );
      return null;
    } on ChatsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> forward({
    required String messageId,
    required String toChatId,
  }) async {
    try {
      await ref.read(chatsRepositoryProvider).forwardMessage(
            chatId: arg,
            messageId: messageId,
            toChatId: toChatId,
          );
      return null;
    } on ChatsException catch (e) {
      return e.failure;
    }
  }

  Future<void> markRead(String messageId) async {
    try {
      await ref
          .read(chatsRepositoryProvider)
          .markRead(chatId: arg, messageId: messageId);
    } on ChatsException {
      /* silent */
    }
  }

  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null) return;
    try {
      final page = await ref.read(chatsRepositoryProvider).listMessages(
            chatId: arg,
            cursor: cursor,
          );
      _nextCursor = page.nextCursor;
      state = AsyncData([...?state.value, ...page.items]);
    } on ChatsException {
      /* keep */
    }
  }
}
