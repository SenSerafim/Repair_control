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
