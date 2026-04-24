import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_providers.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// Глобальный banner — показывается поверх приложения при offline.
/// Оборачивается вокруг child в MaterialApp.builder.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectivityProvider);
    final isOffline =
        conn.value == ConnectivityStatus.offline && conn.hasValue;

    return Stack(
      children: [
        child,
        if (isOffline)
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 8,
            right: 8,
            child: _OfflinePill(),
          ),
      ],
    );
  }
}

class _OfflinePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x6,
        ),
        decoration: BoxDecoration(
          color: AppColors.n800,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadows.sh3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 14,
              color: AppColors.n0,
            ),
            const SizedBox(width: AppSpacing.x6),
            Text(
              'Офлайн — изменения сохраняются локально',
              style: AppTextStyles.tiny.copyWith(color: AppColors.n0),
            ),
          ],
        ),
      ),
    );
  }
}
