import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/system_role.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../onboarding/presentation/widgets/tour_anchor.dart';
import '../application/chats_controller.dart';
import '../data/chats_repository.dart';
import '../domain/chat.dart';
import 'new_chat_sheet.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myChatsProvider);

    return AppScaffold(
      title: 'Чаты',
      padding: EdgeInsets.zero,
      // NEWFIX-2 §3.1 — точка входа в агрегированный экран «Команда».
      // NEWFIX Task 8.1 — единый звоночек с бейджем непрочитанных
      // уведомлений (ТЗ-2 §19) рядом с кнопкой «Команда».
      actions: [
        IconButton(
          icon: const Icon(Icons.groups_outlined),
          tooltip: 'Команда',
          onPressed: () => context.push('/chats/team'),
        ),
        const AppNotificationsBell(),
      ],
      body: async.when(
        loading: () => const AppLoadingState(skeleton: AppChatListSkeleton()),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить чаты',
          subtitle: e is ChatsException
              ? '${e.failure.userMessage} (${e.apiError.code})'
              : e.toString(),
          onRetry: () => ref.invalidate(myChatsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              title: 'Чатов пока нет',
              subtitle:
                  'Чаты создаются автоматически при добавлении участников '
                  'в проект. Откройте проект, чтобы начать переписку.',
              icon: Icons.chat_bubble_outline_rounded,
              actionLabel: 'К проектам',
              onAction: () => context.go(AppRoutes.projects),
            );
          }
          // Фильтр для customer (как и в ProjectChatsScreen) —
          // прячем чаты этапов, которые бригадир не сделал видимыми.
          final role = ref.watch(activeRoleProvider);
          final visible = items.where((it) {
            final c = it.chat;
            if (role != SystemRole.customer) return true;
            if (c.type != ChatType.stage) return true;
            return c.visibleToCustomer;
          }).toList();

          // ТЗ §10.3 — «Поиск по названию чата». Case-insensitive фильтр
          // в-памяти по title чата, projectTitle и last-message preview.
          final q = _query.trim().toLowerCase();
          final filtered = q.isEmpty
              ? visible
              : visible.where((it) {
                  final c = it.chat;
                  final title = (c.title ?? c.type.displayName).toLowerCase();
                  final project = it.projectTitle.toLowerCase();
                  final preview = (c.lastMessagePreview ?? '').toLowerCase();
                  return title.contains(q) ||
                      project.contains(q) ||
                      preview.contains(q);
                }).toList();

          // Группировка по projectId с сохранением исходного порядка.
          final grouped = <String, List<MyChatItem>>{};
          final projectTitles = <String, String>{};
          for (final it in filtered) {
            grouped.putIfAbsent(it.projectId, () => []).add(it);
            projectTitles[it.projectId] = it.projectTitle;
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myChatsProvider),
            child: Column(
              children: [
                _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                ),
                if (filtered.isEmpty && q.isNotEmpty)
                  const Expanded(
                    child: AppEmptyState(
                      title: 'Ничего не найдено',
                      subtitle: 'Попробуйте другое название',
                      icon: Icons.search_off_rounded,
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final entry in grouped.entries) ...[
                          _ProjectGroupHeader(
                            title: projectTitles[entry.key] ?? 'Проект',
                            onTap: () => context.push(
                              AppRoutes.projectDetailWith(entry.key),
                            ),
                          ),
                          for (final it in entry.value)
                            _ChatRow(
                              chat: it.chat,
                              onTap: () => context.push(
                                AppRoutes.chatDetailWith(it.chat.id),
                              ),
                            ),
                        ],
                        const SizedBox(height: AppSpacing.x16),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.n0,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.n50,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: AppColors.n200, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 20, color: AppColors.n400),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Поиск по чатам',
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.n400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectGroupHeader extends StatelessWidget {
  const _ProjectGroupHeader({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.n50,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.n500,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.n400,
              ),
            ],
          ),
        ),
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
          onPressed: () => showNewChatSheet(context, ref, projectId: projectId),
        ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(skeleton: AppChatListSkeleton()),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить чаты',
          subtitle: e is ChatsException
              ? '${e.failure.userMessage} (${e.apiError.code})'
              : e.toString(),
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
              itemBuilder: (_, i) {
                final row = _ChatRow(
                  chat: visible[i],
                  onTap: () =>
                      context.push(AppRoutes.chatDetailWith(visible[i].id)),
                );
                return i == 0
                    ? TourAnchor(id: 'chats.first_chat', child: row)
                    : row;
              },
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
              DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x290D1229),
                      offset: Offset(0, 4),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: const BoxDecoration(
                    color: AppColors.n0,
                    shape: BoxShape.circle,
                  ),
                  child: AppAvatar(
                    seed: chat.id,
                    name: title,
                    size: 45,
                    palette: chat.type == ChatType.personal
                        ? AvatarPalette.blue
                        : null,
                  ),
                ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6),
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
