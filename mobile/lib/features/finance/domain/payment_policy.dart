import 'payment.dart';

/// Единая точка истины для разрешённых действий над выплатой.
///
/// Зеркалит `backend/libs/rbac/src/rbac.matrix.ts` (`finance.payment.*`)
/// + точечные проверки сервиса по `fromUserId/toUserId`. Бэкенд — финальный
/// гард; этот класс закрывает UI: скрыть кнопку, которую сервер всё равно
/// отвергнет, лучше, чем показать её и получить 403.
///
/// Матрица (см. ТЗ §4 + Gaps §4.1):
///
/// | Действие         | customer-owner | foreman | master  | representative      | admin |
/// |------------------|----------------|---------|---------|---------------------|-------|
/// | budget.view      | ✓              | ✓       | ✓       | canSeeBudget        | ✓     |
/// | budget.edit      | ✓              | –       | –       | canEditStages       | ✓     |
/// | payment.create   | ✓              | ✓       | –       | canCreatePayments   | ✓     |
/// | payment.confirm  | toUserId only  | toUserId| toUserId| – (нет membership)  | ✓     |
/// | payment.cancel   | fromUserId only| from-id | from-id | – (нет membership)  | ✓     |
/// | payment.dispute  | from/to        | from/to | from/to | –                   | ✓     |
/// | payment.resolve  | ✓ (status=disp)| –       | –       | canApprove          | ✓     |
/// | distribute       | –              | toUserId+remaining>0 | – | canCreatePayments | ✓ |
/// | view distribution| ✓ (owner аванса)| ✓ (получатель)| – | canSeeBudget         | ✓ |
///
/// `hasXxx` параметры приходят из `canInProjectProvider(...)` — там уже
/// резолвлен системная роль + членство + представительские права.
class PaymentPolicy {
  const PaymentPolicy._();

  /// «Подтвердить получение» — только адресат pending-выплаты.
  /// `hasConfirm` — `finance.payment.confirm` (любой участник, фильтр в сервисе).
  static bool canConfirm({
    required Payment payment,
    required String? meId,
    required bool hasConfirm,
  }) {
    if (meId == null) return false;
    return hasConfirm &&
        payment.status == PaymentStatus.pending &&
        payment.toUserId == meId;
  }

  /// «Отменить» — только отправитель ещё не подтверждённой выплаты.
  /// Бэкенд разрешает sender'у вне зависимости от `payment.create` —
  /// отзыв собственного pending не требует RBAC.
  static bool canCancel({
    required Payment payment,
    required String? meId,
  }) {
    if (meId == null) return false;
    return payment.status == PaymentStatus.pending &&
        payment.fromUserId == meId;
  }

  /// «Открыть спор» — sender или receiver уже **подтверждённой** выплаты,
  /// при наличии RBAC `finance.payment.dispute` (любой участник проекта).
  static bool canDispute({
    required Payment payment,
    required String? meId,
    required bool hasDispute,
  }) {
    if (meId == null) return false;
    return hasDispute &&
        payment.status == PaymentStatus.confirmed &&
        (payment.toUserId == meId || payment.fromUserId == meId);
  }

  /// «Разрешить спор» — только заказчик-владелец (или admin/representative
  /// с `canApprove`). Точная роль закрыта в `finance.payment.resolve`.
  static bool canResolve({
    required Payment payment,
    required bool hasResolve,
  }) {
    return hasResolve && payment.status == PaymentStatus.disputed;
  }

  /// «Распределить мастеру» — только бригадир-получатель подтверждённого
  /// аванса, у которого ещё есть остаток для распределения.
  static bool canDistribute({
    required Payment payment,
    required String? meId,
    required bool hasCreate,
  }) {
    if (meId == null) return false;
    return hasCreate &&
        payment.kind == PaymentKind.advance &&
        payment.status == PaymentStatus.confirmed &&
        payment.remainingToDistribute > 0 &&
        payment.toUserId == meId;
  }

  /// «Распределение аванса» (просмотр распределения) — родительский
  /// аванс, у которого либо уже есть дочерние выплаты, либо я получатель
  /// (бригадир). Заказчик-отправитель тоже видит, если есть дети.
  /// Кнопка ведёт на `AdvanceDistributionScreen` — там RBAC ещё раз
  /// проверяется на действия (создать/удалить child).
  static bool canViewDistribution({
    required Payment payment,
    required String? meId,
  }) {
    if (meId == null) return false;
    if (payment.kind != PaymentKind.advance) return false;
    if (payment.parentPaymentId != null) return false;
    return payment.children.isNotEmpty ||
        payment.toUserId == meId ||
        payment.fromUserId == meId;
  }
}
