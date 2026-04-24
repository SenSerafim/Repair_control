import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/app_notification.dart';

/// In-memory список уведомлений. В Sprint 17.1 можно будет добавить
/// drift-persistence, чтобы пережить рестарт приложения.
final notificationsProvider =
    NotifierProvider<NotificationsController, List<AppNotification>>(
  NotificationsController.new,
);

class NotificationsController extends Notifier<List<AppNotification>> {
  static const _uuid = Uuid();

  @override
  List<AppNotification> build() => const [];

  /// Добавляет уведомление (из FcmService.onMessage и initial).
  void push({
    required String kind,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? id,
  }) {
    final note = AppNotification.fromFcm(
      id: id ?? _uuid.v4(),
      kind: kind,
      title: title,
      body: body,
      data: data,
    );
    state = [note, ...state];
  }

  void markRead(String id) {
    state = [
      for (final n in state) if (n.id == id) n.copyWith(read: true) else n,
    ];
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(read: true)];
  }

  void clear() {
    state = const [];
  }

  int get unreadCount => state.where((n) => !n.read).length;
}

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.read).length;
});
