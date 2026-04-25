import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/notifications_store.dart';
import '../domain/app_notification.dart';

/// Список уведомлений с persist на диск (NotificationsStore).
/// Восстанавливается при старте приложения, ограничен 200 записями.
final notificationsProvider =
    NotifierProvider<NotificationsController, List<AppNotification>>(
  NotificationsController.new,
);

class NotificationsController extends Notifier<List<AppNotification>> {
  static const _uuid = Uuid();

  NotificationsStore get _store => ref.read(notificationsStoreProvider);

  @override
  List<AppNotification> build() {
    // Асинхронная загрузка с диска — build() не должен возвращать Future,
    // поэтому стартуем с пустого списка и подменяем после load().
    Future.microtask(_hydrate);
    return const [];
  }

  Future<void> _hydrate() async {
    final loaded = await _store.load();
    if (loaded.isEmpty) return;
    state = loaded;
  }

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
    _persist();
  }

  void markRead(String id) {
    state = [
      for (final n in state) if (n.id == id) n.copyWith(read: true) else n,
    ];
    _persist();
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(read: true)];
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }

  int get unreadCount => state.where((n) => !n.read).length;

  void _persist() {
    unawaited(_store.save(state));
  }
}

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.read).length;
});
