import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/push/deep_link_router.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/notifications_controller.dart';
import '../domain/app_notification.dart';

/// s-notifications / f-notifications / c-notifications / f-notifications-empty.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsProvider);

    return AppScaffold(
      showBack: true,
      title: 'Уведомления',
      padding: EdgeInsets.zero,
      actions: [
        if (items.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Прочитать все',
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Очистить',
            onPressed: () =>
                ref.read(notificationsProvider.notifier).clear(),
          ),
        ],
      ],
      body: items.isEmpty
          ? const AppEmptyState(
              title: 'Уведомлений нет',
              subtitle:
                  'Push-уведомления о согласованиях, выплатах и чатах '
                  'появятся здесь.',
              icon: Icons.notifications_none_rounded,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.x16),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.x8),
              itemBuilder: (_, i) => _NotifTile(
                notification: items[i],
                onTap: () => _handle(context, ref, items[i]),
              ),
            ),
    );
  }

  void _handle(
    BuildContext context,
    WidgetRef ref,
    AppNotification note,
  ) {
    ref.read(notificationsProvider.notifier).markRead(note.id);
    final path = note.routePath;
    if (path != null) context.push(path);
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _styleFor(notification.category);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: notification.read ? AppColors.n0 : AppColors.brandLight,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200, width: 1.5),
          boxShadow: AppShadows.sh1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.r8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.brand,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM · HH:mm', 'ru')
                        .format(notification.receivedAt),
                    style: AppTextStyles.tiny,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, IconData) _styleFor(NotificationRoute route) => switch (route) {
        NotificationRoute.approval => (
            AppColors.brand,
            Icons.rule_rounded,
          ),
        NotificationRoute.payment => (
            AppColors.greenDark,
            Icons.account_balance_wallet_outlined,
          ),
        NotificationRoute.chat => (
            AppColors.brand,
            Icons.chat_bubble_outline_rounded,
          ),
        NotificationRoute.materials => (
            AppColors.purple,
            Icons.inventory_2_outlined,
          ),
        NotificationRoute.stage => (
            AppColors.yellowDot,
            Icons.dashboard_outlined,
          ),
        NotificationRoute.export => (
            AppColors.greenDark,
            Icons.cloud_download_outlined,
          ),
        NotificationRoute.other => (
            AppColors.n500,
            Icons.notifications_none_rounded,
          ),
      };
}
