import 'package:flutter/material.dart' hide Step;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../chat/application/chats_controller.dart';
import '../../../chat/domain/chat.dart';

/// Таб «Чат» в детали этапа — c-stage-chat.
///
/// Из projectChatsProvider выбирается чат с `stageId == currentStageId`. Если
/// его ещё нет (старые этапы без foreman'а), показываем placeholder и подсказку
/// — чат создастся автоматически после назначения бригадира.
class StageChatTab extends ConsumerWidget {
  const StageChatTab({
    required this.projectId,
    required this.stageId,
    super.key,
  });

  final String projectId;
  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectChatsProvider(projectId));
    return async.when(
      loading: () => const AppLoadingState(),
      error: (e, _) => AppErrorState(
        title: 'Не удалось загрузить чат',
        onRetry: () => ref.invalidate(projectChatsProvider(projectId)),
      ),
      data: (chats) {
        final stageChat = chats.cast<Chat?>().firstWhere(
              (c) => c?.stageId == stageId,
              orElse: () => null,
            );
        if (stageChat == null) {
          return const AppEmptyState(
            title: 'Чат этапа не создан',
            subtitle: 'Чат появится автоматически, когда вы назначите '
                'бригадира этапа.',
            icon: Icons.chat_bubble_outline_rounded,
          );
        }
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.x16),
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: AppRadius.card,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.forum_outlined,
                      color: AppColors.brand,
                    ),
                    const SizedBox(width: AppSpacing.x12),
                    Expanded(
                      child: Text(
                        stageChat.title ?? 'Чат этапа',
                        style: AppTextStyles.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x16),
              AppButton(
                label: 'Открыть чат',
                icon: Icons.chat_outlined,
                onPressed: () =>
                    context.push('/chats/${stageChat.id}'),
              ),
            ],
          ),
        );
      },
    );
  }
}
