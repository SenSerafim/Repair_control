import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/projects/application/project_controller.dart';
import '../../features/projects/domain/membership.dart';
import '../../features/team/application/team_controller.dart';
import 'domain_actions.dart';
import 'representative_rights.dart';
import 'system_role.dart';

/// Клиентская RBAC-матрица: (роль × действие) → разрешено/нет.
///
/// Сервер — финальный guard. Клиент использует матрицу только чтобы
/// скрывать кнопки, для которых сервер заведомо вернёт 403 — это UX-слой.
///
/// Матрица — урезанное отражение `backend/libs/rbac/src/rbac.types.ts`.
class AccessGuard {
  const AccessGuard._();

  // Иерархия ролей по убыванию полномочий:
  // admin ≥ customer ≥ representative ≥ contractor (бригадир) ≥ master.
  //
  // Принципы:
  // • customer — владелец, может ВСЁ кроме методички (она глобальная).
  // • representative — действует от имени заказчика, имеет почти всё,
  //   кроме архивации и удаления документов (необратимые действия
  //   делегируются явно через representativeRights).
  // • contractor (бригадир) — управляет работой: этапы, шаги, материалы,
  //   инструмент, чаты команды. НЕ управляет проектом и финансами
  //   (создание выплат — да, но не их «resolve»).
  // • master — исполнитель: ведёт свои шаги (фото, отметки),
  //   подтверждает выплаты по своим работам, читает чаты/документы.
  static final Map<SystemRole, Set<DomainAction>> _matrix = {
    // Админ — суперпользователь.
    SystemRole.admin: Set.of(DomainAction.values),

    // Заказчик — владелец проекта. Может ВСЁ внутри своего проекта,
    // включая архивацию, бюджет, удаление документов, модерирование
    // чатов. Не может только редактировать общую методичку.
    SystemRole.customer: {
      DomainAction.projectCreate,
      DomainAction.projectEdit,
      DomainAction.projectArchive,
      DomainAction.projectInviteMember,
      DomainAction.stageManage,
      DomainAction.stageStart,
      DomainAction.stagePause,
      DomainAction.stepManage,
      DomainAction.stepAddSubstep,
      DomainAction.stepPhotoUpload,
      DomainAction.approvalList,
      DomainAction.approvalRequest,
      DomainAction.approvalDecide,
      DomainAction.financeBudgetView,
      DomainAction.financeBudgetEdit,
      // Создание платежа — эксклюзив заказчика. Прямой платёж foreman или
      // master без согласований. Бригадиру не выдаём: у него distribute из
      // родительского аванса (см. contractor ниже).
      DomainAction.financePaymentCreateAdvance,
      DomainAction.materialsManage,
      DomainAction.selfPurchaseConfirm,
      // tools.* — заказчик write-действия не делает (issue/manage/return),
      // но read-only видимость инструмента в проекте включена: его инструменты
      // тоже могут быть на объекте (П2.15, уточнение от заказчика).
      DomainAction.toolsViewProject,
      DomainAction.chatRead,
      DomainAction.chatWrite,
      DomainAction.chatCreatePersonal,
      DomainAction.chatCreateGroup,
      DomainAction.chatToggleCustomerVisibility,
      DomainAction.chatModerate,
      DomainAction.documentRead,
      DomainAction.documentWrite,
      DomainAction.documentDelete,
      DomainAction.feedExport,
      DomainAction.noteManage,
      DomainAction.questionManage,
      DomainAction.methodologyRead,
    },

    // Представитель (П7.3 / раунд 2026-05-03) — read-only по умолчанию + чат.
    // Любое write-действие (создание этапа, согласование, аванс, инвайт и т.п.)
    // выдаётся только через явные флаги в representativeRights (см.
    // _representativeFlagToActions ниже + canInProjectProvider).
    //
    // Архивирование проекта представителю НЕ выдаётся ни при каких условиях
    // (см. backend rbac.matrix.ts: project.archive — эксклюзив заказчика).
    //
    // ВАЖНО: список дефолтов должен в точности отражать те ветки
    // `backend/libs/rbac/src/rbac.matrix.ts`, которые возвращают true для
    // representative БЕЗ проверки representativeRights. Любое расхождение даёт
    // 403 на клик/при загрузке экрана: UI считает что кнопка/плитка должна
    // показаться, фетчит данные, бэкенд отдаёт 403. Так было с
    // `finance.budget.view`: бэкенд требует `canSeeBudget`, клиент считал
    // дефолтом — отсюда серия 403 на `GET /projects/:id/budget` у
    // представителя без флага.
    SystemRole.representative: {
      // Чтения (бэкенд: !!ctx.membershipRole / always-true для representative)
      DomainAction.approvalList,
      DomainAction.documentRead,
      DomainAction.methodologyRead,
      DomainAction.questionManage,
      // Read-only инструмент в проекте (П2.15) — write остаётся под canManageTools.
      DomainAction.toolsViewProject,
      // Чат — write по умолчанию (П7.3, "может смотреть всё + писать в чат")
      DomainAction.chatRead,
      DomainAction.chatWrite,
      // Заметки — read+create без права (modify в сервисе уже ограничен авторством)
      DomainAction.noteManage,
      // Экспорт ленты — бэкенд (rbac.matrix.ts: 'feed.export') разрешает
      // representative безусловно, т.к. объём данных в TXT-сводке всё равно
      // фильтруется по роли в сервисе (бюджетные строки прячутся, если нет
      // canSeeBudget). Клиентский дефолт должен совпадать.
      DomainAction.feedExport,
      // NOTE: `financeBudgetView` намеренно НЕ в дефолтах — бэкенд требует
      // representativeRights.canSeeBudget. Право подтягивается через
      // representativeRightToActions[canSeeBudget] в canInProjectProvider.
    },

    // Бригадир — управляет работой команды. Меньше прав, чем
    // представитель: не редактирует проект, не приглашает представителя
    // (только мастеров), не имеет доступа к финансовым resolve.
    SystemRole.contractor: {
      DomainAction.projectInviteMember, // ограничено мастерами в UI
      DomainAction.stageManage,
      DomainAction.stageStart,
      DomainAction.stagePause,
      DomainAction.stepManage,
      DomainAction.stepAddSubstep,
      DomainAction.stepPhotoUpload,
      DomainAction.approvalList,
      DomainAction.approvalRequest,
      DomainAction.approvalDecide, // в пределах своих этапов
      DomainAction.financeBudgetView,
      // Бригадир НЕ создаёт общий аванс — это эксклюзив заказчика. Из
      // родительского аванса распределяет мастерам через distribute.
      DomainAction.financePaymentDistribute,
      DomainAction.materialsManage,
      DomainAction.selfPurchaseCreate,
      DomainAction.selfPurchaseConfirm,
      DomainAction.toolsViewProject,
      DomainAction.toolsAddToProject,
      DomainAction.toolsClaim,
      DomainAction.chatRead,
      DomainAction.chatWrite,
      DomainAction.chatCreatePersonal,
      DomainAction.chatCreateGroup,
      DomainAction.chatToggleCustomerVisibility,
      DomainAction.chatModerate,
      DomainAction.documentRead,
      DomainAction.documentWrite,
      DomainAction.feedExport,
      DomainAction.noteManage,
      DomainAction.questionManage,
      DomainAction.methodologyRead,
    },

    // Мастер — исполнитель. Минимум прав: ведёт свои шаги (фото,
    // подшаги), подтверждает выплаты по своим работам, читает чаты
    // и документы. Не может управлять этапами или приглашать кого-либо.
    SystemRole.master: {
      DomainAction.stepManage, // только свои шаги (assignee)
      DomainAction.stepAddSubstep,
      DomainAction.stepPhotoUpload,
      DomainAction.approvalList,
      DomainAction.approvalRequest, // доп.работа
      DomainAction.financeBudgetView,
      DomainAction.selfPurchaseCreate,
      DomainAction.toolsViewProject,
      DomainAction.toolsAddToProject,
      DomainAction.toolsClaim,
      DomainAction.chatRead,
      DomainAction.chatWrite,
      DomainAction.documentRead,
      DomainAction.noteManage,
      DomainAction.questionManage,
      DomainAction.methodologyRead,
    },
  };

