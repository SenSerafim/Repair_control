import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/access/access_guard.dart';
import 'package:repair_control/core/access/domain_actions.dart';
import 'package:repair_control/core/access/system_role.dart';

void main() {
  group('AccessGuard', () {
    test('admin может всё', () {
      for (final a in DomainAction.values) {
        expect(
          AccessGuard.can(SystemRole.admin, a),
          isTrue,
          reason: 'admin should have ${a.name}',
        );
      }
    });

    test('customer — владелец, имеет всё внутри проекта', () {
      // По новой матрице customer = всё (в том числе этапы и фото).
      // Не имеет только глобальной правки методички (это admin-only).
      expect(
        AccessGuard.can(SystemRole.customer, DomainAction.projectCreate),
        isTrue,
      );
      expect(
        AccessGuard.can(SystemRole.customer, DomainAction.approvalDecide),
        isTrue,
      );
      expect(
        AccessGuard.can(SystemRole.customer, DomainAction.stageStart),
        isTrue,
      );
      expect(
        AccessGuard.can(SystemRole.customer, DomainAction.stepPhotoUpload),
        isTrue,
      );
      expect(
        AccessGuard.can(SystemRole.customer, DomainAction.documentDelete),
        isTrue,
      );
      expect(
        AccessGuard.can(SystemRole.customer, DomainAction.methodologyEdit),
        isFalse,
      );
    });

    test('foreman — управление этапами и выплатами мастерам', () {
      expect(
        AccessGuard.can(SystemRole.contractor, DomainAction.stageStart),
        isTrue,
      );
      expect(
        AccessGuard.can(SystemRole.contractor, DomainAction.stagePause),
        isTrue,
      );
      expect(
        AccessGuard.can(
          SystemRole.contractor,
          DomainAction.financePaymentCreate,
        ),
        isTrue,
      );
      expect(
        AccessGuard.can(SystemRole.contractor, DomainAction.projectCreate),
        isFalse,
      );
    });

    test('master — отмечать шаги, загружать фото', () {
      expect(
        AccessGuard.can(SystemRole.master, DomainAction.stepManage),
        isTrue,
      );
      expect(
        AccessGuard.can(SystemRole.master, DomainAction.stepPhotoUpload),
        isTrue,
      );
      expect(
        AccessGuard.can(SystemRole.master, DomainAction.stageStart),
        isFalse,
      );
      expect(
        AccessGuard.can(SystemRole.master, DomainAction.approvalDecide),
        isFalse,
      );
    });

    test('representative — read-only baseline (П7.3, раунд 2026-05-03)', () {
      // По умолчанию представитель только смотрит и пишет в чат.
      // Любое write-действие выдаётся через RepresentativeRights и
      // проверяется через canInProjectProvider.
      expect(
        AccessGuard.can(SystemRole.representative, DomainAction.chatRead),
        isTrue,
      );
      expect(
        AccessGuard.can(SystemRole.representative, DomainAction.chatWrite),
        isTrue,
      );
      expect(
        AccessGuard.can(
          SystemRole.representative,
          DomainAction.financeBudgetView,
        ),
        isTrue,
      );
      // Write-actions — без делегирования НЕТ.
      expect(
        AccessGuard.can(SystemRole.representative, DomainAction.approvalDecide),
        isFalse,
      );
      expect(
        AccessGuard.can(
          SystemRole.representative,
          DomainAction.financePaymentCreate,
        ),
        isFalse,
      );
      expect(
        AccessGuard.can(SystemRole.representative, DomainAction.stageManage),
        isFalse,
      );
      // Архивирование — никогда (П7.1, П10.4).
      expect(
        AccessGuard.can(SystemRole.representative, DomainAction.projectArchive),
        isFalse,
      );
      expect(
        AccessGuard.can(
          SystemRole.representative,
          DomainAction.financePaymentResolve,
        ),
        isFalse,
      );
      expect(
        AccessGuard.can(SystemRole.representative, DomainAction.documentDelete),
        isFalse,
      );
    });

    test('null role — всё запрещено', () {
      for (final a in DomainAction.values) {
        expect(AccessGuard.can(null, a), isFalse);
      }
    });
  });
}
