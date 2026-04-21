import { AccessContext, DomainAction, RepresentativeRights } from './rbac.types';

/**
 * Решение матрицы прав из ТЗ §1.5 (4 системные роли × 16 действий).
 *
 * Правила:
 * - admin: всё.
 * - customer: владеет проектом (ownerId === userId) — может всё в рамках своего проекта.
 * - representative: определяется RepresentativeRights, привязанными к Membership.
 * - contractor (foreman): управляет этапами/шагами; не редактирует бюджет; может создавать выплаты распределения.
 * - master: работает только по назначенным этапам; ограничен просмотром и отметкой своих шагов.
 */
export const canAccess = (action: DomainAction, ctx: AccessContext): boolean => {
  if (ctx.systemRole === 'admin') return true;

  switch (action) {
    case 'project.create':
      return ctx.systemRole === 'customer';

    case 'project.edit':
    case 'project.archive':
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canEditStages;
      return false;

    case 'project.invite_member':
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative')
        return !!ctx.representativeRights?.canInviteMembers;
      return false;

    case 'stage.manage':
    case 'stage.start':
    case 'stage.pause':
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canEditStages;
      if (ctx.membershipRole === 'foreman') return true;
      return false;

    case 'step.manage':
      if (ctx.membershipRole === 'foreman') return true;
      if (ctx.membershipRole === 'master') {
        // Мастер может управлять шагом, только если он назначен на этап или на сам шаг (ТЗ §6.4)
        const isStageAssignee = (ctx.stageForemanIds ?? []).includes(ctx.userId);
        const isStepAssignee = (ctx.stepAssigneeIds ?? []).includes(ctx.userId);
        return isStageAssignee || isStepAssignee;
      }
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canEditStages;
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      return false;

    case 'step.add_substep':
      // подшаги могут добавлять все участники проекта (ТЗ §6.4)
      return !!ctx.membershipRole;

    case 'step.photo.upload':
      // Фото шага может прикрепить любой активный участник (customer/rep.canEditStages/foreman/master)
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canEditStages;
      if (ctx.membershipRole === 'foreman') return true;
      if (ctx.membershipRole === 'master') return !!ctx.membershipRole;
      return false;

    case 'note.manage':
    case 'question.manage':
      // Любой участник проекта. Точечные ограничения (author-only / addressee-only) — внутри сервиса.
      return !!ctx.membershipRole;

    case 'methodology.read':
      // Методичка видна всем аутентифицированным (ТЗ §8 спринт 3 день 6).
      return true;

    case 'methodology.edit':
      // Только админ правит методичку. Admin обрабатывается в блоке выше → сюда не доходит.
      return false;

    case 'approval.request':
      if (ctx.membershipRole === 'foreman') return true;
      if (ctx.membershipRole === 'master') return true;
      return false;

    case 'approval.decide':
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canApprove;
      if (ctx.membershipRole === 'foreman') return true;
      return false;

    case 'finance.budget.edit':
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative') return !!ctx.representativeRights?.canEditStages;
      return false;

    case 'finance.payment.create':
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative')
        return !!ctx.representativeRights?.canCreatePayments;
      if (ctx.membershipRole === 'foreman') return true; // распределение аванса
      return false;

    case 'materials.manage':
      if (ctx.systemRole === 'customer' && ctx.projectOwnerId === ctx.userId) return true;
      if (ctx.membershipRole === 'representative')
        return !!ctx.representativeRights?.canManageMaterials;
      if (ctx.membershipRole === 'foreman') return true;
      if (ctx.membershipRole === 'master') return true;
      return false;

    case 'tools.manage':
      // заказчик инструменты не видит (ТЗ §1.4)
      if (ctx.membershipRole === 'foreman') return true;
      if (ctx.membershipRole === 'master') return true;
      if (ctx.membershipRole === 'representative')
        return !!ctx.representativeRights?.canManageTools;
      return false;

    case 'chat.read':
      return !!ctx.membershipRole;

    default:
      return false;
  }
};

export const mergeRepresentativeRights = (
  base: RepresentativeRights | undefined,
  override: Partial<RepresentativeRights> | undefined,
): RepresentativeRights => ({
  canEditStages: false,
  canApprove: false,
  canSeeBudget: false,
  canAddRepresentative: false,
  canCreatePayments: false,
  canManageMaterials: false,
  canManageTools: false,
  canInviteMembers: false,
  ...(base ?? {}),
  ...(override ?? {}),
});
