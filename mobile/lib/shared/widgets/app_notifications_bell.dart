import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/tokens.dart';
import '../../features/notifications/application/notifications_controller.dart';

/// NEWFIX Task 8.1 — переиспользуемый «звоночек с бейджем» для AppBar
/// верхнеуровневых экранов (ТЗ-2 §19, нижняя строка).
///
/// Поведение:
///  · читает [unreadNotificationsCountProvider] (in-memory счётчик
///    непрочитанных уведомлений из `NotificationsController`);
///  · тап открывает `/notifications` через `context.push`;
///  · если непрочитанных нет — бейдж не отрисовывается.
///
/// На экранах с уже существующим «фирменным» хедером (projects/console
/// со своим `_IconBtn`/`_IconShellBtn` в стилизованной плашке) этот
/// виджет НЕ подменяет существующий бейдж — он предназначен для
/// «стандартных» `AppBar.actions` (например, chats/budget).
class AppNotificationsBell extends ConsumerWidget {
  const AppNotificationsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadNotificationsCountProvider);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Уведомления',
          icon: const Icon(PhosphorIconsRegular.bell),
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        if (count > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.redDot,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.n0, width: 1.5),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: AppColors.n0,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
