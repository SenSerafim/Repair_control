import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_providers.dart';
import '../../core/storage/offline_queue.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// Глобальный banner — показывается поверх приложения при offline или
/// при наличии отложенных offline-действий, ожидающих синхронизации.
/// Оборачивается вокруг child в MaterialApp.builder.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectivityProvider);
    final isOffline =
        conn.value == ConnectivityStatus.offline && conn.hasValue;

    // Initial pending — берём напрямую (StreamProvider начнёт пушить
    // только при первом enqueue/drain). Подписываемся для последующих.
    final initialPending = ref.read(offlineQueueProvider).pendingCount;
    final pending =
        ref.watch(offlinePendingCountProvider).valueOrNull ?? initialPending;
    final hasPending = pending > 0;

    return Stack(
      children: [
        child,
        if (isOffline || hasPending)
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 8,
            right: 8,
            child: _StatusPill(
              isOffline: isOffline,
              pending: pending,
            ),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOffline, required this.pending});

  final bool isOffline;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final (icon, message, bg) = isOffline
        ? (
            Icons.cloud_off_rounded,
            pending > 0
                ? 'Офлайн · отложено $pending действий'
                : 'Офлайн — изменения сохраняются локально',
            AppColors.n800,
          )
        : (
            Icons.sync_rounded,
            'Синхронизация $pending действий…',
            AppColors.brandDark,
          );
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x6,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadows.sh3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.n0),
            const SizedBox(width: AppSpacing.x6),
            Text(
              message,
              style: AppTextStyles.tiny.copyWith(color: AppColors.n0),
            ),
          ],
        ),
      ),
    );
  }
}
