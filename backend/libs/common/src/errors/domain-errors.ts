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
  PAYMENT_NOT_FOUND: 'payments.not_found',
  PAYMENT_INVALID_RECIPIENT: 'payments.invalid_recipient',
  PAYMENT_INVALID_STATUS: 'payments.invalid_status',
  PAYMENT_PARENT_NOT_CONFIRMED: 'payments.parent_not_confirmed',
  PAYMENT_NOT_PENDING: 'payments.not_pending',
  PAYMENT_CONFIRM_FORBIDDEN: 'payments.confirm_forbidden',
  PAYMENT_DISPUTE_FORBIDDEN: 'payments.dispute_forbidden',
  PAYMENT_CANCEL_FORBIDDEN: 'payments.cancel_forbidden',
  PAYMENT_DISTRIBUTE_FORBIDDEN: 'payments.distribute_forbidden',
  PAYMENT_AMOUNT_INVALID: 'payments.amount_invalid',
  MATERIAL_REQUEST_NOT_FOUND: 'materials.not_found',
  MATERIAL_ITEM_NOT_FOUND: 'materials.item_not_found',
  MATERIAL_INVALID_STATUS: 'materials.invalid_status',
  MATERIAL_PRICE_REQUIRED: 'materials.price_required',
  MATERIAL_CONFIRM_FORBIDDEN: 'materials.confirm_forbidden',
  MATERIAL_AUTHOR_ONLY_SEND: 'materials.author_only_send',
  MATERIAL_FINALIZE_NOT_OPEN: 'materials.finalize_not_open',
  IDEMPOTENCY_MISMATCH: 'idempotency.request_mismatch',
  IDEMPOTENCY_MISSING_USER: 'idempotency.missing_user',
  SELFPURCHASE_NOT_FOUND: 'selfpurchase.not_found',
  SELFPURCHASE_ADDRESSEE_ONLY: 'selfpurchase.addressee_only',
  SELFPURCHASE_INVALID_STATUS: 'selfpurchase.invalid_status',
  SELFPURCHASE_REJECT_COMMENT_REQUIRED: 'selfpurchase.reject_comment_required',
  SELFPURCHASE_NO_FOREMAN_ON_STAGE: 'selfpurchase.no_foreman_on_stage',
  SELFPURCHASE_INVALID_ACTOR: 'selfpurchase.invalid_actor',
  TOOL_NOT_FOUND: 'tools.not_found',
  TOOL_ACCESS_DENIED: 'tools.access_denied',
  TOOL_INSUFFICIENT_QTY: 'tools.insufficient_qty',
  TOOL_ISSUANCE_NOT_FOUND: 'tools.issuance_not_found',
  TOOL_ISSUANCE_INVALID_STATUS: 'tools.issuance_invalid_status',
  TOOL_CONFIRM_MASTER_ONLY: 'tools.confirm_master_only',
  TOOL_RETURN_MASTER_ONLY: 'tools.return_master_only',
  TOOL_RETURN_CONFIRM_OWNER_ONLY: 'tools.return_confirm_owner_only',
  TOOL_RETURN_QTY_INVALID: 'tools.return_qty_invalid',
  TOOL_OWNER_NOT_FOREMAN: 'tools.owner_not_foreman',
} as const;
