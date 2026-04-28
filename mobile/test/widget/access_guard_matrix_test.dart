import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/access/access_guard.dart';
import 'package:repair_control/core/access/domain_actions.dart';
import 'package:repair_control/core/access/system_role.dart';

/// Phase 11: полная RBAC матрица (4 роли × ключевые actions).
///
/// Зеркало бэка: `backend/libs/rbac/src/rbac.types.ts`. Любое расхождение
/// между mobile и backend здесь упадёт при контрактном test'е.
void main() {
  group('AccessGuard.can — null role', () {
    test('null role → всё запрещено', () {
      for (final action in DomainAction.values) {
        expect(AccessGuard.can(null, action), isFalse,
            reason: 'null role не должен иметь $action');
      }
    });
  });

  group('AccessGuard — admin', () {
    test('admin может всё', () {
      for (final action in DomainAction.values) {
        expect(AccessGuard.can(SystemRole.admin, action), isTrue,
            reason: 'admin не имеет $action');
      }
    });
  });

  group('AccessGuard — customer (заказчик)', () {
    test('может projectCreate / approvalDecide / financePaymentResolve', () {
      for (final a in [
        DomainAction.projectCreate,
        DomainAction.projectEdit,
        DomainAction.projectInviteMember,
        DomainAction.approvalDecide,
        DomainAction.financePaymentCreate,
        DomainAction.financePaymentConfirm,
        DomainAction.financePaymentDispute,
        DomainAction.financePaymentResolve,
        DomainAction.financeBudgetView,
        DomainAction.financeBudgetEdit,
        DomainAction.documentRead,
        DomainAction.documentWrite,
      ]) {
        expect(AccessGuard.can(SystemRole.customer, a), isTrue,
            reason: 'customer должен иметь $a');
      }
    });

    test('заказчик имеет полный доступ к производственным actions', () {
      // Заказчик — владелец проекта: этапы, шаги, материалы, документы.
      // Инструмент (`tools.*`) и самозакуп (`selfpurchase.create`) НЕ его
      // зона — backend RBAC явно блокирует, см. ТЗ §1.4 / gaps §6.1.
      for (final a in [
        DomainAction.stageManage,
        DomainAction.stageStart,
        DomainAction.stagePause,
        DomainAction.stepManage,
        DomainAction.stepPhotoUpload,
        DomainAction.materialsManage,
        DomainAction.materialFinalize,
        DomainAction.documentDelete,
      ]) {
        expect(AccessGuard.can(SystemRole.customer, a), isTrue,
            reason: 'customer должен иметь $a');
      }
    });

    test('заказчик НЕ имеет инструмента / самозакупа (ТЗ §1.4)', () {
      for (final a in [
        DomainAction.toolsManage,
        DomainAction.toolsIssue,
        DomainAction.toolsReturn,
        DomainAction.selfPurchaseCreate,
      ]) {
        expect(AccessGuard.can(SystemRole.customer, a), isFalse,
            reason: 'customer не должен иметь $a (бекенд вернёт 403)');
      }
    });
  });

  group('AccessGuard — contractor (бригадир)', () {
    test('управляет этапами / шагами / материалами / выплатами', () {
      for (final a in [
        DomainAction.stageManage,
        DomainAction.stageStart,
        DomainAction.stagePause,
        DomainAction.stepManage,
        DomainAction.stepPhotoUpload,
        DomainAction.approvalRequest,
        DomainAction.approvalDecide, // одобряет master-шаги
        DomainAction.financePaymentCreate,
        DomainAction.financePaymentConfirm,
        DomainAction.financePaymentDispute,
        DomainAction.materialsManage,
        DomainAction.materialFinalize,
        DomainAction.toolsManage,
        DomainAction.toolsIssue,
        DomainAction.toolsReturn,
        DomainAction.chatCreateGroup,
        DomainAction.chatToggleCustomerVisibility,
        DomainAction.chatModerate,
        DomainAction.documentWrite,
        DomainAction.projectInviteMember, // приглашает мастеров
      ]) {
        expect(AccessGuard.can(SystemRole.contractor, a), isTrue,
            reason: 'contractor должен иметь $a');
      }
    });

    test('НЕ имеет projectCreate / projectArchive / payment.resolve / '
        'budgetEdit / documentDelete', () {
      for (final a in [
        DomainAction.projectCreate,
        DomainAction.projectEdit,
        DomainAction.projectArchive,
        DomainAction.financePaymentResolve,
        DomainAction.financeBudgetEdit,
        DomainAction.documentDelete,
      ]) {
        expect(AccessGuard.can(SystemRole.contractor, a), isFalse,
            reason: 'contractor не должен иметь $a');
      }
    });
  });

  group('AccessGuard — master (мастер)', () {
    test('может только свой step / photo / chat-write / mat-self-buy', () {
      for (final a in [
        DomainAction.stepManage,
        DomainAction.stepPhotoUpload,
        DomainAction.approvalRequest,
        DomainAction.financePaymentConfirm,
        DomainAction.financePaymentDispute,
        DomainAction.selfPurchaseCreate,
        DomainAction.toolsReturn,
        DomainAction.chatRead,
        DomainAction.chatWrite,
        DomainAction.documentRead,
      ]) {
        expect(AccessGuard.can(SystemRole.master, a), isTrue,
            reason: 'master должен иметь $a');
      }
    });

    test('НЕ имеет stage-management / payment-create / approval-decide', () {
      for (final a in [
        DomainAction.stageManage,
        DomainAction.stageStart,
        DomainAction.stagePause,
        DomainAction.financePaymentCreate,
        DomainAction.financePaymentResolve,
        DomainAction.approvalDecide,
        DomainAction.materialsManage,
        DomainAction.toolsIssue,
        DomainAction.chatCreateGroup,
        DomainAction.documentWrite,
        DomainAction.documentDelete,
        DomainAction.projectInviteMember,
      ]) {
        expect(AccessGuard.can(SystemRole.master, a), isFalse,
            reason: 'master не должен иметь $a');
      }
    });
  });

  group('AccessGuard — representative', () {
    test('почти все права (действует от имени заказчика)', () {
      // Базовый набор — представитель имеет почти всё.
      for (final a in [
        DomainAction.chatRead,
        DomainAction.chatWrite,
        DomainAction.documentRead,
        DomainAction.documentWrite,
        DomainAction.financeBudgetView,
        DomainAction.financePaymentCreate,
        DomainAction.financePaymentConfirm,
        DomainAction.approvalDecide,
        DomainAction.stageManage,
        DomainAction.stepManage,
        DomainAction.materialsManage,
        DomainAction.toolsManage,
        DomainAction.projectInviteMember,
        DomainAction.noteManage,
        DomainAction.methodologyRead,
      ]) {
        expect(AccessGuard.can(SystemRole.representative, a), isTrue,
            reason: 'representative должен иметь $a');
      }
    });

    test('НЕ имеет необратимых действий без делегирования', () {
      // Несколько ключевых необратимых: архивация проекта, удаление
      // документов, окончательный resolve выплат, редактирование бюджета.
      for (final a in [
        DomainAction.projectArchive,
        DomainAction.financePaymentResolve,
        DomainAction.financeBudgetEdit,
        DomainAction.documentDelete,
      ]) {
        expect(AccessGuard.can(SystemRole.representative, a), isFalse,
            reason: 'representative без делегирования не должен иметь $a');
      }
    });
  });

  group('Кросс-роль: финансы', () {
    test('financePaymentResolve — только customer + admin', () {
      expect(
        AccessGuard.can(SystemRole.customer, DomainAction.financePaymentResolve),
        isTrue,
      );
      expect(
        AccessGuard.can(SystemRole.admin, DomainAction.financePaymentResolve),
        isTrue,
      );
      expect(
        AccessGuard.can(
            SystemRole.contractor, DomainAction.financePaymentResolve),
        isFalse,
      );
      expect(
        AccessGuard.can(SystemRole.master, DomainAction.financePaymentResolve),
        isFalse,
      );
      expect(
        AccessGuard.can(
            SystemRole.representative, DomainAction.financePaymentResolve),
        isFalse,
      );
    });

    test('approvalDecide — customer/contractor/representative/admin (не master)',
        () {
      expect(AccessGuard.can(SystemRole.customer, DomainAction.approvalDecide),
          isTrue);
      expect(
          AccessGuard.can(SystemRole.contractor, DomainAction.approvalDecide),
          isTrue);
      expect(
        AccessGuard.can(SystemRole.representative, DomainAction.approvalDecide),
        isTrue,
      );
      expect(AccessGuard.can(SystemRole.admin, DomainAction.approvalDecide),
          isTrue);
      expect(AccessGuard.can(SystemRole.master, DomainAction.approvalDecide),
          isFalse);
    });
  });
}
