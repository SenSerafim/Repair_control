import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/access/access_guard.dart';
import 'package:repair_control/core/access/domain_actions.dart';
import 'package:repair_control/core/access/system_role.dart';

void main() {
  group('AccessGuard', () {
    test('admin может всё', () {
      for (final a in DomainAction.values) {
        expect(AccessGuard.can(SystemRole.admin, a), isTrue,
            reason: 'admin should have ${a.name}');
      }
    });

    test('customer — финансы и согласования, не управление этапами', () {
      expect(AccessGuard.can(SystemRole.customer, DomainAction.projectCreate),
          isTrue);
      expect(
          AccessGuard.can(SystemRole.customer, DomainAction.approvalDecide),
          isTrue);
      expect(
          AccessGuard.can(SystemRole.customer, DomainAction.stageStart),
          isFalse);
      expect(
          AccessGuard.can(SystemRole.customer, DomainAction.stepPhotoUpload),
          isFalse);
    });

    test('foreman — управление этапами и выплатами мастерам', () {
      expect(
          AccessGuard.can(SystemRole.contractor, DomainAction.stageStart),
          isTrue);
      expect(
          AccessGuard.can(SystemRole.contractor, DomainAction.stagePause),
          isTrue);
      expect(
          AccessGuard.can(
              SystemRole.contractor, DomainAction.financePaymentCreate),
          isTrue);
      expect(
          AccessGuard.can(SystemRole.contractor, DomainAction.projectCreate),
          isFalse);
    });

    test('master — отмечать шаги, загружать фото', () {
      expect(AccessGuard.can(SystemRole.master, DomainAction.stepManage),
          isTrue);
      expect(AccessGuard.can(SystemRole.master, DomainAction.stepPhotoUpload),
          isTrue);
      expect(AccessGuard.can(SystemRole.master, DomainAction.stageStart),
          isFalse);
      expect(
          AccessGuard.can(SystemRole.master, DomainAction.approvalDecide),
          isFalse);
    });

    test('representative — базовые права без делегирования', () {
      expect(AccessGuard.can(SystemRole.representative, DomainAction.chatRead),
          isTrue);
      expect(
          AccessGuard.can(
              SystemRole.representative, DomainAction.approvalDecide),
          isFalse);
      expect(
          AccessGuard.can(
              SystemRole.representative, DomainAction.financePaymentCreate),
          isFalse);
    });

    test('null role — всё запрещено', () {
      for (final a in DomainAction.values) {
        expect(AccessGuard.can(null, a), isFalse);
      }
    });
  });
}
