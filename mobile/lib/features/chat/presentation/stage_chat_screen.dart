import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/api_error.dart';
import '../../../shared/widgets/app_states.dart';
import '../application/chats_controller.dart';
import '../data/chats_repository.dart';

/// NEWFIX Task 2.3 — loading shim that resolves a stage's chat (idempotent
/// POST /api/stages/:stageId/chat) and pushReplaces into the standard
/// /chats/:chatId conversation. Keeps the stage-chat URL stable while reusing
/// the existing ChatConversationScreen.
///
/// Резолв идёт через кешированный [stageChatProvider] — повторное открытие
/// чата этапа (вернулся назад → снова открыл) мгновенное, без повторного
/// POST и долгого спиннера (Егор 23.06.2026).
class StageChatScreen extends ConsumerWidget {
  const StageChatScreen({super.key, required this.stageId});
  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stageChatProvider(stageId));
    return async.when(
      loading: () => const Scaffold(body: AppLoadingState()),
      error: (err, _) {
        // ChatsRepository оборачивает DioException в ChatsException; ApiError
        // приходит только если кто-то бросил его напрямую. Проверяем оба.
        String? msg;
        if (err is ChatsException) {
          msg = err.apiError.message ?? err.failure.userMessage;
        } else if (err is ApiError) {
          msg = err.message;
        }
        return Scaffold(
          appBar: AppBar(),
          body: AppErrorState(
            title: 'Не удалось открыть чат этапа',
            subtitle: (msg == null || msg.isEmpty) ? 'Попробуйте ещё раз' : msg,
            onRetry: () => ref.invalidate(stageChatProvider(stageId)),
          ),
        );
      },
      data: (chat) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.pushReplacement('/chats/${chat.id}');
        });
        return const Scaffold(body: AppLoadingState());
      },
    );
  }
}
