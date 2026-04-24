import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/chat.dart';
import '../domain/message.dart';

class ChatsException implements Exception {
  ChatsException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

class MessagesPage {
  const MessagesPage({required this.items, this.nextCursor});
  final List<Message> items;
  final String? nextCursor;
}

class ChatsRepository {
  ChatsRepository(this._dio);
  final Dio _dio;

  Future<List<Chat>> listProject(String projectId) => _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/projects/$projectId/chats',
        );
        return r.data!
            .map((e) => Chat.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<Chat> get(String chatId) => _call(() async {
        final r = await _dio.get<Map<String, dynamic>>('/api/chats/$chatId');
        return Chat.parse(r.data!);
      });

  Future<Chat> createPersonal({
    required String projectId,
    required String withUserId,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/chats/personal',
          data: {'withUserId': withUserId},
        );
        return Chat.parse(r.data!);
      });

  Future<Chat> createGroup({
    required String projectId,
    required String title,
    required List<String> participantUserIds,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/chats/group',
          data: {'title': title, 'participantUserIds': participantUserIds},
        );
        return Chat.parse(r.data!);
      });

  Future<Chat> patch({
    required String chatId,
    String? title,
    bool? visibleToCustomer,
  }) =>
      _call(() async {
        final r = await _dio.patch<Map<String, dynamic>>(
          '/api/chats/$chatId',
          data: {
            if (title != null) 'title': title,
            if (visibleToCustomer != null)
              'visibleToCustomer': visibleToCustomer,
          },
        );
        return Chat.parse(r.data!);
      });

  Future<Chat> addParticipant({
    required String chatId,
    required String userId,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/chats/$chatId/participants',
          data: {'userId': userId},
        );
        return Chat.parse(r.data!);
      });

  Future<void> removeParticipant({
    required String chatId,
    required String userId,
  }) =>
      _call(() async {
        await _dio.delete<void>(
          '/api/chats/$chatId/participants/$userId',
        );
      });

  Future<MessagesPage> listMessages({
    required String chatId,
    String? cursor,
    int limit = 50,
  }) =>
      _call(() async {
        final r = await _dio.get<dynamic>(
          '/api/chats/$chatId/messages',
          queryParameters: {
            if (cursor != null) 'cursor': cursor,
            'limit': limit,
          },
        );
        final data = r.data;
        if (data is Map<String, dynamic>) {
          final items = (data['items'] as List<dynamic>? ?? const [])
              .map((e) => Message.parse(e as Map<String, dynamic>))
              .toList();
          return MessagesPage(
            items: items,
            nextCursor: data['nextCursor'] as String?,
          );
        }
        if (data is List) {
          return MessagesPage(
            items: data
                .map((e) => Message.parse(e as Map<String, dynamic>))
                .toList(),
          );
        }
        return const MessagesPage(items: []);
      });

  Future<Message> sendMessage({
    required String chatId,
    String? text,
    List<String>? attachmentKeys,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/chats/$chatId/messages',
          data: {
            if (text != null) 'text': text,
            if (attachmentKeys != null) 'attachmentKeys': attachmentKeys,
          },
        );
        return Message.parse(r.data!);
      });

  Future<Message> editMessage({
    required String chatId,
    required String messageId,
    required String text,
  }) =>
      _call(() async {
        final r = await _dio.patch<Map<String, dynamic>>(
          '/api/chats/$chatId/messages/$messageId',
          data: {'text': text},
        );
        return Message.parse(r.data!);
      });

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) =>
      _call(() async {
        await _dio.delete<void>('/api/chats/$chatId/messages/$messageId');
      });

  Future<Message> forwardMessage({
    required String chatId,
    required String messageId,
    required String toChatId,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/chats/$chatId/messages/$messageId/forward',
          data: {'toChatId': toChatId},
        );
        return Message.parse(r.data!);
      });

  Future<void> markRead({
    required String chatId,
    required String messageId,
  }) =>
      _call(() async {
        await _dio.post<void>(
          '/api/chats/$chatId/read',
          data: {'messageId': messageId},
        );
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw ChatsException(AuthFailure.fromApiError(api), api);
    }
  }
}

final chatsRepositoryProvider = Provider<ChatsRepository>((ref) {
  return ChatsRepository(ref.read(dioProvider));
});
