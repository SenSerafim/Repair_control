import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  HttpException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';

export class DomainError extends HttpException {
  constructor(status: number, code: string, message: string, details?: Record<string, unknown>) {
    super({ code, message, details }, status);
  }
}

export class InvalidInputError extends BadRequestException {
  constructor(code: string, message: string, details?: Record<string, unknown>) {
    super({ code, message, details });
  }
}

export class AuthError extends UnauthorizedException {
  constructor(code: string, message: string) {
    super({ code, message });
  }
}

export class ForbiddenError extends ForbiddenException {
  constructor(code: string, message: string) {
    super({ code, message });
  }
}

export class NotFoundError extends NotFoundException {
  constructor(code: string, message: string) {
    super({ code, message });
  }
}

export class ConflictError extends ConflictException {
  constructor(code: string, message: string) {
    super({ code, message });
  }
}

export const ErrorCodes = {
  INVALID_CREDENTIALS: 'auth.invalid_credentials',
  LOGIN_BLOCKED: 'auth.login_blocked',
  PHONE_IN_USE: 'auth.phone_in_use',
  TOKEN_INVALID: 'auth.token_invalid',
  TOKEN_EXPIRED: 'auth.token_expired',
  SESSION_REVOKED: 'auth.session_revoked',
  RECOVERY_INVALID_CODE: 'auth.recovery_invalid_code',
  RECOVERY_EXPIRED: 'auth.recovery_expired',
  RECOVERY_BLOCKED: 'auth.recovery_blocked',
  ROLE_ALREADY_HAS: 'users.role_already_has',
  ROLE_NOT_FOUND: 'users.role_not_found',
  ROLE_CANNOT_REMOVE_LAST: 'users.role_cannot_remove_last',
  PROJECT_NOT_FOUND: 'projects.not_found',
  PROJECT_ARCHIVED: 'projects.archived',
  PROJECT_SELF_FOREMAN_FORBIDDEN: 'projects.self_foreman_forbidden',
  MEMBERSHIP_EXISTS: 'projects.membership_exists',
  MEMBERSHIP_NOT_FOUND: 'projects.membership_not_found',
  STAGE_NOT_FOUND: 'stages.not_found',
  STAGE_INVALID_TRANSITION: 'stages.invalid_transition',
  STAGE_PAUSE_REQUIRES_REASON: 'stages.pause_requires_reason',
  STAGE_NOT_PAUSED: 'stages.not_paused',
  TEMPLATE_NOT_FOUND: 'templates.not_found',
  FORBIDDEN: 'common.forbidden',
} as const;