  /// Может ли пользователь с [role] выполнить [action]?
  /// Если [role] == null — всё запрещено.
  static bool can(SystemRole? role, DomainAction action) {
    if (role == null) return false;
    return _matrix[role]?.contains(action) ?? false;
  }
}

/// Отслеживает текущую активную роль пользователя (из auth-состояния).
final activeRoleProvider = Provider<SystemRole?>((ref) {
  return ref.watch(authControllerProvider).activeRole;
});

/// Можно ли выполнить action с учётом активной роли — реактивный геттер.
final canProvider = Provider.family<bool, DomainAction>((ref, action) {
  final role = ref.watch(activeRoleProvider);
  return AccessGuard.can(role, action);
});

/// Делегированные представителю права в конкретном проекте.
///
/// Источник: `Membership.representativeRights` (JSONB на бэке, массив строк
/// = `DomainAction.value`). Парсится в `Membership.parse(...)` и кэшируется
/// в `MembershipRights`. Здесь — конвертация из строк в `Set<DomainAction>`
/// + автоинвалидация при перезагрузке team.
final representativeRightsProvider = Provider.autoDispose
    .family<Set<DomainAction>, String>((ref, projectId) {
      final me = ref.watch(authControllerProvider).userId;
      if (me == null) return const <DomainAction>{};
      final teamAsync = ref.watch(teamControllerProvider(projectId));
      return teamAsync.when(
        data: (team) {
          final mine = team.members.where(
            (m) => m.userId == me && m.role == MembershipRole.representative,
          );
          if (mine.isEmpty) return const <DomainAction>{};
          final rights = mine.first.representativeRights;
          final result = <DomainAction>{};
          for (final raw in rights) {
            // Поддержка обоих форматов: булевы флаги (`canApprove`) и старые
            // имена `DomainAction.value`.
            result.addAll(_expandFlag(raw));
            final direct = _domainActionFromString(raw);
            if (direct != null) result.add(direct);
          }
          return result;
        },
        loading: () => const <DomainAction>{},
        error: (_, __) => const <DomainAction>{},
      );
    });

