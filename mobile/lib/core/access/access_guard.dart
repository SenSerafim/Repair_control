import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
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

  static final Map<SystemRole, Set<DomainAction>> _matrix = {
    SystemRole.admin: Set.of(DomainAction.values),
    SystemRole.customer: {
      DomainAction.projectCreate,
      DomainAction.projectEdit,
      DomainAction.projectArchive,
      DomainAction.projectInviteMember,
      DomainAction.approvalList,
      DomainAction.approvalDecide,
      DomainAction.financeBudgetView,
      DomainAction.financeBudgetEdit,
      DomainAction.financePaymentCreate,
      DomainAction.financePaymentConfirm,
      DomainAction.financePaymentDispute,
      DomainAction.financePaymentResolve,
      DomainAction.chatRead,
      DomainAction.chatWrite,
      DomainAction.chatCreatePersonal,
      DomainAction.documentRead,
      DomainAction.documentWrite,
      DomainAction.feedExport,
      DomainAction.noteManage,
      DomainAction.methodologyRead,
    },
    SystemRole.representative: {
      // Делегированные права хранятся в membership.representativeRights
      // (JSONB). Матрица — базовые права без делегирования.
      DomainAction.chatRead,
      DomainAction.chatWrite,
      DomainAction.documentRead,
      DomainAction.financeBudgetView,
      DomainAction.noteManage,
      DomainAction.methodologyRead,
    },
    SystemRole.contractor: {
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
      DomainAction.documentDelete,
      DomainAction.feedExport,
      DomainAction.noteManage,
      DomainAction.questionManage,
      DomainAction.methodologyRead,
    },
    SystemRole.master: {
      DomainAction.stepManage,
      DomainAction.stepAddSubstep,
      DomainAction.stepPhotoUpload,
      DomainAction.approvalRequest,
      DomainAction.financeBudgetView,
      DomainAction.financePaymentConfirm,
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
