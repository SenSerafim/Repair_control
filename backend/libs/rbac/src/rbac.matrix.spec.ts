import { canAccess, mergeRepresentativeRights } from './rbac.matrix';
import { AccessContext } from './rbac.types';

const customer = (ownsProject: boolean): AccessContext => ({
  userId: 'u-customer',
  systemRole: 'customer',
  projectOwnerId: ownsProject ? 'u-customer' : 'u-someone-else',
  membershipRole: 'customer',
});

const representative = (
  rights: Partial<AccessContext['representativeRights']> = {},
): AccessContext => ({
  userId: 'u-rep',
  systemRole: 'representative',
  projectOwnerId: 'u-owner',
  membershipRole: 'representative',
  representativeRights: mergeRepresentativeRights(undefined, rights),
});

const foreman = (): AccessContext => ({
  userId: 'u-for',
  systemRole: 'contractor',
  projectOwnerId: 'u-owner',
  membershipRole: 'foreman',
});

const master = (): AccessContext => ({
  userId: 'u-mas',
  systemRole: 'master',
  projectOwnerId: 'u-owner',
  membershipRole: 'master',
});

const admin = (): AccessContext => ({ userId: 'u-adm', systemRole: 'admin' });

describe('RBAC matrix — ТЗ §1.5', () => {
  describe('admin', () => {
    it('bypasses all checks', () => {
      expect(canAccess('project.create', admin())).toBe(true);
      expect(canAccess('finance.budget.edit', admin())).toBe(true);
      expect(canAccess('tools.manage', admin())).toBe(true);
    });
  });

  describe('project.create', () => {
    it('customer can create', () => {
      expect(canAccess('project.create', customer(true))).toBe(true);
    });
    it('contractor cannot create', () => {
      expect(canAccess('project.create', foreman())).toBe(false);
    });
    it('master cannot create', () => {
      expect(canAccess('project.create', master())).toBe(false);
    });
    it('representative cannot create', () => {
      expect(canAccess('project.create', representative())).toBe(false);
    });
  });

  describe('project.edit / project.archive', () => {
    it('owner-customer can edit', () => {
      expect(canAccess('project.edit', customer(true))).toBe(true);
      expect(canAccess('project.archive', customer(true))).toBe(true);
    });
    it('non-owner customer cannot edit someone else project', () => {
      expect(canAccess('project.edit', customer(false))).toBe(false);
    });
    it('representative with canEditStages can edit', () => {
      expect(canAccess('project.edit', representative({ canEditStages: true }))).toBe(true);
    });
    it('representative without canEditStages cannot edit', () => {
      expect(canAccess('project.edit', representative({ canEditStages: false }))).toBe(false);
    });
    it('foreman cannot edit project-level', () => {
      expect(canAccess('project.edit', foreman())).toBe(false);
    });
  });

  describe('project.invite_member', () => {
    it('owner invites', () => {
      expect(canAccess('project.invite_member', customer(true))).toBe(true);
    });
    it('representative with canInviteMembers', () => {
      expect(canAccess('project.invite_member', representative({ canInviteMembers: true }))).toBe(
        true,
      );
      expect(canAccess('project.invite_member', representative({ canInviteMembers: false }))).toBe(
        false,
      );
    });
    it('foreman cannot invite', () => {
      expect(canAccess('project.invite_member', foreman())).toBe(false);
    });
  });

  describe('stage.manage / stage.start / stage.pause', () => {
    it('foreman always manages stages', () => {
      expect(canAccess('stage.manage', foreman())).toBe(true);
      expect(canAccess('stage.start', foreman())).toBe(true);
      expect(canAccess('stage.pause', foreman())).toBe(true);
    });
    it('owner can manage stages of their project', () => {
      expect(canAccess('stage.manage', customer(true))).toBe(true);
    });
    it('representative with canEditStages can manage', () => {
      expect(canAccess('stage.manage', representative({ canEditStages: true }))).toBe(true);
      expect(canAccess('stage.manage', representative({ canEditStages: false }))).toBe(false);
    });
    it('master cannot manage stages (only work on assigned)', () => {
      expect(canAccess('stage.manage', master())).toBe(false);
    });
  });

  describe('approval.decide', () => {
    it('owner decides', () => {
      expect(canAccess('approval.decide', customer(true))).toBe(true);
    });
    it('representative with canApprove decides', () => {
      expect(canAccess('approval.decide', representative({ canApprove: true }))).toBe(true);
      expect(canAccess('approval.decide', representative({ canApprove: false }))).toBe(false);
    });
    it('foreman decides (for master requests)', () => {
      expect(canAccess('approval.decide', foreman())).toBe(true);
    });
    it('master cannot decide', () => {
      expect(canAccess('approval.decide', master())).toBe(false);
    });
  });

  describe('finance.budget.edit', () => {
    it('only owner or permitted representative', () => {
      expect(canAccess('finance.budget.edit', customer(true))).toBe(true);
      expect(canAccess('finance.budget.edit', representative({ canEditStages: true }))).toBe(true);
      expect(canAccess('finance.budget.edit', representative({ canEditStages: false }))).toBe(
        false,
      );
      expect(canAccess('finance.budget.edit', foreman())).toBe(false);
      expect(canAccess('finance.budget.edit', master())).toBe(false);
    });
  });

  describe('finance.payment.create', () => {
    it('owner, foreman, and permitted representative', () => {
      expect(canAccess('finance.payment.create', customer(true))).toBe(true);
      expect(canAccess('finance.payment.create', foreman())).toBe(true);
      expect(canAccess('finance.payment.create', representative({ canCreatePayments: true }))).toBe(
        true,
      );
      expect(
        canAccess('finance.payment.create', representative({ canCreatePayments: false })),
      ).toBe(false);
      expect(canAccess('finance.payment.create', master())).toBe(false);
    });
  });

  describe('tools.manage — customer invisible (ТЗ §1.4)', () => {
    it('customer cannot see/manage tools', () => {
      expect(canAccess('tools.manage', customer(true))).toBe(false);
    });
    it('foreman and master can', () => {
      expect(canAccess('tools.manage', foreman())).toBe(true);
      expect(canAccess('tools.manage', master())).toBe(true);
    });
    it('representative needs canManageTools', () => {
      expect(canAccess('tools.manage', representative({ canManageTools: true }))).toBe(true);
      expect(canAccess('tools.manage', representative({ canManageTools: false }))).toBe(false);
    });
  });

  describe('chat.read', () => {
    it('any member can read (matrix restricts by chat type separately)', () => {
      expect(canAccess('chat.read', foreman())).toBe(true);
      expect(canAccess('chat.read', master())).toBe(true);
      expect(canAccess('chat.read', customer(true))).toBe(true);
      expect(canAccess('chat.read', representative())).toBe(true);
    });
    it('non-member cannot', () => {
      expect(canAccess('chat.read', { userId: 'x', systemRole: 'customer' })).toBe(false);
    });
  });

  describe('step.add_substep', () => {
    it('any member can add (ТЗ §6.4)', () => {
      expect(canAccess('step.add_substep', foreman())).toBe(true);
      expect(canAccess('step.add_substep', master())).toBe(true);
      expect(canAccess('step.add_substep', customer(true))).toBe(true);
      expect(canAccess('step.add_substep', representative())).toBe(true);
    });
    it('non-member cannot', () => {
      expect(canAccess('step.add_substep', { userId: 'x', systemRole: 'customer' })).toBe(false);
    });
  });

  describe('step.manage — мастер только на назначенных этапах (ТЗ §6.4)', () => {
    it('foreman — всегда ок', () => {
      expect(canAccess('step.manage', foreman())).toBe(true);
    });
    it('master назначен на stage (stageForemanIds содержит его userId) — ok', () => {
      const ctx = { ...master(), stageForemanIds: ['u-mas'] };
      expect(canAccess('step.manage', ctx)).toBe(true);
    });
    it('master назначен непосредственно на шаг (stepAssigneeIds) — ok', () => {
      const ctx = { ...master(), stepAssigneeIds: ['u-mas'], stageForemanIds: [] };
      expect(canAccess('step.manage', ctx)).toBe(true);
    });
    it('master не назначен ни на этап, ни на шаг — 403', () => {
      const ctx = { ...master(), stageForemanIds: ['other'], stepAssigneeIds: ['other'] };
      expect(canAccess('step.manage', ctx)).toBe(false);
    });
    it('representative без canEditStages — 403', () => {
      expect(canAccess('step.manage', representative({ canEditStages: false }))).toBe(false);
    });
    it('representative с canEditStages — ok', () => {
      expect(canAccess('step.manage', representative({ canEditStages: true }))).toBe(true);
    });
  });

  describe('step.photo.upload', () => {
    it('owner, foreman, master — могут прикрепить фото', () => {
      expect(canAccess('step.photo.upload', customer(true))).toBe(true);
      expect(canAccess('step.photo.upload', foreman())).toBe(true);
      expect(canAccess('step.photo.upload', master())).toBe(true);
    });
    it('representative — только с canEditStages', () => {
      expect(canAccess('step.photo.upload', representative({ canEditStages: true }))).toBe(true);
      expect(canAccess('step.photo.upload', representative({ canEditStages: false }))).toBe(false);
    });
    it('не-участник — 403', () => {
      expect(canAccess('step.photo.upload', { userId: 'x', systemRole: 'customer' })).toBe(false);
    });
  });

  describe('tools.* — customer явно заблокирован (ТЗ §1.4)', () => {
    it('customer-owner НЕ видит инструмент', () => {
      expect(canAccess('tools.manage', customer(true))).toBe(false);
      expect(canAccess('tools.return', customer(true))).toBe(false);
      expect(canAccess('tools.issue', customer(true))).toBe(false);
    });
    it('foreman выдаёт и возвращает', () => {
      expect(canAccess('tools.issue', foreman())).toBe(true);
      expect(canAccess('tools.return', foreman())).toBe(true);
    });
    it('master не может выдавать (только foreman)', () => {
      expect(canAccess('tools.issue', master())).toBe(false);
    });
    it('master может инициировать возврат', () => {
      expect(canAccess('tools.return', master())).toBe(true);
    });
  });

  describe('selfpurchase.create / selfpurchase.confirm', () => {
    it('foreman и master могут создать самозакуп (gaps §4.3)', () => {
      expect(canAccess('selfpurchase.create', foreman())).toBe(true);
      expect(canAccess('selfpurchase.create', master())).toBe(true);
    });
    it('customer-owner и foreman могут подтвердить; rep — только с canApprove', () => {
      expect(canAccess('selfpurchase.confirm', customer(true))).toBe(true);
      expect(canAccess('selfpurchase.confirm', foreman())).toBe(true);
      expect(canAccess('selfpurchase.confirm', representative({ canApprove: true }))).toBe(true);
      expect(canAccess('selfpurchase.confirm', representative({ canApprove: false }))).toBe(false);
    });
    it('master не подтверждает (только создаёт)', () => {
      expect(canAccess('selfpurchase.confirm', master())).toBe(false);
    });
  });

  describe('note.manage / question.manage', () => {
    it('любой участник может (точечные права в сервисе)', () => {
      expect(canAccess('note.manage', foreman())).toBe(true);
      expect(canAccess('note.manage', master())).toBe(true);
      expect(canAccess('note.manage', customer(true))).toBe(true);
      expect(canAccess('note.manage', representative())).toBe(true);
      expect(canAccess('question.manage', foreman())).toBe(true);
    });
    it('не-участник — 403', () => {
      expect(canAccess('note.manage', { userId: 'x', systemRole: 'customer' })).toBe(false);
      expect(canAccess('question.manage', { userId: 'x', systemRole: 'customer' })).toBe(false);
    });
  });

  // ---------- S5: Chat actions ----------

  describe('chat.read', () => {
    it('admin → true', () => {
      expect(canAccess('chat.read', admin())).toBe(true);
    });
    it('no membership → false', () => {
      expect(canAccess('chat.read', { userId: 'x', systemRole: 'customer' })).toBe(false);
    });
    it('active participant → true', () => {
      const ctx: AccessContext = {
        ...customer(true),
        chatIsParticipant: true,
        chatIsActiveParticipant: true,
      };
      expect(canAccess('chat.read', ctx)).toBe(true);
    });
    it('left participant без visibility → false', () => {
      const ctx: AccessContext = {
        ...customer(true),
        chatIsParticipant: true,
        chatIsActiveParticipant: false,
        chatType: 'stage',
        chatVisibleToCustomer: false,
      };
      expect(canAccess('chat.read', ctx)).toBe(false);
    });
    it('customer-owner видит stage-chat если visibleToCustomer=true', () => {
      const ctx: AccessContext = {
        ...customer(true),
        chatIsParticipant: true,
        chatIsActiveParticipant: false,
        chatType: 'stage',
        chatVisibleToCustomer: true,
      };
      expect(canAccess('chat.read', ctx)).toBe(true);
    });
  });

  describe('chat.write', () => {
    it('active participant → true', () => {
      const ctx: AccessContext = { ...foreman(), chatIsActiveParticipant: true };
      expect(canAccess('chat.write', ctx)).toBe(true);
    });
    it('customer с visibility (read-only) → false (write запрещён)', () => {
      const ctx: AccessContext = {
        ...customer(true),
        chatIsParticipant: true,
        chatIsActiveParticipant: false,
        chatVisibleToCustomer: true,
      };
      expect(canAccess('chat.write', ctx)).toBe(false);
    });
    it('без membership → false', () => {
      expect(canAccess('chat.write', { userId: 'x', systemRole: 'customer' })).toBe(false);
    });
  });

  describe('chat.create_personal', () => {
    it('любой member', () => {
      expect(canAccess('chat.create_personal', customer(true))).toBe(true);
      expect(canAccess('chat.create_personal', foreman())).toBe(true);
      expect(canAccess('chat.create_personal', master())).toBe(true);
    });
    it('не-участник — 403', () => {
      expect(canAccess('chat.create_personal', { userId: 'x', systemRole: 'customer' })).toBe(
        false,
      );
    });
  });

  describe('chat.create_group', () => {
    it('owner, rep.canInviteMembers, foreman — OK', () => {
      expect(canAccess('chat.create_group', customer(true))).toBe(true);
      expect(canAccess('chat.create_group', representative({ canInviteMembers: true }))).toBe(true);
      expect(canAccess('chat.create_group', foreman())).toBe(true);
    });
    it('master — no', () => {
      expect(canAccess('chat.create_group', master())).toBe(false);
    });
    it('rep без canInviteMembers — no', () => {
      expect(canAccess('chat.create_group', representative())).toBe(false);
    });
  });

  describe('chat.toggle_customer_visibility', () => {
    it('foreman — creator чата — OK', () => {
      const ctx: AccessContext = { ...foreman(), chatCreatedById: 'u-for' };
      expect(canAccess('chat.toggle_customer_visibility', ctx)).toBe(true);
    });
    it('foreman не-creator — no', () => {
      const ctx: AccessContext = { ...foreman(), chatCreatedById: 'u-other' };
      expect(canAccess('chat.toggle_customer_visibility', ctx)).toBe(false);
    });
    it('customer — no', () => {
      expect(canAccess('chat.toggle_customer_visibility', customer(true))).toBe(false);
    });
  });

  describe('chat.moderate', () => {
    it('customer-owner — OK', () => {
      expect(canAccess('chat.moderate', customer(true))).toBe(true);
    });
    it('creator чата — OK', () => {
      const ctx: AccessContext = { ...foreman(), chatCreatedById: 'u-for' };
      expect(canAccess('chat.moderate', ctx)).toBe(true);
    });
    it('чужой — no', () => {
      expect(canAccess('chat.moderate', master())).toBe(false);
    });
  });

  // ---------- S5: Document actions ----------

  describe('document.read', () => {
    it('любой член проекта', () => {
      expect(canAccess('document.read', customer(true))).toBe(true);
      expect(canAccess('document.read', representative())).toBe(true);
      expect(canAccess('document.read', foreman())).toBe(true);
      expect(canAccess('document.read', master())).toBe(true);
    });
    it('не-член — no', () => {
      expect(canAccess('document.read', { userId: 'x', systemRole: 'customer' })).toBe(false);
    });
  });

  describe('document.write', () => {
    it('owner, rep.canEditStages, foreman, master — OK', () => {
      expect(canAccess('document.write', customer(true))).toBe(true);
      expect(canAccess('document.write', representative({ canEditStages: true }))).toBe(true);
      expect(canAccess('document.write', foreman())).toBe(true);
      expect(canAccess('document.write', master())).toBe(true);
    });
    it('rep без прав — no', () => {
      expect(canAccess('document.write', representative())).toBe(false);
    });
  });

  describe('document.delete', () => {
    it('owner — OK', () => {
      expect(canAccess('document.delete', customer(true))).toBe(true);
    });
    it('uploader-сам — OK', () => {
      const ctx: AccessContext = { ...foreman(), documentUploadedById: 'u-for' };
      expect(canAccess('document.delete', ctx)).toBe(true);
    });
    it('чужой foreman — no', () => {
      const ctx: AccessContext = { ...foreman(), documentUploadedById: 'u-other' };
      expect(canAccess('document.delete', ctx)).toBe(false);
    });
    it('master чужой документ — no', () => {
      expect(canAccess('document.delete', master())).toBe(false);
    });
  });

  // ---------- S5: Feed export ----------

  describe('feed.export', () => {
    it('owner и foreman — OK', () => {
      expect(canAccess('feed.export', customer(true))).toBe(true);
      expect(canAccess('feed.export', foreman())).toBe(true);
      expect(canAccess('feed.export', representative({ canSeeBudget: true }))).toBe(true);
    });
    it('master — no', () => {
      expect(canAccess('feed.export', master())).toBe(false);
    });
    it('rep без canSeeBudget — no', () => {
      expect(canAccess('feed.export', representative())).toBe(false);
    });
  });

  // ---------- S5: Notification settings ----------

  describe('notification.settings.self', () => {
    it('любой аутентифицированный — OK', () => {
      expect(canAccess('notification.settings.self', customer(true))).toBe(true);
      expect(canAccess('notification.settings.self', foreman())).toBe(true);
      expect(canAccess('notification.settings.self', master())).toBe(true);
      expect(canAccess('notification.settings.self', { userId: 'x', systemRole: 'customer' })).toBe(
        true,
      );
    });
  });

  // ---------- S5: Feedback ----------

  describe('feedback.create', () => {
    it('любой аутентифицированный — OK', () => {
      expect(canAccess('feedback.create', customer(true))).toBe(true);
      expect(canAccess('feedback.create', master())).toBe(true);
      expect(canAccess('feedback.create', { userId: 'x', systemRole: 'customer' })).toBe(true);
    });
  });

  // ---------- S5: Admin-only ----------

  describe('admin.*', () => {
    it('admin имеет все admin.* права', () => {
      expect(canAccess('admin.templates.manage', admin())).toBe(true);
      expect(canAccess('admin.faq.manage', admin())).toBe(true);
      expect(canAccess('admin.feedback.read', admin())).toBe(true);
      expect(canAccess('admin.settings.manage', admin())).toBe(true);
      expect(canAccess('admin.notifications.inspect', admin())).toBe(true);
    });
    it('не-admin — все запрещено', () => {
      expect(canAccess('admin.templates.manage', customer(true))).toBe(false);
      expect(canAccess('admin.faq.manage', foreman())).toBe(false);
      expect(canAccess('admin.feedback.read', representative({ canApprove: true }))).toBe(false);
      expect(canAccess('admin.settings.manage', master())).toBe(false);
      expect(canAccess('admin.notifications.inspect', foreman())).toBe(false);
    });
  });
});

describe('mergeRepresentativeRights', () => {
  it('fills defaults and overrides', () => {
    const merged = mergeRepresentativeRights(undefined, { canApprove: true });
    expect(merged.canApprove).toBe(true);
    expect(merged.canEditStages).toBe(false);
    expect(merged.canSeeBudget).toBe(false);
  });
  it('override takes precedence over base', () => {
    const merged = mergeRepresentativeRights({ canApprove: false }, { canApprove: true });
    expect(merged.canApprove).toBe(true);
  });
});
