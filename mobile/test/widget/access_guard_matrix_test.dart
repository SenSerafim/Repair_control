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

    test('НЕ имеет производственных actions (stage/step/material/tools)', () {
      for (final a in [
        DomainAction.stageManage,
        DomainAction.stageStart,
        DomainAction.stagePause,
        DomainAction.stepManage,
        DomainAction.stepPhotoUpload,
        DomainAction.materialsManage,
        DomainAction.materialFinalize,
        DomainAction.toolsIssue,
        DomainAction.toolsReturn,
        DomainAction.documentDelete,
      ]) {
        expect(AccessGuard.can(SystemRole.customer, a), isFalse,
            reason: 'customer не должен иметь $a');
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
        DomainAction.documentDelete,
      ]) {
        expect(AccessGuard.can(SystemRole.contractor, a), isTrue,
            reason: 'contractor должен иметь $a');
      }
    });

    test('НЕ имеет projectCreate / financePaymentResolve / financeBudgetEdit',
        () {
      for (final a in [
        DomainAction.projectCreate,
        DomainAction.projectEdit,
        DomainAction.projectInviteMember,
        DomainAction.financePaymentResolve,
        DomainAction.financeBudgetEdit,
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
    test('базовые права без делегирования', () {
      for (final a in [
        DomainAction.chatRead,
        DomainAction.chatWrite,
        DomainAction.documentRead,
        DomainAction.financeBudgetView,
        DomainAction.noteManage,
        DomainAction.methodologyRead,
      ]) {
        expect(AccessGuard.can(SystemRole.representative, a), isTrue,
            reason: 'representative должен иметь $a');
      }
    });

    test('НЕ имеет approval/finance write actions без делегирования', () {
      for (final a in [
        DomainAction.approvalDecide,
        DomainAction.financePaymentCreate,
        DomainAction.financePaymentConfirm,
        DomainAction.financePaymentResolve,
        DomainAction.financeBudgetEdit,
        DomainAction.documentWrite,
        DomainAction.documentDelete,
        DomainAction.stageManage,
      ]) {
        expect(AccessGuard.can(SystemRole.representative, a), isFalse,
            reason: 'representative БЕЗ делегирования не должен иметь $a');
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

    test('approvalDecide — customer/contractor/admin (не master/rep)', () {
      expect(AccessGuard.can(SystemRole.customer, DomainAction.approvalDecide),
          isTrue);
      expect(
          AccessGuard.can(SystemRole.contractor, DomainAction.approvalDecide),
          isTrue);
      expect(AccessGuard.can(SystemRole.admin, DomainAction.approvalDecide),
          isTrue);
      expect(AccessGuard.can(SystemRole.master, DomainAction.approvalDecide),
          isFalse);
      expect(
        AccessGuard.can(SystemRole.representative, DomainAction.approvalDecide),
        isFalse,
      );
    });
  });
}
