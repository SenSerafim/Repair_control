import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/projects/domain/membership.dart';
import '../../features/team/application/team_controller.dart';
import 'domain_actions.dart';
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
      DomainAction.financePaymentCreate,
      DomainAction.financePaymentConfirm,
      DomainAction.financePaymentDispute,
      DomainAction.financePaymentResolve,
      DomainAction.materialsManage,
      DomainAction.materialFinalize,
      DomainAction.selfPurchaseConfirm,
      // tools.* — заказчик инструменты НЕ видит (ТЗ §1.4, gaps §6.1).
      // Backend RBAC явно блокирует — не запрашиваем эти эндпоинты с UI.
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

    // Представитель — действует от имени заказчика. По умолчанию имеет
    // почти всё кроме необратимых действий (архивация проекта, удаление
    // документов, окончательный resolve выплат) и редактирования бюджета.
    // Эти полномочия делегируются явными флагами в representativeRights
    // и проверяются через canInProjectProvider.
    SystemRole.representative: {
      DomainAction.projectEdit,
      // projectInviteMember для representative — только через делегированный
      // флаг canInviteMembers (см. _representativeFlagToActions). Backend
      // также проверяет именно его. В статическом сете не держим.
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
      DomainAction.financePaymentCreate,
      DomainAction.financePaymentConfirm,
      DomainAction.financePaymentDispute,
      DomainAction.materialsManage,
      DomainAction.selfPurchaseConfirm,
      DomainAction.toolsManage,
      DomainAction.chatRead,
      DomainAction.chatWrite,
      DomainAction.chatCreatePersonal,
      DomainAction.chatCreateGroup,
      DomainAction.documentRead,
      DomainAction.documentWrite,
      DomainAction.feedExport,
      DomainAction.noteManage,
      DomainAction.questionManage,
      DomainAction.methodologyRead,
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
      DomainAction.financePaymentCreate,
      DomainAction.financePaymentConfirm,
      DomainAction.financePaymentDispute,
      DomainAction.materialsManage,
      DomainAction.materialFinalize,
      DomainAction.selfPurchaseCreate,
      DomainAction.selfPurchaseConfirm,
      DomainAction.toolsManage,
      DomainAction.toolsIssue,
      DomainAction.toolsReturn,
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
      DomainAction.financePaymentConfirm, // подтверждение получения
      DomainAction.financePaymentDispute,
      DomainAction.selfPurchaseCreate,
      DomainAction.toolsReturn,
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
final representativeRightsProvider =
    Provider.autoDispose.family<Set<DomainAction>, String>((ref, projectId) {
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

/// Маппинг булевых флагов `RepresentativeRights` (бекенд) → набор
/// `DomainAction`. Источник истины — `backend/libs/rbac/src/rbac.matrix.ts`.
const _representativeFlagToActions = <String, List<DomainAction>>{
  'canEditStages': [
    DomainAction.projectEdit,
    DomainAction.stageManage,
    DomainAction.stageStart,
    DomainAction.stagePause,
    DomainAction.stepManage,
    DomainAction.stepAddSubstep,
    DomainAction.documentWrite,
    DomainAction.documentDelete,
  ],
  'canApprove': [
    DomainAction.approvalRequest,
    DomainAction.approvalDecide,
  ],
  'canSeeBudget': [
    DomainAction.financeBudgetView,
    DomainAction.feedExport,
  ],
  'canCreatePayments': [
    DomainAction.financePaymentCreate,
    DomainAction.financePaymentConfirm,
    DomainAction.financePaymentDispute,
    DomainAction.financePaymentResolve,
  ],
  'canManageMaterials': [
    DomainAction.materialsManage,
    DomainAction.materialFinalize,
  ],
  'canManageTools': [
    DomainAction.toolsManage,
    DomainAction.toolsIssue,
    DomainAction.toolsReturn,
  ],
  'canInviteMembers': [
    DomainAction.projectInviteMember,
  ],
  'canAddRepresentative': [
    DomainAction.projectInviteMember,
  ],
};

DomainAction? _domainActionFromString(String raw) {
  for (final a in DomainAction.values) {
    if (a.name == raw || a.toString().split('.').last == raw) return a;
  }
  return null;
}

Set<DomainAction> _expandFlag(String flag) {
  return _representativeFlagToActions[flag]?.toSet() ?? const {};
}

/// Какие роли участника может пригласить текущий пользователь в проекте.
///
/// Правила (соответствуют backend RBAC):
/// - admin / customer: представитель + бригадир + мастер (любые, любое количество);
/// - representative с canInviteMembers: представитель + бригадир + мастер
///   (любые, любое количество — действует от имени заказчика);
/// - contractor (бригадир): только мастер;
/// - master: ничего пригласить не может.
final invitableRolesProvider =
    Provider.family<List<MembershipRole>, String>((ref, projectId) {
  final role = ref.watch(activeRoleProvider);
  if (role == null) return const [];
  if (role == SystemRole.admin || role == SystemRole.customer) {
    return const [
      MembershipRole.representative,
      MembershipRole.foreman,
      MembershipRole.master,
    ];
  }
  if (role == SystemRole.contractor) {
    return const [MembershipRole.master];
  }
  if (role == SystemRole.representative) {
    final delegated = ref.watch(representativeRightsProvider(projectId));
    if (!delegated.contains(DomainAction.projectInviteMember)) return const [];
    return const [
      MembershipRole.representative,
      MembershipRole.foreman,
      MembershipRole.master,
    ];
  }
  return const [];
});

/// Тот же `canProvider`, но с учётом делегированных представителю прав
/// в конкретном проекте. Используется в экранах, где экшен зависит от
/// проекта (approval-decide, finance-confirm, и т.д.) — там, где нужно
/// honor RepresentativeRights для роли representative.
final canInProjectProvider =
    Provider.family<bool, ({DomainAction action, String projectId})>(
  (ref, params) {
    final role = ref.watch(activeRoleProvider);
    if (AccessGuard.can(role, params.action)) return true;
    if (role != SystemRole.representative) return false;
    final delegated =
        ref.watch(representativeRightsProvider(params.projectId));
    return delegated.contains(params.action);
  },
);

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
