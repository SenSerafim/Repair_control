import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/socket_service.dart';
import '../../auth/domain/auth_failure.dart';
import '../data/chats_repository.dart';
import '../domain/chat.dart';
import '../domain/message.dart';

final projectChatsProvider = AsyncNotifierProvider.family<
    ProjectChatsController, List<Chat>, String>(
  ProjectChatsController.new,
);

class ProjectChatsController
    extends FamilyAsyncNotifier<List<Chat>, String> {
  @override
  Future<List<Chat>> build(String projectId) {
    return ref.read(chatsRepositoryProvider).listProject(projectId);
  }

  Future<AuthFailure?> createPersonal(String withUserId) async {
    try {
      final c = await ref
          .read(chatsRepositoryProvider)
          .createPersonal(projectId: arg, withUserId: withUserId);
      state = AsyncData([c, ...(state.value ?? const [])]);
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
      state = AsyncData([c, ...(state.value ?? const [])]);
      return null;
    } on ChatsException catch (e) {
      return e.failure;
    }
  }
}

/// Сообщения одного чата с WS-подписками. Держит также typing-user-set.
final messagesProvider = AsyncNotifierProvider.family<
    MessagesController, List<Message>, String>(
  MessagesController.new,
);

class MessagesController
    extends FamilyAsyncNotifier<List<Message>, String> {
  StreamSubscription<dynamic>? _newSub;
  StreamSubscription<dynamic>? _editSub;
  StreamSubscription<dynamic>? _delSub;

  String? _nextCursor;

  @override
  Future<List<Message>> build(String chatId) async {
    final socket = ref.read(socketServiceProvider);
    await socket.connect();
    socket.joinChat(chatId);

    _newSub = socket.on(SocketEvents.messageNew).listen((payload) {
      final data = payload;
      if (data is Map && data['chatId'] == chatId) {
        _handleIncoming(Message.parse(Map<String, dynamic>.from(data)));
      }
    });
    _editSub = socket.on(SocketEvents.messageEdited).listen((payload) {
      if (payload is Map && payload['chatId'] == chatId) {
        _handleIncoming(
          Message.parse(Map<String, dynamic>.from(payload)),
          replace: true,
        );
      }
    });
    _delSub = socket.on(SocketEvents.messageDeleted).listen((payload) {
      if (payload is Map && payload['chatId'] == chatId) {
        _handleIncoming(
          Message.parse(Map<String, dynamic>.from(payload)),
          replace: true,
        );
      }
    });

    ref.onDispose(() {
      _newSub?.cancel();
      _editSub?.cancel();
      _delSub?.cancel();
      socket.leaveChat(chatId);
    });

    final page = await ref
        .read(chatsRepositoryProvider)
        .listMessages(chatId: chatId);
    _nextCursor = page.nextCursor;
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
      final current = state.value ?? const <Message>[];
      state = AsyncData(
        current
            .map((m) => m.id == messageId
                ? m.copyWith(deletedAt: DateTime.now(), text: null)
                : m)
            .toList(),
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
