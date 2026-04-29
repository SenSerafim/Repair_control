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
  'methodology.read',
  'methodology.edit',
  'finance.payment.confirm',
  'finance.payment.dispute',
  'finance.payment.resolve',
  'finance.budget.view',
  'material.finalize',
  'selfpurchase.create',
  'selfpurchase.confirm',
  'tools.issue',
  'tools.return',
  'approval.list',
  // ---------- S5 ----------
  'chat.write',
  'chat.create_personal',
  'chat.create_group',
  'chat.toggle_customer_visibility',
  'chat.moderate',
  'document.read',
  'document.write',
  'document.delete',
  'feed.export',
  'notification.settings.self',
  'feedback.create',
  'admin.templates.manage',
  'admin.faq.manage',
  'admin.feedback.read',
  'admin.feedback.reply',
  'admin.settings.manage',
  'admin.notifications.inspect',
  // Admin panel Day 10b
  'admin.users.list',
  'admin.users.detail',
  'admin.users.ban',
  'admin.users.reset_password',
  'admin.users.force_logout',
  'admin.users.manage_roles',
  'admin.projects.list_all',
  'admin.projects.force_archive',
  'admin.legal.read_admin',
  'admin.legal.manage',
  'admin.legal_publications.manage',
  'admin.knowledge.manage',
  'knowledge.read',
  'admin.broadcast.send',
  'admin.broadcast.list',
  'admin.audit.read',
  'admin.stats.read',
  // Public
  'legal.accept',
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
  // S5: контекст чата (для chat.* actions)
  chatCreatedById?: string;
  chatIsParticipant?: boolean;
  chatIsActiveParticipant?: boolean; // участник с leftAt=null
  chatVisibleToCustomer?: boolean;
  chatType?: 'project' | 'stage' | 'personal' | 'group';
  // S5: контекст документа (для document.* actions)
  documentUploadedById?: string;
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
