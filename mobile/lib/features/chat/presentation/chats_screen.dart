import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/chats_controller.dart';
import '../domain/chat.dart';
import 'new_chat_sheet.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Чаты',
      body: AppEmptyState(
        title: 'Чаты привязаны к проектам',
        subtitle:
            'Откройте проект и перейдите на плитку «Чаты» — там личные, '
            'групповые и чаты этапов.',
        icon: Icons.chat_bubble_outline_rounded,
        actionLabel: 'К проектам',
        onAction: () => context.go('/projects'),
      ),
    );
  }
}

class ProjectChatsScreen extends ConsumerWidget {
  const ProjectChatsScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectChatsProvider(projectId));

    return AppScaffold(
      showBack: true,
      title: 'Чаты',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Новый чат',
          onPressed: () =>
              showNewChatSheet(context, ref, projectId: projectId),
        ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(skeleton: AppChatListSkeleton()),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить чаты',
          onRetry: () => ref.invalidate(projectChatsProvider(projectId)),
        ),
        data: (chats) {
          if (chats.isEmpty) {
            return const AppEmptyState(
              title: 'Чатов пока нет',
              subtitle:
                  'Создайте личный или групповой чат с участниками проекта.',
              icon: Icons.forum_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(projectChatsProvider(projectId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.x16),
              itemCount: chats.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.x8),
              itemBuilder: (_, i) => _ChatRow(
                chat: chats[i],
                onTap: () => context.push('/chats/${chats[i].id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.chat, required this.onTap});

  final Chat chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleText = chat.title ??
        (chat.type == ChatType.project
            ? 'Общий чат проекта'
            : chat.type == ChatType.stage
                ? 'Чат этапа'
                : 'Личный');
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200, width: 1.5),
          boxShadow: AppShadows.sh1,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(
                chat.type == ChatType.group
                    ? Icons.group_outlined
                    : chat.type == ChatType.stage
                        ? Icons.dashboard_outlined
                        : chat.type == ChatType.personal
                            ? Icons.person_outline_rounded
                            : Icons.forum_outlined,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titleText,
                          style: AppTextStyles.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.lastMessageAt != null)
                        Text(
                          DateFormat('HH:mm', 'ru')
                              .format(chat.lastMessageAt!),
                          style: AppTextStyles.tiny,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessagePreview ??
                              chat.type.displayName,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.unreadCount > 0) ...[
                        const SizedBox(width: AppSpacing.x6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          constraints:
                              const BoxConstraints(minWidth: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.brand,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '${chat.unreadCount}',
                            style: AppTextStyles.tiny
                                .copyWith(color: AppColors.n0),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
