import { RepresentativeRights } from './rbac.types';

export const DEFAULT_REPRESENTATIVE_RIGHTS: RepresentativeRights = {
  canEditStages: false,
  canApprove: false,
  canSeeBudget: false,
  canAddRepresentative: false,
  canCreatePayments: false,
  canManageMaterials: false,
  canManageTools: false,
  canInviteMembers: false,
};

export const sanitizeRepresentativeRights = (
  input: Record<string, unknown> | undefined,
): RepresentativeRights => {
  const result: RepresentativeRights = { ...DEFAULT_REPRESENTATIVE_RIGHTS };
  if (!input) return result;
  for (const key of Object.keys(DEFAULT_REPRESENTATIVE_RIGHTS) as (keyof RepresentativeRights)[]) {
    if (typeof input[key] === 'boolean') {
      result[key] = input[key] as boolean;
    }
  }
  return result;
};
