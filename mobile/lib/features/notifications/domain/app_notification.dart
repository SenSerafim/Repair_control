import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/push/deep_link_router.dart';

part 'app_notification.freezed.dart';

/// Локальная запись о полученном уведомлении. Хранится в памяти
/// NotificationsController'а.
@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String kind,
    required String title,
    required String body,
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
    required DateTime receivedAt,
    @Default(false) bool read,
  }) = _AppNotification;

  static AppNotification fromFcm({
    required String id,
    required String kind,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) =>
      AppNotification(
        id: id,
        kind: kind,
        title: title,
        body: body,
        data: Map<String, dynamic>.from(data ?? const {}),
        receivedAt: DateTime.now(),
      );
}

extension AppNotificationX on AppNotification {
  NotificationRoute get category => DeepLinkRouter.categoryOf(kind);

  String? get routePath => DeepLinkRouter.routeFor(data);
}
