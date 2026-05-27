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
      expect(canAccess('tools.claim', admin())).toBe(true);
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

  describe('project.edit', () => {
    it('owner-customer can edit', () => {
      expect(canAccess('project.edit', customer(true))).toBe(true);
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

  describe('project.archive (П7.1 / П10.4 — эксклюзив заказчика)', () => {
    it('owner-customer can archive', () => {
      expect(canAccess('project.archive', customer(true))).toBe(true);
    });
    it('non-owner customer cannot archive someone else project', () => {
      expect(canAccess('project.archive', customer(false))).toBe(false);
    });
    it('representative cannot archive even with all rights', () => {
      expect(
        canAccess(
          'project.archive',
          representative({ canEditStages: true, canApprove: true, canManageTeam: true }),
        ),
      ).toBe(false);
    });
    it('foreman/master cannot archive', () => {
      expect(canAccess('project.archive', foreman())).toBe(false);
      expect(canAccess('project.archive', master())).toBe(false);
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
    it('representative with canManageTeam (П2.12) — also OK', () => {
      expect(canAccess('project.invite_member', representative({ canManageTeam: true }))).toBe(
        true,
      );
    });
    it('foreman can invite (restricted to master role inside service)', () => {
      expect(canAccess('project.invite_member', foreman())).toBe(true);
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

  describe('finance.payment.create_advance', () => {
    it('owner-customer and representative.canCreatePayments may create advance from budget; foreman/master cannot', () => {
      expect(canAccess('finance.payment.create_advance', customer(true))).toBe(true);
      expect(
        canAccess('finance.payment.create_advance', representative({ canCreatePayments: true })),
      ).toBe(true);
      expect(
        canAccess('finance.payment.create_advance', representative({ canCreatePayments: false })),
      ).toBe(false);
      expect(canAccess('finance.payment.create_advance', foreman())).toBe(false);
      expect(canAccess('finance.payment.create_advance', master())).toBe(false);
    });
  });

  describe('finance.payment.distribute', () => {
    it('only foreman can distribute; customer/representative/master cannot', () => {
      expect(canAccess('finance.payment.distribute', foreman())).toBe(true);
      expect(canAccess('finance.payment.distribute', customer(true))).toBe(false);
      expect(
        canAccess('finance.payment.distribute', representative({ canCreatePayments: true })),
      ).toBe(false);
      expect(canAccess('finance.payment.distribute', master())).toBe(false);
    });
  });

  describe('tools.* — self-custody (2026-05-12)', () => {
    it('любой member видит / добавляет / claim-ит', () => {
      for (const action of ['tools.view_project', 'tools.add_to_project', 'tools.claim'] as const) {
        expect(canAccess(action, customer(true))).toBe(true);
        expect(canAccess(action, representative())).toBe(true);
        expect(canAccess(action, foreman())).toBe(true);
        expect(canAccess(action, master())).toBe(true);
      }
    });
    it('не-участник проекта — 403', () => {
      expect(canAccess('tools.claim', { userId: 'x', systemRole: 'customer' })).toBe(false);
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

  describe('chat.create_personal / chat.create_group (П1.6 — выкинуты из MVP)', () => {
    it('личные чаты создавать никому нельзя', () => {
      expect(canAccess('chat.create_personal', customer(true))).toBe(false);
      expect(canAccess('chat.create_personal', foreman())).toBe(false);
      expect(canAccess('chat.create_personal', master())).toBe(false);
      expect(canAccess('chat.create_personal', representative({ canInviteMembers: true }))).toBe(
        false,
      );
    });
    it('групповые чаты создавать никому нельзя', () => {
      expect(canAccess('chat.create_group', customer(true))).toBe(false);
      expect(canAccess('chat.create_group', foreman())).toBe(false);
      expect(canAccess('chat.create_group', master())).toBe(false);
      expect(canAccess('chat.create_group', representative({ canInviteMembers: true }))).toBe(
        false,
      );
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
    it('rep с canEditStages — OK', () => {
      expect(canAccess('document.delete', representative({ canEditStages: true }))).toBe(true);
    });
    it('rep без canEditStages — no', () => {
      expect(canAccess('document.delete', representative())).toBe(false);
    });
    it('автор-foreman не может удалить свой документ (общая папка)', () => {
      const ctx: AccessContext = { ...foreman(), documentUploadedById: 'u-for' };
      expect(canAccess('document.delete', ctx)).toBe(false);
    });
    it('автор-master не может удалить свой документ', () => {
      const ctx: AccessContext = { ...master(), documentUploadedById: 'u-mas' };
      expect(canAccess('document.delete', ctx)).toBe(false);
    });
    it('master чужой документ — no', () => {
      expect(canAccess('document.delete', master())).toBe(false);
    });
  });

  // ---------- S5: Feed export ----------

  describe('feed.export', () => {
    it('любой участник проекта — OK (объём данных в сводке фильтруется по роли)', () => {
      expect(canAccess('feed.export', customer(true))).toBe(true);
      expect(canAccess('feed.export', foreman())).toBe(true);
      expect(canAccess('feed.export', master())).toBe(true);
      expect(canAccess('feed.export', representative({ canSeeBudget: true }))).toBe(true);
      expect(canAccess('feed.export', representative())).toBe(true);
    });
    it('outsider без membership — нет', () => {
      const outsider: AccessContext = { userId: 'u-out', systemRole: 'master' };
      expect(canAccess('feed.export', outsider)).toBe(false);
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

describe('materials.mark_delivered / materials.accept (E1a — ТЗ NEWFIX §5.7)', () => {
  describe('materials.mark_delivered (любой active member)', () => {
    it('owner-customer может', () => {
      expect(canAccess('materials.mark_delivered', customer(true))).toBe(true);
    });
    it('foreman может', () => {
      expect(canAccess('materials.mark_delivered', foreman())).toBe(true);
    });
    it('master может (он первый принимает материал)', () => {
      expect(canAccess('materials.mark_delivered', master())).toBe(true);
    });
    it('representative может (даже без специальных rights)', () => {
      expect(canAccess('materials.mark_delivered', representative())).toBe(true);
    });
    it('non-owner customer без membership — не может', () => {
      const noMember: AccessContext = {
        userId: 'u-stranger',
        systemRole: 'customer',
        projectOwnerId: 'u-other',
      };
      expect(canAccess('materials.mark_delivered', noMember)).toBe(false);
    });
  });

  describe('materials.accept (foreman / customer-owner / representative с canApprove)', () => {
    it('owner-customer может', () => {
      expect(canAccess('materials.accept', customer(true))).toBe(true);
    });
    it('foreman может', () => {
      expect(canAccess('materials.accept', foreman())).toBe(true);
    });
    it('master НЕ может — мастер только фиксирует доставку, не принимает', () => {
      expect(canAccess('materials.accept', master())).toBe(false);
    });
    it('representative с canApprove — может', () => {
      expect(canAccess('materials.accept', representative({ canApprove: true }))).toBe(true);
    });
    it('representative без canApprove — НЕ может', () => {
      expect(canAccess('materials.accept', representative({ canApprove: false }))).toBe(false);
    });
    it('admin — bypass', () => {
      expect(canAccess('materials.accept', admin())).toBe(true);
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