DomainAction? _domainActionFromString(String raw) {
  for (final a in DomainAction.values) {
    if (a.name == raw || a.toString().split('.').last == raw) return a;
  }
  return null;
}

/// Источник истины — `representativeRightToActions` в
/// `core/access/representative_rights.dart`, которая зеркалит
/// `backend/libs/rbac/src/rbac.matrix.ts`. Здесь — конвертация по jsonKey
/// и graceful return пустого set для незнакомых ключей (на случай legacy
/// данных в БД до унификации формата permissions).
Set<DomainAction> _expandFlag(String flag) {
  final right = RepresentativeRight.fromJsonKey(flag);
  if (right == null) return const {};
  return representativeRightToActions[right]?.toSet() ?? const {};
}

/// Membership-запись текущего пользователя в конкретном проекте.
///
/// ТЗ §1.3 — один аккаунт может быть foreman в проекте A и master в проекте B.
/// Решения по UI должны приниматься по membership-роли (где я в этом проекте),
/// а не по глобальной активной роли.
final myMembershipInProjectProvider = Provider.autoDispose
    .family<Membership?, String>((ref, projectId) {
      final me = ref.watch(authControllerProvider).userId;
      if (me == null) return null;
      final teamAsync = ref.watch(teamControllerProvider(projectId));
      return teamAsync.maybeWhen(
        data: (team) {
          try {
            return team.members.firstWhere((m) => m.userId == me);
          } catch (_) {
            return null;
          }
        },
        orElse: () => null,
      );
    });

/// Какие роли участника может пригласить текущий пользователь в проекте.
///
/// 2026-05 рефактор: решение по membership-роли в конкретном проекте, а не
/// по глобальной активной (ТЗ §1.3). Синхронизировано с
/// `backend/libs/rbac/src/rbac.matrix.ts` + service-уровень
/// `members.service.ts` (foreman → only master).
///
/// 2026-05-12 фикс «Недостаточно прав» у заказчика: владелец проекта получает
/// права заказчика даже если у него нет явной customer-membership (legacy-
/// проекты, race во время загрузки team-данных). Источник истины —
/// `project.ownerId`; membership используется только когда me ≠ owner.
final invitableRolesProvider = Provider.family<List<MembershipRole>, String>((
  ref,
  projectId,
) {
  final sys = ref.watch(activeRoleProvider);
  if (sys == SystemRole.admin) {
    return const [
      MembershipRole.representative,
      MembershipRole.foreman,
      MembershipRole.master,
    ];
  }
  final me = ref.watch(authControllerProvider).userId;
  final projectAsync = ref.watch(projectControllerProvider(projectId));
  final ownerId = projectAsync.maybeWhen(
    data: (p) => p.ownerId,
    orElse: () => null,
  );
  // Заказчик/представитель приглашают только бригадира и представителя.
  // Мастеров приглашает бригадир — это явное продуктовое требование
  // (Серафим 08.06.2026): заказчик не должен видеть мастеров вообще.
  if (me != null && ownerId != null && me == ownerId) {
    return const [MembershipRole.representative, MembershipRole.foreman];
  }
  final my = ref.watch(myMembershipInProjectProvider(projectId));
  if (my == null) return const [];
  switch (my.role) {
    case MembershipRole.customer:
      return const [MembershipRole.representative, MembershipRole.foreman];
    case MembershipRole.representative:
      final delegated = ref.watch(representativeRightsProvider(projectId));
      if (!delegated.contains(DomainAction.projectInviteMember)) {
        return const [];
      }
      return const [MembershipRole.representative, MembershipRole.foreman];
    case MembershipRole.foreman:
      return const [MembershipRole.master];
    case MembershipRole.master:
      return const [];
  }
});

