import 'package:dio/dio.dart';

import '../../chat/data/chats_repository.dart';
import '../../chat/domain/chat.dart';
import '../../chat/domain/message.dart';
import 'demo_data.dart';

/// Mock-репозиторий чатов и сообщений для демо-тура.
class DemoChatsRepository extends ChatsRepository {
  DemoChatsRepository() : super(Dio());

  @override
  Future<List<Chat>> listProject(String projectId) async => DemoData.chats;

  @override
  Future<Chat> get(String chatId) async => DemoData.chatById(chatId);

  @override
  Future<List<MyChatItem>> listMine() async => DemoData.chats
      .map((c) => MyChatItem(
            chat: c,
            projectId: DemoData.projectId,
            projectTitle: DemoData.project.title,
          ))
      .toList();

  @override
  Future<Chat> createPersonal({
    required String projectId,
    required String withUserId,
  }) async =>
      DemoData.chats.first;

  @override
  Future<Chat> createGroup({
    required String projectId,
    required String title,
    required List<String> participantUserIds,
  }) async =>
      DemoData.chats.first;

  @override
  Future<Chat> patch({
    required String chatId,
    String? title,
    bool? visibleToCustomer,
  }) async =>
      DemoData.chatById(chatId);

  @override
  Future<Chat> addParticipant({
    required String chatId,
    required String userId,
  }) async =>
      DemoData.chatById(chatId);

  @override
  Future<void> removeParticipant({
    required String chatId,
    required String userId,
  }) async {}

  @override
  Future<MessagesPage> listMessages({
    required String chatId,
    String? cursor,
    int limit = 50,
  }) async {
    return MessagesPage(items: DemoData.messagesForChat(chatId));
  }

  @override
  Future<Message> sendMessage({
    required String chatId,
    String? text,
    List<String>? attachmentKeys,
  }) async =>
      DemoData.messagesForProjectChat.last;

  @override
  Future<Message> editMessage({
    required String chatId,
    required String messageId,
    required String text,
  }) async =>
      DemoData.messagesForProjectChat.last;

  @override
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {}

  @override
  Future<Message> forwardMessage({
    required String chatId,
    required String messageId,
    required String toChatId,
  }) async =>
      DemoData.messagesForProjectChat.last;

  @override
  Future<void> markRead({
    required String chatId,
    required String messageId,
  }) async {}
}
