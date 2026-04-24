import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';
import '../domain/notification_setting.dart';

final notificationSettingsProvider = AsyncNotifierProvider<
    NotificationSettingsController, List<NotificationSetting>>(
  NotificationSettingsController.new,
);

class NotificationSettingsController
    extends AsyncNotifier<List<NotificationSetting>> {
  @override
  Future<List<NotificationSetting>> build() async {
    final repo = ref.read(profileRepositoryProvider);
    return repo.listNotificationSettings();
  }

  /// Optimistic toggle. Критичные — запрещены.
  Future<void> toggle(
    NotificationSetting setting, {
    required bool pushEnabled,
  }) async {
    if (setting.critical) return; // нельзя отключать критичные
    final current = state.value ?? [];
    state = AsyncData(
      current
          .map(
            (s) => s.kind == setting.kind
                ? s.copyWith(pushEnabled: pushEnabled)
                : s,
          )
          .toList(),
    );
    try {
      await ref.read(profileRepositoryProvider).patchNotificationSetting(
            kind: setting.kind,
            pushEnabled: pushEnabled,
          );
    } on ProfileException {
      // Откат оптимистичного UI
      state = AsyncData(current);
    }
  }
}
