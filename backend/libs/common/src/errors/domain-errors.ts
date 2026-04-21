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
  STEP_NOT_FOUND: 'steps.not_found',
  STEP_INVALID_STATUS: 'steps.invalid_status',
  STEP_INVALID_ASSIGNEE: 'steps.invalid_assignee',
  STEP_REORDER_MISMATCH: 'steps.reorder_mismatch',
  STEP_TITLE_REQUIRED: 'steps.title_required',
  STEP_EXTRA_REQUIRES_PRICE: 'steps.extra_requires_price',
  SUBSTEP_NOT_FOUND: 'substeps.not_found',
  SUBSTEP_EDIT_AUTHOR_ONLY: 'substeps.edit_author_only',
  PHOTO_NOT_FOUND: 'photos.not_found',
  PHOTO_INVALID_MIME: 'photos.invalid_mime',
  PHOTO_TOO_LARGE: 'photos.too_large',
  NOTE_NOT_FOUND: 'notes.not_found',
  NOTE_AUTHOR_ONLY: 'notes.author_only',
  NOTE_INVALID_SCOPE: 'notes.invalid_scope',
  NOTE_ADDRESSEE_REQUIRED: 'notes.addressee_required',
  NOTE_STAGE_REQUIRED: 'notes.stage_required',
  QUESTION_NOT_FOUND: 'questions.not_found',
  QUESTION_ADDRESSEE_ONLY: 'questions.addressee_only',
  QUESTION_ALREADY_ANSWERED: 'questions.already_answered',
  QUESTION_ALREADY_CLOSED: 'questions.already_closed',
  QUESTION_AUTHOR_ONLY_CLOSE: 'questions.author_only_close',
  APPROVAL_NOT_FOUND: 'approvals.not_found',
  APPROVAL_INVALID_SCOPE: 'approvals.invalid_scope',
  APPROVAL_INVALID_STATUS: 'approvals.invalid_status',
  APPROVAL_ADDRESSEE_REQUIRED: 'approvals.addressee_required',
  APPROVAL_DECIDE_FORBIDDEN: 'approvals.decide_forbidden',
  APPROVAL_REJECT_COMMENT_REQUIRED: 'approvals.reject_comment_required',
  APPROVAL_CUSTOMER_BYPASS_FOREMAN: 'approvals.customer_bypass_foreman',
  APPROVAL_RESUBMIT_AUTHOR_ONLY: 'approvals.resubmit_author_only',
  APPROVAL_RESUBMIT_INVALID_STATUS: 'approvals.resubmit_invalid_status',
  APPROVAL_CANCEL_AUTHOR_ONLY: 'approvals.cancel_author_only',
  APPROVAL_CANCEL_INVALID_STATUS: 'approvals.cancel_invalid_status',
  APPROVAL_PLAN_NOT_APPROVED: 'approvals.plan_not_approved',
  APPROVAL_STAGE_NOT_IN_REVIEW: 'approvals.stage_not_in_review',
  APPROVAL_DEADLINE_IN_PAST: 'approvals.deadline_in_past',
  METHODOLOGY_SECTION_NOT_FOUND: 'methodology.section_not_found',
  METHODOLOGY_ARTICLE_NOT_FOUND: 'methodology.article_not_found',
  METHODOLOGY_ADMIN_ONLY: 'methodology.admin_only',
  METHODOLOGY_SEARCH_QUERY_REQUIRED: 'methodology.search_query_required',
} as const;
