import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/api_error.dart';
import '../../../shared/widgets/app_states.dart';
import '../data/chats_repository.dart';
import '../domain/chat.dart';

/// NEWFIX Task 2.3 — loading shim that resolves a stage's chat (idempotent
/// POST /api/stages/:stageId/chat) and pushReplaces into the standard
/// /chats/:chatId conversation. Keeps the stage-chat URL stable while reusing
/// the existing ChatConversationScreen.
class StageChatScreen extends ConsumerStatefulWidget {
  const StageChatScreen({super.key, required this.stageId});
  final String stageId;

  @override
  ConsumerState<StageChatScreen> createState() => _StageChatScreenState();
}

class _StageChatScreenState extends ConsumerState<StageChatScreen> {
  late Future<Chat> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve();
  }

  Future<Chat> _resolve() =>
      ref.read(chatsRepositoryProvider).ensureStageChat(widget.stageId);

  void _retry() {
    setState(() => _future = _resolve());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Chat>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: AppLoadingState());
        }
        if (snap.hasError || snap.data == null) {
          final err = snap.error;
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
              subtitle: (msg == null || msg.isEmpty)
                  ? 'Попробуйте ещё раз'
                  : msg,
              onRetry: _retry,
            ),
          );
        }
        final chatId = snap.data!.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pushReplacement('/chats/$chatId');
        });
        return const Scaffold(body: AppLoadingState());
      },
    );
  }
}
