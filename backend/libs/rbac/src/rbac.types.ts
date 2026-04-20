export type SystemRole = 'customer' | 'representative' | 'contractor' | 'master' | 'admin';

/**
 * 16 доменных действий из ТЗ §1.5 — матрица прав 4 ролей × 16 действий.
 * Эти действия используются в @RequireAccess и проверяются AccessGuard'ом.
 */
export const DOMAIN_ACTIONS = [
  'project.create',
  'project.edit',
  'project.archive',
  'project.invite_member',
  'stage.manage',
  'stage.start',
  'stage.pause',
  'step.manage',
  'step.add_substep',
  'step.photo.upload',
  'approval.request',
  'approval.decide',
  'finance.budget.edit',
  'finance.payment.create',
  'materials.manage',
  'tools.manage',
  'chat.read',
  'note.manage',
  'question.manage',
] as const;

export type DomainAction = (typeof DOMAIN_ACTIONS)[number];

export interface AccessContext {
  systemRole: SystemRole;
  userId: string;
  projectOwnerId?: string;
  membershipRole?: 'customer' | 'representative' | 'foreman' | 'master';
  representativeRights?: RepresentativeRights;
  stageForemanIds?: string[];
  stepAuthorId?: string;
  stepAssigneeIds?: string[];
}

export interface RepresentativeRights {
  canEditStages?: boolean;
  canApprove?: boolean;
  canSeeBudget?: boolean;
  canAddRepresentative?: boolean;
  canCreatePayments?: boolean;
  canManageMaterials?: boolean;
  canManageTools?: boolean;
  canInviteMembers?: boolean;
}
