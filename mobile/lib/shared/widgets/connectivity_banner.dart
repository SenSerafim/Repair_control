import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_providers.dart';
import '../../core/storage/offline_queue.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// Глобальный banner — показывается поверх приложения при offline или
/// при наличии отложенных offline-действий, ожидающих синхронизации.
/// Оборачивается вокруг child в MaterialApp.builder.
///
/// Серафим 08.06.2026: пользователь может свернуть баннер (× с правой
/// стороны) — остаётся компактная точка-индикатор в углу, которую можно
/// тапнуть, чтобы развернуть обратно. На смену состояния (online ⇄ offline
/// или появление новых pending) сворачивание сбрасывается.
class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner> {
  bool _collapsed = false;
  bool? _lastOffline;
  int _lastPending = 0;

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectivityProvider);
    final isOffline = conn.value == ConnectivityStatus.offline && conn.hasValue;

    final initialPending = ref.read(offlineQueueProvider).pendingCount;
    final pending =
        ref.watch(offlinePendingCountProvider).valueOrNull ?? initialPending;
    final hasPending = pending > 0;

    // Сбрасываем сворачивание при смене состояния, чтобы пользователь
    // увидел новое уведомление (offline → online, выросла очередь, и т.п.).
    if (_lastOffline != null &&
        (isOffline != _lastOffline || pending > _lastPending)) {
      _collapsed = false;
    }
    _lastOffline = isOffline;
    _lastPending = pending;

    final visible = isOffline || hasPending;

    return Stack(
      children: [
        widget.child,
        if (visible)
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 8,
            right: 8,
            child: _collapsed
                ? Align(
                    alignment: Alignment.topRight,
                    child: _CollapsedDot(
                      isOffline: isOffline,
                      pending: pending,
                      onTap: () => setState(() => _collapsed = false),
                    ),
                  )
                : _StatusPill(
                    isOffline: isOffline,
                    pending: pending,
                    onClose: () => setState(() => _collapsed = true),
                  ),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.isOffline,
    required this.pending,
    required this.onClose,
  });

  final bool isOffline;
  final int pending;
  final VoidCallback onClose;

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
            Flexible(
              child: Text(
                message,
                style: AppTextStyles.tiny.copyWith(color: AppColors.n0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.x8),
            GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.n0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapsedDot extends StatelessWidget {
  const _CollapsedDot({
    required this.isOffline,
    required this.pending,
    required this.onTap,
  });

  final bool isOffline;
  final int pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isOffline ? AppColors.n800 : AppColors.brandDark;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: AppShadows.sh3,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOffline ? Icons.cloud_off_rounded : Icons.sync_rounded,
                size: 12,
                color: AppColors.n0,
              ),
              if (pending > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '$pending',
                  style: AppTextStyles.tiny.copyWith(color: AppColors.n0),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