/// Может ли пользователь выполнить [action] в КОНКРЕТНОМ проекте.
///
/// 2026-05-13 рефактор: per-project membership > глобальный activeRole.
/// Раньше провайдер смотрел только `activeRoleProvider` (глобальную активную
/// роль) и поэтому скрывал, например, у бригадира пункт «Назначить мастера»,
/// если он переключил глобальную роль на «заказчика». Теперь:
///   1) `admin` (глобально) — всегда true.
///   2) `project.ownerId == me` — права заказчика (фикс legacy-проектов без
///      явной customer-membership).
///   3) `Membership.role` в этом проекте → соответствующая `SystemRole` в
///      матрице. Один аккаунт может быть foreman в проекте A и master в
///      проекте B; UI принимает решение по тому, где я нахожусь СЕЙЧАС.
///   4) Делегированные представителю права (canApprove / canSeeBudget / …) —
///      добавочные, к matrix-набору representative.
///   5) Fallback на глобальный `activeRoleProvider` — на случай, когда
///      `teamControllerProvider` ещё не загрузился (нулевой кадр после deep-
///      link). Это даёт лучший UX, чем ложное «нет прав».
final canInProjectProvider =
    Provider.family<bool, ({DomainAction action, String projectId})>((
      ref,
      params,
    ) {
      final sysRole = ref.watch(activeRoleProvider);
      if (sysRole == SystemRole.admin) return true;

      final me = ref.watch(authControllerProvider).userId;
      final projectAsync = ref.watch(
        projectControllerProvider(params.projectId),
      );
      final ownerId = projectAsync.maybeWhen(
        data: (p) => p.ownerId,
        orElse: () => null,
      );
      if (me != null &&
          ownerId != null &&
          me == ownerId &&
          AccessGuard.can(SystemRole.customer, params.action)) {
        return true;
      }

      final my = ref.watch(myMembershipInProjectProvider(params.projectId));
      final membershipSysRole = switch (my?.role) {
        MembershipRole.customer => SystemRole.customer,
        MembershipRole.representative => SystemRole.representative,
        MembershipRole.foreman => SystemRole.contractor,
        MembershipRole.master => SystemRole.master,
        null => null,
      };
      if (membershipSysRole != null &&
          AccessGuard.can(membershipSysRole, params.action)) {
        return true;
      }
      if (membershipSysRole == SystemRole.representative) {
        final delegated = ref.watch(
          representativeRightsProvider(params.projectId),
        );
        if (delegated.contains(params.action)) return true;
      }

      // Fallback на глобальную активную роль (для случая, когда team ещё
      // не пришла; иначе UI на 1 кадр скрывал кнопки у того, у кого они есть).
      if (AccessGuard.can(sysRole, params.action)) return true;
      if (sysRole == SystemRole.representative) {
        final delegated = ref.watch(
          representativeRightsProvider(params.projectId),
        );
        if (delegated.contains(params.action)) return true;
      }
      return false;
    });

/// Wrapper-виджет: показывает [child] только если у текущей роли есть
/// право на [action]. Иначе — `SizedBox.shrink()` или [fallback].
class AccessGated extends ConsumerWidget {
  const AccessGated({
    required this.action,
    required this.child,
    this.fallback,
    super.key,
  });

  final DomainAction action;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(canProvider(action));
    if (allowed) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
