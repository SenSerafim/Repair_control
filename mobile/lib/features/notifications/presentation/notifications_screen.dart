import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/push/deep_link_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../onboarding/presentation/widgets/tour_anchor.dart';
import '../application/notifications_controller.dart';
import '../domain/app_notification.dart';
import '../domain/notification_l10n.dart';

/// `f-notifications` / `f-notifications-empty` (`Кластер F`).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationRoute? _filter;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(notificationsProvider);
    final filtered = _filter == null
        ? items
        : items.where((n) => n.category == _filter).toList();

    return AppScaffold(
      showBack: true,
      // Если попали сюда через deep-link / push-уведомление, history стека
      // навигатора пуст — `maybePop` молча отказывает. В этом случае
      // отправляем пользователя на /home, чтобы кнопка «Назад» гарантированно
      // что-то делала. Pop оборачиваем в try/catch — go_router бросает
      // assertion, если в этом же кадре стек навигатора уже изменился
      // (множественные тапы / ре-build после refresh).
      onBack: () => _onBack(context),
      title: 'Уведомления',
      padding: EdgeInsets.zero,
      actions: [
        if (items.any((n) => !n.read))
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Прочитать все',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ),
          ),
      ],
      body: Column(
        children: [
          if (items.isNotEmpty)
            _TypeFilter(
              selected: _filter,
              onChanged: (v) => setState(() => _filter = v),
            ),
          Expanded(
            child: items.isEmpty
                ? const AppEmptyState(
                    title: 'Нет уведомлений',
                    subtitle:
                        'Здесь будут отображаться все уведомления по вашим '
                        'проектам',
                    icon: Icons.notifications_none_rounded,
                  )
                : filtered.isEmpty
                    ? const AppEmptyState(
                        title: 'Нет уведомлений в категории',
                        icon: Icons.filter_alt_outlined,
                      )
                    : _NotifList(
                        items: filtered,
                        onTap: (n) => _handle(context, ref, n),
                      ),
          ),
        ],
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

  void _onBack(BuildContext context) {
    if (_popping) return;
    _popping = true;
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    } catch (_) {
      // Навигатор в transition (двойной тап) или go_router нашёл коллизию
      // ключей у страниц — fallback на /home гарантирует, что пользователь
      // всё равно уйдёт с экрана.
      context.go(AppRoutes.home);
    } finally {
      // Снимаем гард после frame, чтобы повторный тап в этом же кадре
      // не пропустился.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _popping = false;
      });
    }
  }

  bool _popping = false;
}

class _TypeFilter extends StatelessWidget {
  const _TypeFilter({required this.selected, required this.onChanged});

  final NotificationRoute? selected;
  final ValueChanged<NotificationRoute?> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <AppFilterPillSpec>[
      const AppFilterPillSpec(id: '__all__', label: 'Все'),
      const AppFilterPillSpec(id: 'approval', label: 'Согласования'),
      const AppFilterPillSpec(id: 'stage', label: 'Дедлайны'),
      const AppFilterPillSpec(id: 'payment', label: 'Выплаты'),
      const AppFilterPillSpec(id: 'materials', label: 'Споры'),
      const AppFilterPillSpec(id: 'chat', label: 'Чаты'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(bottom: BorderSide(color: AppColors.n100)),
      ),
      child: AppFilterPillBar(
        chips: chips,
        activeId: selected?.name ?? '__all__',
        onSelect: (id) {
          if (id == '__all__') {
            onChanged(null);
          } else {
            onChanged(NotificationRoute.values
                .firstWhere((r) => r.name == id, orElse: () => NotificationRoute.other));
          }
        },
      ),
    );
  }
}

class _NotifList extends StatelessWidget {
  const _NotifList({required this.items, required this.onTap});

  final List<AppNotification> items;
  final ValueChanged<AppNotification> onTap;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    String? lastDayKey;
    var firstTile = true;
    for (final n in items) {
      final dayKey = _dayKey(n.receivedAt);
      if (dayKey != lastDayKey) {
        children.add(_DateSeparator(label: _dayLabel(n.receivedAt)));
        lastDayKey = dayKey;
      }
      final tile = _NotifTile(notification: n, onTap: () => onTap(n));
      children
        ..add(
          firstTile
              ? TourAnchor(id: 'notifications.first_item', child: tile)
              : tile,
        )
        ..add(const Divider(
          height: 1,
          thickness: 1,
          indent: 68,
          color: AppColors.n100,
        ));
      firstTile = false;
    }
    return ListView(
      padding: EdgeInsets.zero,
      children: children,
    );
  }

  String _dayKey(DateTime t) =>
      DateFormat('yyyy-MM-dd').format(t);

  String _dayLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tDay = DateTime(t.year, t.month, t.day);
    final diff = today.difference(tDay).inDays;
    if (diff == 0) return 'СЕГОДНЯ';
    if (diff == 1) return 'ВЧЕРА';
    return DateFormat('d MMMM', 'ru').format(t).toUpperCase();
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.n200,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.n400,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.n200,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _styleFor(notification.category);
    final title = renderNotifTitle(
      notification.kind,
      notification.data,
      fallback: notification.title,
    );
    final bodyText = renderNotifBody(
      notification.kind,
      notification.data,
      fallback: notification.body,
    );
    final mainText = (title.isEmpty ? notification.title : title)
        + (bodyText.isEmpty ? '' : '\n${bodyText.isEmpty ? notification.body : bodyText}');
    return Material(
      color: notification.read ? AppColors.n0 : AppColors.brandLight,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Icon(icon, color: fg, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n800,
                        height: 1.5,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(notification.receivedAt),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays == 1) return 'вчера, ${DateFormat('HH:mm', 'ru').format(t)}';
    return DateFormat('d MMM, HH:mm', 'ru').format(t);
  }

  (Color, Color, IconData) _styleFor(NotificationRoute route) =>
      switch (route) {
        NotificationRoute.approval => (
            AppColors.purpleBg,
            AppColors.purple,
            Icons.rule_rounded,
          ),
        NotificationRoute.payment => (
            AppColors.greenLight,
            AppColors.greenDark,
            Icons.account_balance_wallet_outlined,
          ),
        NotificationRoute.chat => (
            AppColors.brandLight,
            AppColors.brand,
            Icons.chat_bubble_outline_rounded,
          ),
        NotificationRoute.materials => (
            AppColors.redBg,
            AppColors.redDot,
            Icons.help_outline_rounded,
          ),
        NotificationRoute.stage => (
            AppColors.yellowBg,
            const Color(0xFFD97706),
            Icons.access_time_rounded,
          ),
        NotificationRoute.document => (
            AppColors.brandLight,
            AppColors.brand,
            Icons.insert_drive_file_outlined,
          ),
        NotificationRoute.export => (
            AppColors.greenLight,
            AppColors.greenDark,
            Icons.cloud_download_outlined,
          ),
        NotificationRoute.announcement => (
            AppColors.brandLight,
            AppColors.brand,
            Icons.campaign_outlined,
          ),
        NotificationRoute.other => (
            AppColors.n100,
            AppColors.n500,
            Icons.notifications_none_rounded,
          ),
      };
}
