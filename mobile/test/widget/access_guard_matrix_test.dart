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
        expect(
          AccessGuard.can(null, action),
          isFalse,
          reason: 'null role не должен иметь $action',
        );
      }
    });
  });

  group('AccessGuard — admin', () {
    test('admin может всё', () {
      for (final action in DomainAction.values) {
        expect(
          AccessGuard.can(SystemRole.admin, action),
          isTrue,
          reason: 'admin не имеет $action',
        );
      }
    });
  });

  group('AccessGuard — customer (заказчик)', () {
    test('может projectCreate / approvalDecide / payments', () {
      for (final a in [
        DomainAction.projectCreate,
        DomainAction.projectEdit,
        DomainAction.projectInviteMember,
        DomainAction.approvalDecide,
        DomainAction.financePaymentCreateAdvance,
        DomainAction.financeBudgetView,
        DomainAction.financeBudgetEdit,
        DomainAction.documentRead,
        DomainAction.documentWrite,
      ]) {
        expect(
          AccessGuard.can(SystemRole.customer, a),
          isTrue,
          reason: 'customer должен иметь $a',
        );
      }
    });

    test('заказчик НЕ имеет права distribute (это эксклюзив бригадира)', () {
      expect(
        AccessGuard.can(
          SystemRole.customer,
          DomainAction.financePaymentDistribute,
        ),
        isFalse,
        reason: 'customer не должен иметь distribute — он не получатель аванса',
      );
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
        DomainAction.documentDelete,
      ]) {
        expect(
          AccessGuard.can(SystemRole.customer, a),
          isTrue,
          reason: 'customer должен иметь $a',
        );
      }
    });

    test(
      'заказчик не создаёт самозакуп (но инструмент — self-custody модель доступна всем)',
      () {
        for (final a in [DomainAction.selfPurchaseCreate]) {
          expect(
            AccessGuard.can(SystemRole.customer, a),
            isFalse,
            reason: 'customer не должен иметь $a (бекенд вернёт 403)',
          );
        }
      },
    );
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
        DomainAction.financePaymentDistribute,
        DomainAction.materialsManage,
        DomainAction.toolsViewProject,
        DomainAction.toolsAddToProject,
        DomainAction.toolsClaim,
        DomainAction.chatCreateGroup,
        DomainAction.chatToggleCustomerVisibility,
        DomainAction.chatModerate,
        DomainAction.documentWrite,
        DomainAction.projectInviteMember, // приглашает мастеров
      ]) {
        expect(
          AccessGuard.can(SystemRole.contractor, a),
          isTrue,
          reason: 'contractor должен иметь $a',
        );
      }
    });

    test('НЕ имеет projectCreate / projectArchive / createAdvance / '
        'budgetEdit / documentDelete', () {
      for (final a in [
        DomainAction.projectCreate,
        DomainAction.projectEdit,
        DomainAction.projectArchive,
        // Бригадир НЕ создаёт общий аванс из бюджета — это эксклюзив заказчика.
        DomainAction.financePaymentCreateAdvance,
        DomainAction.financeBudgetEdit,
        DomainAction.documentDelete,
      ]) {
        expect(
          AccessGuard.can(SystemRole.contractor, a),
          isFalse,
          reason: 'contractor не должен иметь $a',
        );
      }
    });
  });

  group('AccessGuard — master (мастер)', () {
    test('может только свой step / photo / chat-write / mat-self-buy', () {
      for (final a in [
        DomainAction.stepManage,
        DomainAction.stepPhotoUpload,
        DomainAction.approvalRequest,
        DomainAction.selfPurchaseCreate,
        DomainAction.toolsViewProject,
        DomainAction.toolsClaim,
        DomainAction.chatRead,
        DomainAction.chatWrite,
        DomainAction.documentRead,
      ]) {
        expect(
          AccessGuard.can(SystemRole.master, a),
          isTrue,
          reason: 'master должен иметь $a',
        );
      }
    });

    test(
      'НЕ имеет stage-management / payment-create / distribute / approval-decide',
      () {
        for (final a in [
          DomainAction.stageManage,
          DomainAction.stageStart,
          DomainAction.stagePause,
          DomainAction.financePaymentCreateAdvance,
          DomainAction.financePaymentDistribute,
          DomainAction.approvalDecide,
          DomainAction.materialsManage,
          DomainAction.chatCreateGroup,
          DomainAction.documentWrite,
          DomainAction.documentDelete,
          DomainAction.projectInviteMember,
        ]) {
          expect(
            AccessGuard.can(SystemRole.master, a),
            isFalse,
            reason: 'master не должен иметь $a',
          );
        }
      },
    );
  });

  group('AccessGuard — representative (П7.3 — read-only by default + чат)', () {
    test('по умолчанию — только смотреть и писать в чат', () {
      // Раунд 2026-05-03: представитель read-only + чат-write. Любое write
      // действие выдаётся только через явные представительские права
      // (см. canInProjectProvider в access_guard.dart).
      //
      // ВАЖНО: набор должен один-в-один соответствовать веткам
      // `backend/libs/rbac/src/rbac.matrix.ts`, которые возвращают true для
      // representative без проверки representativeRights. Любое расхождение
      // даёт 403 на клик/при загрузке: клиент уверен, что плитка/кнопка
      // доступна — фетчит данные — бэкенд режет (так был баг с
      // financeBudgetView, см. логи 2026-05-12).
      for (final a in [
        DomainAction.chatRead,
        DomainAction.chatWrite,
        DomainAction.documentRead,
        DomainAction.approvalList,
        DomainAction.noteManage,
        DomainAction.methodologyRead,
        // feed.export — бэкенд разрешает representative безусловно,
        // объём данных в TXT-сводке фильтруется по роли в сервисе.
        DomainAction.feedExport,
      ]) {
        expect(
          AccessGuard.can(SystemRole.representative, a),
          isTrue,
          reason: 'representative должен иметь $a (read-only baseline)',
        );
      }
    });

    test('НЕ имеет write-действий без делегирования', () {
      // Архивирование никогда не выдаётся (П7.1, П10.4 — эксклюзив заказчика).
      // Все остальные write-actions — только через RepresentativeRights.
      // financeBudgetView — read-action, но тоже требует canSeeBudget
      // (бэкенд rbac.matrix.ts: ветка 'finance.budget.view').
      for (final a in [
        DomainAction.projectArchive,
        DomainAction.projectInviteMember,
        DomainAction.projectEdit,
        DomainAction.stageManage,
        DomainAction.stepManage,
        DomainAction.financeBudgetView,
        DomainAction.financePaymentCreateAdvance,
        DomainAction.financePaymentDistribute,
        DomainAction.financeBudgetEdit,
        DomainAction.materialsManage,
        DomainAction.documentDelete,
        DomainAction.approvalDecide,
      ]) {
        expect(
          AccessGuard.can(SystemRole.representative, a),
          isFalse,
          reason: 'representative без делегирования не должен иметь $a',
        );
      }
    });
  });

  group('Кросс-роль: финансы', () {
    test(
      'approvalDecide — customer/contractor/admin; representative — только с canApprove',
      () {
        expect(
          AccessGuard.can(SystemRole.customer, DomainAction.approvalDecide),
          isTrue,
        );
        expect(
          AccessGuard.can(SystemRole.contractor, DomainAction.approvalDecide),
          isTrue,
        );
        // П7.3 — представитель без делегированного canApprove не имеет approvalDecide.
        // Тест проверяет именно baseline-матрицу. Делегированные права проверяются
        // через canInProjectProvider (см. отдельные unit-тесты на providers).
        expect(
          AccessGuard.can(
            SystemRole.representative,
            DomainAction.approvalDecide,
          ),
          isFalse,
        );
        expect(
          AccessGuard.can(SystemRole.admin, DomainAction.approvalDecide),
          isTrue,
        );
        expect(
          AccessGuard.can(SystemRole.master, DomainAction.approvalDecide),
          isFalse,
        );
      },
    );
  });
}
