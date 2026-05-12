import 'payment.dart';

/// Какие действия над платежом доступны пользователю.
///
/// Зеркалит `backend/libs/rbac/src/rbac.matrix.ts` (`finance.payment.*`)
/// + точечные проверки сервиса по `fromUserId/toUserId`. Бэкенд — финальный
/// гард; этот класс закрывает UI: скрыть кнопку, которую сервер всё равно
/// отвергнет, лучше, чем показать её и получить 403.
///
/// В упрощённой модели (2026-05-12) платёж = факт передачи денег. Нет
/// подтверждений, отмен, споров — единственное действие на детали платежа
/// для бригадира: распределить полученный аванс мастеру.
///
/// | Действие              | customer-owner | foreman | master  | representative      | admin |
/// |-----------------------|----------------|---------|---------|---------------------|-------|
/// | budget.view           | ✓              | ✓       | ✓       | canSeeBudget        | ✓     |
/// | budget.edit           | ✓              | –       | –       | canEditStages       | ✓     |
/// | payment.create_advance| ✓              | –       | –       | canCreatePayments   | ✓     |
/// | payment.distribute    | –              | parent.to=actor| – | –                   | ✓     |
class PaymentPolicy {
  const PaymentPolicy._();

  /// «Распределить мастеру» — только бригадир-получатель аванса.
  /// `hasDistribute` — `finance.payment.distribute` (бригадир-роль; точечная
  /// проверка parent.toUserId === actor — в сервисе).
  static bool canDistribute({
    required Payment payment,
    required String? meId,
    required bool hasDistribute,
  }) {
    if (meId == null) return false;
    return hasDistribute &&
        payment.kind == PaymentKind.advance &&
        payment.toUserId == meId;
  }

  /// «Распределение аванса» (просмотр) — родительский аванс с уже созданными
  /// дочерними выплатами, либо я отправитель/получатель.
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
