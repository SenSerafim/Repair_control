import { SetMetadata } from '@nestjs/common';
import { DomainAction } from './rbac.types';

export const REQUIRE_ACCESS_KEY = 'rbac.require_access';

export interface AccessRequirement {
  action: DomainAction;
  /**
   * Имя параметра запроса (body/params/query), по которому достаётся идентификатор ресурса (projectId, stageId, ...).
   * AccessGuard по этому id вытянет контекст через loader.
   */
  resourceIdFrom?: { source: 'params' | 'body' | 'query'; key: string };
  resource?:
    | 'project'
    | 'stage'
    | 'step'
    | 'material_request'
    | 'selfpurchase'
    | 'tool_issuance'
    | 'none';
}

export const RequireAccess = (requirement: AccessRequirement) =>
  SetMetadata(REQUIRE_ACCESS_KEY, requirement);
