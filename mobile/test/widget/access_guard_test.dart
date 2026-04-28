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

    test('customer — владелец, имеет всё внутри проекта', () {
      // По новой матрице customer = всё (в том числе этапы и фото).
      // Не имеет только глобальной правки методички (это admin-only).
      expect(AccessGuard.can(SystemRole.customer, DomainAction.projectCreate),
          isTrue);
      expect(AccessGuard.can(SystemRole.customer, DomainAction.approvalDecide),
          isTrue);
      expect(AccessGuard.can(SystemRole.customer, DomainAction.stageStart),
          isTrue);
      expect(
          AccessGuard.can(SystemRole.customer, DomainAction.stepPhotoUpload),
          isTrue);
      expect(AccessGuard.can(SystemRole.customer, DomainAction.documentDelete),
          isTrue);
      expect(AccessGuard.can(SystemRole.customer, DomainAction.methodologyEdit),
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

    test('representative — почти всё, кроме необратимого', () {
      // Представитель действует от имени заказчика — имеет основные
      // полномочия. Бэкенд проверяет конкретные representativeRights.
      expect(AccessGuard.can(SystemRole.representative, DomainAction.chatRead),
          isTrue);
      expect(
          AccessGuard.can(
              SystemRole.representative, DomainAction.approvalDecide),
          isTrue);
      expect(
          AccessGuard.can(
              SystemRole.representative, DomainAction.financePaymentCreate),
          isTrue);
      expect(
          AccessGuard.can(SystemRole.representative, DomainAction.stageManage),
          isTrue);
      // Необратимые действия — нет.
      expect(
          AccessGuard.can(
              SystemRole.representative, DomainAction.projectArchive),
          isFalse);
      expect(
          AccessGuard.can(
              SystemRole.representative, DomainAction.financePaymentResolve),
          isFalse);
      expect(
          AccessGuard.can(
              SystemRole.representative, DomainAction.documentDelete),
          isFalse);
    });

    test('null role — всё запрещено', () {
      for (final a in DomainAction.values) {
        expect(AccessGuard.can(null, a), isFalse);
      }
    });
  });
}
