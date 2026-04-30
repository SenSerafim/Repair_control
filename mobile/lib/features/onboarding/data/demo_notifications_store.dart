import 'package:logger/logger.dart';

import '../../notifications/data/notifications_store.dart';
import '../../notifications/domain/app_notification.dart';
import 'demo_data.dart';

/// Mock-хранилище уведомлений для демо-тура. Не пишет на диск, не читает с диска —
/// возвращает [DemoData.notifications]. См. `DemoProjectsRepository`.
class DemoNotificationsStore extends NotificationsStore {
  DemoNotificationsStore() : super(logger: Logger(level: Level.off));

  @override
  Future<List<AppNotification>> load() async => DemoData.notifications;

  @override
  Future<void> save(List<AppNotification> items) async {}
}
