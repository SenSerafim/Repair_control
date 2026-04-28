import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/notification_settings_controller.dart';
import '../domain/notification_setting.dart';

/// s-notif-settings — 3 секции (Критичные/Важные/Информационные).
/// Критичные disabled с lock-иконкой и тостом «Эти уведомления нельзя
/// отключить».
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationSettingsProvider);

    return AppScaffold(
      showBack: true,
      title: 'Уведомления',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(notificationSettingsProvider),
        ),
        data: (items) {
          final byPriority = <NotificationPriority, List<NotificationSetting>>{
            for (final p in NotificationPriority.values)
              p: <NotificationSetting>[],
          };
          for (final s in items) {
            byPriority[s.priority]!.add(s);
          }
          // В дизайне 3 секции; «normal» сливаем с «low» как «Информационные».
          final critical =
              byPriority[NotificationPriority.critical] ?? const <NotificationSetting>[];
          final important =
              byPriority[NotificationPriority.high] ?? const <NotificationSetting>[];
          final info = <NotificationSetting>[
            ...?byPriority[NotificationPriority.normal],
            ...?byPriority[NotificationPriority.low],
          ];

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
            children: [
              if (critical.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Критичные',
                  hint: 'Нельзя отключить',
                  icon: PhosphorIconsFill.lock,
                ),
                const SizedBox(height: AppSpacing.x6),
                _SettingsGroup(
                  items: critical,
                  onToggle: (s, v) => _toggle(context, ref, s, v),
                ),
                const SizedBox(height: AppSpacing.x16),
              ],
              if (important.isNotEmpty) ...[
                const _SectionHeader(title: 'Важные'),
                const SizedBox(height: AppSpacing.x6),
                _SettingsGroup(
                  items: important,
                  onToggle: (s, v) => _toggle(context, ref, s, v),
                ),
                const SizedBox(height: AppSpacing.x16),
              ],
              if (info.isNotEmpty) ...[
                const _SectionHeader(title: 'Информационные'),
                const SizedBox(height: AppSpacing.x6),
                _SettingsGroup(
                  items: info,
                  onToggle: (s, v) => _toggle(context, ref, s, v),
                ),
                const SizedBox(height: AppSpacing.x16),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    NotificationSetting s,
    bool enabled,
  ) async {
    if (s.critical) {
      AppToast.show(
        context,
        message: 'Эти уведомления нельзя отключить',
      );
      return;
    }
    await ref
        .read(notificationSettingsProvider.notifier)
        .toggle(s, pushEnabled: enabled);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.hint, this.icon});

  final String title;
  final String? hint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x4,
        AppSpacing.x4,
        AppSpacing.x4,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AppColors.n400),
            const SizedBox(width: 4),
          ],
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.n400,
              letterSpacing: 0.6,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(width: 6),
            Text(
              '· $hint',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.n400,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items, required this.onToggle});

  final List<NotificationSetting> items;
  final void Function(NotificationSetting, bool) onToggle;

  @override
  Widget build(BuildContext context) {
    return AppMenuGroup(
      children: [
        for (final s in items)
          AppMenuRow(
            label: notificationKindLabels[s.kind] ?? s.kind,
            sub: _subFor(s),
            disabled: s.critical,
            trailing: _Toggle(
              value: s.pushEnabled || s.critical,
              disabled: s.critical,
              onChanged: (v) => onToggle(s, v),
            ),
          ),
      ],
    );
  }

  String? _subFor(NotificationSetting s) {
    if (s.critical) return 'Критичное · нельзя отключить';
    return null;
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.value,
    required this.disabled,
    required this.onChanged,
  });

  final bool value;
  final bool disabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.6 : 1.0,
      child: Switch.adaptive(
        value: value,
        onChanged: disabled ? null : onChanged,
        activeColor: AppColors.brand,
        activeTrackColor: AppColors.brand.withValues(alpha: 0.4),
      ),
    );
  }
}
