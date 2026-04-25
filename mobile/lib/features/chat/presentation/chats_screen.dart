import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/system_role.dart';
import '../../../core/routing/app_routes.dart';
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
        onAction: () => context.go(AppRoutes.projects),
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
          // ТЗ §10.2 + §6.2: customer не видит чат этапа, если бригадир
          // явно не включил `visibleToCustomer`. Бэкенд так же фильтрует,
          // но клиент дублирует на случай stale-данных.
          final role = ref.watch(activeRoleProvider);
          final visible = chats.where((c) {
            if (role != SystemRole.customer) return true;
            if (c.type != ChatType.stage) return true;
            return c.visibleToCustomer;
          }).toList();
          if (visible.isEmpty) {
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
              itemCount: visible.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.x8),
              itemBuilder: (_, i) => _ChatRow(
                chat: visible[i],
                onTap: () =>
                    context.push(AppRoutes.chatDetailWith(visible[i].id)),
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
            // Project/group/stage чаты — quad-color avatar (палитра по chat.id);
            // personal — фиксированный blue (более «личное» восприятие).
            AppAvatar(
              seed: chat.id,
              name: titleText,
              size: 44,
              palette: chat.type == ChatType.personal
                  ? AvatarPalette.blue
                  : null,
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
