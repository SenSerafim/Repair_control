import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/system_role.dart';
import '../../../core/routing/app_routes.dart';
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
            return Center(
              child: AppEmptyState(
                title: 'Нет чатов',
                subtitle:
                    'Чаты создаются автоматически при добавлении участников '
                    'в проект',
                icon: Icons.forum_outlined,
                actionLabel: 'Создать чат',
                onAction: () =>
                    showNewChatSheet(context, ref, projectId: projectId),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(projectChatsProvider(projectId)),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: visible.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                indent: 76,
                color: AppColors.n100,
              ),
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

  String _titleText() {
    return chat.title ??
        (chat.type == ChatType.project
            ? 'Общий чат проекта'
            : chat.type == ChatType.stage
                ? 'Чат этапа'
                : 'Личный');
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tDate = DateTime(t.year, t.month, t.day);
    final diff = today.difference(tDate).inDays;
    if (diff == 0) return DateFormat('HH:mm', 'ru').format(t);
    if (diff == 1) return 'вчера';
    if (diff < 7) return DateFormat('EEE', 'ru').format(t);
    return DateFormat('d MMM', 'ru').format(t);
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleText();
    return Material(
      color: AppColors.n0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x16,
            vertical: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppAvatar(
                seed: chat.id,
                name: title,
                size: 48,
                palette: chat.type == ChatType.personal
                    ? AvatarPalette.blue
                    : null,
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n900,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat.lastMessagePreview ?? chat.type.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.n500,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (chat.lastMessageAt != null)
                    Text(
                      _formatTime(chat.lastMessageAt!),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n400,
                      ),
                    )
                  else
                    const SizedBox(height: 14),
                  const SizedBox(height: 6),
                  if (chat.unreadCount > 0)
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: AppShadows.shBlue,
                      ),
                      child: Text(
                        '${chat.unreadCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.n0,
                          height: 1.4,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
