import { RepresentativeRights } from './rbac.types';

/**
 * Дефолтные права представителя — все false (read-only-доступ к проекту + чат-write,
 * см. P7.3 / решение раунд 1).
 *
 * canArchive намеренно отсутствует: архивирование проекта — эксклюзив заказчика
 * (П7.1, П10.4). Любая попытка прокинуть это поле через JSON будет проигнорирована
 * sanitize-функцией ниже.
 */
export const DEFAULT_REPRESENTATIVE_RIGHTS: Required<Omit<RepresentativeRights, 'canArchive'>> = {
  canEditStages: false,
  canApprove: false,
  canSeeBudget: false,
  canAddRepresentative: false,
  canCreatePayments: false,
  canManageMaterials: false,
  canManageTools: false,
  canInviteMembers: false,
  canCreateStages: false,
  canManageTeam: false,
};

export const sanitizeRepresentativeRights = (
  input: Record<string, unknown> | undefined,
): RepresentativeRights => {
  const result: RepresentativeRights = { ...DEFAULT_REPRESENTATIVE_RIGHTS };
  if (!input) return result;
  for (const key of Object.keys(
    DEFAULT_REPRESENTATIVE_RIGHTS,
  ) as (keyof typeof DEFAULT_REPRESENTATIVE_RIGHTS)[]) {
    if (typeof input[key] === 'boolean') {
      (result as Record<string, boolean>)[key] = input[key] as boolean;
    }
  }
  return result;
};
