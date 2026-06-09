import '../../../core/access/system_role.dart';
import '../../projects/domain/membership.dart';

/// NEWFIX-2 §6.1 — клиентская оборона (defense-in-depth).
///
/// Заказчик НЕ должен видеть мастеров в команде проекта (приватность контакта
/// бригадира с его исполнителями). Сервер уже фильтрует ответ
/// `GET /api/me/teammates` (см. backend/audit), но если фильтр когда-нибудь
/// сломается, клиент не должен раскрывать мастеров заказчику.
///
/// Сравнение идёт по `MembershipRole` (роль участника в проекте), потому что
/// именно она приходит с бэка в каждом `Membership`. Глобальная `SystemRole`
/// пользователя (`activeRole`) используется только для решения,
/// фильтровать или нет.
List<Membership> filterMembershipsForRole(
  List<Membership> input,
  SystemRole? viewerRole,
) {
  if (viewerRole != SystemRole.customer) return input;
  return input
      .where((m) => m.role != MembershipRole.master)
      .toList(growable: false);
}
