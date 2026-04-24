import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/notification_settings_controller.dart';
import '../domain/notification_setting.dart';

/// s-notif-settings — список уведомлений с toggle. Критичные disabled.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationSettingsProvider);

    return AppScaffold(
      showBack: true,
      title: 'Уведомления',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(notificationSettingsProvider),
        ),
        data: (items) {
          final byPriority = <NotificationPriority, List<NotificationSetting>>{
            for (final p in NotificationPriority.values) p: <NotificationSetting>[],
          };
          for (final s in items) {
            byPriority[s.priority]!.add(s);
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x12),
            children: [
              for (final priority in NotificationPriority.values)
                if (byPriority[priority]!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x4,
                      vertical: AppSpacing.x8,
                    ),
                    child: Text(
                      priority.displayName,
                      style: AppTextStyles.micro,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.n0,
                      borderRadius: BorderRadius.circular(AppRadius.r20),
                      boxShadow: AppShadows.sh1,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0;
                            i < byPriority[priority]!.length;
                            i++) ...[
                          _SettingRow(
                            setting: byPriority[priority]![i],
                            onToggle: (enabled) => ref
                                .read(notificationSettingsProvider.notifier)
                                .toggle(
                                  byPriority[priority]![i],
                                  pushEnabled: enabled,
                                ),
                          ),
                          if (i < byPriority[priority]!.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.x16,
                              ),
                              child: Divider(
                                height: 1,
                                color: AppColors.n100,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x16),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.setting,
    required this.onToggle,
  });

  final NotificationSetting setting;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final label = notificationKindLabels[setting.kind] ?? setting.kind;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.subtitle),
                if (setting.critical) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Критичное — нельзя отключить',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.redText),
                  ),
                ],
              ],
            ),
          ),
          if (setting.critical)
            const Tooltip(
              message: 'Критичные уведомления нельзя отключить',
              child: Icon(
                Icons.lock_rounded,
                size: 18,
                color: AppColors.n400,
              ),
            ),
          const SizedBox(width: AppSpacing.x6),
          Switch(
            value: setting.pushEnabled || setting.critical,
            onChanged: setting.critical ? null : onToggle,
            activeTrackColor: AppColors.brand,
          ),
        ],
      ),
    );
  }
}
