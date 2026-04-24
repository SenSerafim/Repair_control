import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/profile/domain/notification_setting.dart';

void main() {
  group('NotificationPriority.fromString', () {
    test('все известные значения', () {
      expect(
        NotificationPriority.fromString('critical'),
        NotificationPriority.critical,
      );
      expect(
        NotificationPriority.fromString('high'),
        NotificationPriority.high,
      );
      expect(
        NotificationPriority.fromString('normal'),
        NotificationPriority.normal,
      );
      expect(
        NotificationPriority.fromString('low'),
        NotificationPriority.low,
      );
    });

    test('неизвестное → normal', () {
      expect(
        NotificationPriority.fromString('wtf'),
        NotificationPriority.normal,
      );
    });

    test('null → normal', () {
      expect(
        NotificationPriority.fromString(null),
        NotificationPriority.normal,
      );
    });
  });

  group('NotificationSetting.parse', () {
    test('critical из бэкенда', () {
      final s = NotificationSetting.parse({
        'kind': 'stage_overdue',
        'pushEnabled': true,
        'priority': 'critical',
        'critical': true,
      });
      expect(s.critical, isTrue);
      expect(s.priority, NotificationPriority.critical);
      expect(s.kind, 'stage_overdue');
    });
  });

  group('notificationKindLabels', () {
    test('имеет ожидаемые ключи', () {
      expect(notificationKindLabels['stage_overdue'], isNotNull);
      expect(notificationKindLabels['chat_message'], isNotNull);
      expect(notificationKindLabels['payment_created'], isNotNull);
    });
  });
}
