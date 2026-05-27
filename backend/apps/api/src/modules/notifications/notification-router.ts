import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { FeedEventKind, NotificationKind } from '@prisma/client';
import { PrismaService } from '@app/common';
import { NotificationsService } from './notifications.service';

/**
 * Подписчик на feed-события: для каждого FeedEvent решает, кому и какой push отправить.
 * Использует @OnEvent('feed.emitted') (эмитит FeedService) как триггер.
 */
@Injectable()
export class NotificationRouter {
  private readonly logger = new Logger(NotificationRouter.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  @OnEvent('feed.emitted')
  async onFeedEmitted(ev: {
    kind: FeedEventKind;
    projectId: string | null;
    actorId: string | null;
    payload: Record<string, unknown>;
  }): Promise<void> {
    try {
      await this.fanOut(ev);
    } catch (e) {
      this.logger.error(`router failed for ${ev.kind}: ${(e as Error).message}`);
    }
  }

  async fanOut(ev: {
    kind: FeedEventKind;
    projectId: string | null;
    actorId: string | null;
    payload: Record<string, unknown>;
  }): Promise<void> {
    const mapping = MAPPINGS[ev.kind];
    if (!mapping) return;
    const { kind: notificationKind, recipients, enrich } = mapping;
    const userIds = await recipients(ev, this.prisma);
    const unique = Array.from(new Set(userIds.filter((u) => u && u !== ev.actorId)));
    if (unique.length === 0) return;
    let extra: Record<string, unknown> = {};
    if (enrich) {
      try {
        extra = await enrich(ev, this.prisma);
      } catch (e) {
        // Энричер — best-effort. Если не смогли дотянуть метки, рендерим
        // с исходным payload (шаблоны имеют fallback).
        this.logger.warn(`enrich failed for ${ev.kind}: ${(e as Error).message}`);
      }
    }
    const payload = { ...ev.payload, ...extra };
    await this.notifications.dispatch({
      userIds: unique,
      kind: notificationKind,
      projectId: ev.projectId,
      payload,
      deepLink: buildDeepLink({ ...ev, payload }),
    });
  }
}

type RecipientResolver = (
  ev: {
    kind: FeedEventKind;
    projectId: string | null;
    actorId: string | null;
    payload: Record<string, unknown>;
  },
  prisma: PrismaService,
) => Promise<string[]>;

/**
 * Опциональный энричер payload. Возвращает дополнительные ключи, которые
 * мерджатся поверх `ev.payload` перед рендером шаблона. Нужен там, где emit-сайт
 * не знает русских меток (scope, decision, toolName) — роутер дотягивает их сам.
 */
type PayloadEnricher = (
  ev: {
    kind: FeedEventKind;
    projectId: string | null;
    actorId: string | null;
    payload: Record<string, unknown>;
  },
  prisma: PrismaService,
) => Promise<Record<string, unknown>>;

interface RoutingRule {
  kind: NotificationKind;
  recipients: RecipientResolver;
  enrich?: PayloadEnricher;
}

// ----- Recipients -----

const projectMembers: RecipientResolver = async (ev, prisma) => {
  if (!ev.projectId) return [];
  const project = await prisma.project.findUnique({
    where: { id: ev.projectId },
    select: { ownerId: true, memberships: { select: { userId: true } } },
  });
  if (!project) return [];
  return [project.ownerId, ...project.memberships.map((m) => m.userId)];
};

const projectOwnerAndReps: RecipientResolver = async (ev, prisma) => {
  if (!ev.projectId) return [];
  const project = await prisma.project.findUnique({
    where: { id: ev.projectId },
    select: { ownerId: true, memberships: { select: { userId: true, role: true } } },
  });
  if (!project) return [];
  return [
    project.ownerId,
    ...project.memberships.filter((m) => m.role === 'representative').map((m) => m.userId),
  ];
};

const chatParticipantsExceptAuthor: RecipientResolver = async (ev, prisma) => {
  const chatId = (ev.payload as any)?.chatId;
  if (!chatId) return [];
  const participants = await prisma.chatParticipant.findMany({
    where: { chatId, leftAt: null },
    select: { userId: true },
  });
  return participants.map((p) => p.userId);
};

const addresseeFromPayload: RecipientResolver = async (ev) => {
  const ids: string[] = [];
  const a = (ev.payload as any)?.addresseeId;
  if (typeof a === 'string') ids.push(a);
  return ids;
};

/**
 * Резолвер для membership_added/removed/left. Members-feed-события несут
 * `userId` (затронутого участника), а не `addresseeId` — это исторически
 * разная конвенция payload-полей. Без этого резолвера push по «вас добавили
 * в проект» / «вас удалили из проекта» вообще не дошёл бы до пользователя.
 */
const membershipUserFromPayload: RecipientResolver = async (ev) => {
  const u = (ev.payload as any)?.userId;
  return typeof u === 'string' ? [u] : [];
};

const requesterFromPayload: RecipientResolver = async (ev) => {
  const r = (ev.payload as any)?.requestedById;
  return typeof r === 'string' ? [r] : [];
};

const forwardedToOwnerFromPayload: RecipientResolver = async (ev) => {
  const ownerId = (ev.payload as any)?.forwardedToOwnerId;
  return typeof ownerId === 'string' ? [ownerId] : [];
};

const paymentParties: RecipientResolver = async (ev, prisma) => {
  const paymentId = (ev.payload as any)?.paymentId;
  if (!paymentId) return [];
  const p = await prisma.payment.findUnique({
    where: { id: paymentId },
    select: { fromUserId: true, toUserId: true, projectId: true },
  });
  if (!p) return [];
  const project = await prisma.project.findUnique({
    where: { id: p.projectId },
    select: { ownerId: true },
  });
  return [p.fromUserId, p.toUserId, project?.ownerId].filter(Boolean) as string[];
};

const exportRequester: RecipientResolver = async (ev, prisma) => {
  const jobId = (ev.payload as any)?.jobId;
  if (!jobId) return [];
  const job = await prisma.exportJob.findUnique({
    where: { id: jobId },
    select: { requestedById: true },
  });
  return job ? [job.requestedById] : [];
};

const stageMasterFromPayload: RecipientResolver = async (ev) => {
  const id = (ev.payload as any)?.masterUserId;
  return typeof id === 'string' && id ? [id] : [];
};

const stageForemanIdFromPayload: RecipientResolver = async (ev) => {
  const id = (ev.payload as any)?.foremanUserId;
  return typeof id === 'string' && id ? [id] : [];
};

const approvalAddresseeFromDb: RecipientResolver = async (ev, prisma) => {
  const id = (ev.payload as any)?.approvalId;
  if (typeof id !== 'string' || !id) return [];
  const a = await prisma.approval.findUnique({
    where: { id },
    select: { addresseeId: true },
  });
  return a?.addresseeId ? [a.addresseeId] : [];
};

const selfPurchaseAuthor: RecipientResolver = async (ev, prisma) => {
  const id = (ev.payload as any)?.selfPurchaseId;
  if (typeof id !== 'string' || !id) return [];
  const sp = await prisma.selfPurchase.findUnique({
    where: { id },
    select: { byUserId: true },
  });
  return sp?.byUserId ? [sp.byUserId] : [];
};

/**
 * Все участники проекта кроме actor-а — для tool custody fan-out.
 * actor отсекается на этапе `unique` в fanOut.
 */
const projectMembersAll: RecipientResolver = projectMembers;

// ----- Payload enrichers (дотягивают ru-метки в payload для шаблонов) -----

const enrichApprovalScope: PayloadEnricher = async (ev, prisma) => {
  const id = (ev.payload as any)?.approvalId;
  if (typeof id !== 'string' || !id) return {};
  const a = await prisma.approval.findUnique({
    where: { id },
    select: { scope: true },
  });
  return a ? { scope: a.scope } : {};
};

const enrichScopeFixed =
  (scope: string): PayloadEnricher =>
  async () => ({ scope });

const enrichSelfPurchaseScope: PayloadEnricher = async () => ({ scope: 'self_purchase' });

const enrichStageTitle: PayloadEnricher = async (ev, prisma) => {
  const id = (ev.payload as any)?.stageId;
  if (typeof id !== 'string' || !id) return {};
  const stage = await prisma.stage.findUnique({
    where: { id },
    select: { title: true },
  });
  return stage?.title ? { stageTitle: stage.title } : {};
};

const enrichStepTitle: PayloadEnricher = async (ev, prisma) => {
  const id = (ev.payload as any)?.stepId;
  if (typeof id !== 'string' || !id) return {};
  const step = await prisma.step.findUnique({
    where: { id },
    select: { title: true },
  });
  return step?.title ? { stepTitle: step.title } : {};
};

const enrichMaterialRequestTitle: PayloadEnricher = async (ev, prisma) => {
  const id = (ev.payload as any)?.requestId;
  if (typeof id !== 'string' || !id) return {};
  const r = await prisma.materialRequest.findUnique({
    where: { id },
    select: { title: true },
  });
  return r?.title ? { title: r.title } : {};
};

const enrichNotePreview: PayloadEnricher = async (ev, prisma) => {
  const id = (ev.payload as any)?.noteId;
  if (typeof id !== 'string' || !id) return {};
  const n = await prisma.note.findUnique({
    where: { id },
    select: { text: true },
  });
  if (!n?.text) return {};
  return { preview: n.text.slice(0, 120) };
};

const enrichQuestionPreview: PayloadEnricher = async (ev, prisma) => {
  const id = (ev.payload as any)?.questionId;
  if (typeof id !== 'string' || !id) return {};
  const q = await prisma.question.findUnique({
    where: { id },
    select: { text: true },
  });
  if (!q?.text) return {};
  return { preview: q.text.slice(0, 120) };
};

const enrichChatMessagePreview: PayloadEnricher = async (ev, prisma) => {
  const id = (ev.payload as any)?.messageId;
  if (typeof id !== 'string' || !id) return {};
  const m = await prisma.chatMessage.findUnique({
    where: { id },
    select: { text: true },
  });
  if (!m?.text) return {};
  return { preview: m.text.slice(0, 120) };
};

const enrichProjectTitle: PayloadEnricher = async (ev, prisma) => {
  if (!ev.projectId) return {};
  const p = await prisma.project.findUnique({
    where: { id: ev.projectId },
    select: { title: true },
  });
  return p?.title ? { projectTitle: p.title, title: p.title } : {};
};

/**
 * Дотягивает имя нового holder-а инструмента, чтобы шаблон отрендерился
 * корректным «Вася забрал <инструмент>».
 */
const enrichCustodyHolder: PayloadEnricher = async (ev, prisma) => {
  const id = (ev.payload as any)?.holderId;
  if (typeof id !== 'string' || !id) return {};
  const u = await prisma.user.findUnique({
    where: { id },
    select: { firstName: true, lastName: true },
  });
  if (!u) return {};
  return { holderName: `${u.firstName} ${u.lastName}`.trim() };
};

const enrichStageTitleAsTitle: PayloadEnricher = async (ev, prisma) => {
  const extras = await enrichStageTitle(ev, prisma);
  const title = (extras as Record<string, unknown>).stageTitle;
  return title ? { ...extras, title } : extras;
};

// ----- Routing table -----

const MAPPINGS: Partial<Record<FeedEventKind, RoutingRule>> = {
  // ---- Approvals (lifecycle) ----
  approval_requested: {
    kind: 'approval_requested',
    recipients: addresseeFromPayload,
    enrich: enrichApprovalScope,
  },
  approval_approved: {
    kind: 'approval_approved',
    recipients: requesterFromPayload,
    enrich: enrichApprovalScope,
  },
  approval_rejected: {
    kind: 'approval_rejected',
    recipients: requesterFromPayload,
    enrich: enrichApprovalScope,
  },
  // Повторная подача — снова требуется решение адресата.
  approval_resubmitted: {
    kind: 'approval_requested',
    recipients: approvalAddresseeFromDb,
    enrich: enrichApprovalScope,
  },
  // План одобрен — оповещаем всю команду проекта.
  plan_approved: {
    kind: 'approval_approved',
    recipients: projectMembers,
    enrich: enrichScopeFixed('plan'),
  },
  // Дедлайн перенесён — оповещаем всю команду проекта.
  deadline_changed: {
    kind: 'approval_approved',
    recipients: projectMembers,
    enrich: enrichScopeFixed('deadline_change'),
  },
  // ---- Payments ----
  payment_created: { kind: 'payment_created', recipients: paymentParties },
  // ---- Stages ----
  stage_rejected_by_customer: { kind: 'stage_rejected_by_customer', recipients: projectMembers },
  stage_deadline_exceeds_project: {
    kind: 'stage_deadline_exceeds_project',
    recipients: projectOwnerAndReps,
  },
  // ---- Materials ----
  material_request_created: {
    kind: 'material_request_created',
    recipients: projectMembers,
    enrich: enrichMaterialRequestTitle,
  },
  material_delivered: {
    kind: 'material_delivered',
    recipients: projectMembers,
    enrich: enrichMaterialRequestTitle,
  },
  // E1a — ТЗ NEWFIX §5.7: уведомления о состоянии приёмки.
  material_request_accepted_partial: {
    kind: 'material_request_accepted_partial',
    recipients: projectMembers,
    enrich: enrichMaterialRequestTitle,
  },
  material_request_accepted_full: {
    kind: 'material_request_accepted_full',
    recipients: projectMembers,
    enrich: enrichMaterialRequestTitle,
  },
  // ТЗ NEWFIX §5.5: эмитится из MaterialsScheduler один раз в день для каждой
  // заявки, у которой dueDate прошёл, а статус всё ещё open.
  material_request_overdue: {
    kind: 'material_request_overdue',
    recipients: projectMembers,
    enrich: enrichMaterialRequestTitle,
  },
  // ---- Self-purchases ----
  selfpurchase_created: { kind: 'selfpurchase_created', recipients: addresseeFromPayload },
  selfpurchase_forwarded: {
    kind: 'selfpurchase_created',
    recipients: forwardedToOwnerFromPayload,
  },
  selfpurchase_approved: {
    kind: 'approval_approved',
    recipients: selfPurchaseAuthor,
    enrich: enrichSelfPurchaseScope,
  },
  selfpurchase_rejected: {
    kind: 'approval_rejected',
    recipients: selfPurchaseAuthor,
    enrich: enrichSelfPurchaseScope,
  },
  // ---- Tools (self-custody, 2026-05-12) ----
  // tool_custody_changed: кто-то self-claim-нул инструмент → нотифицируем
  // всех участников проекта (кроме самого actor-а, его отсекает fanOut).
  tool_custody_changed: {
    kind: 'tool_custody_changed',
    recipients: projectMembersAll,
    enrich: enrichCustodyHolder,
  },
  // ---- Chat / collaboration ----
  chat_message_sent: {
    kind: 'chat_message_new',
    recipients: chatParticipantsExceptAuthor,
    enrich: enrichChatMessagePreview,
  },
  step_completed: {
    kind: 'step_completed',
    recipients: projectOwnerAndReps,
    enrich: enrichStepTitle,
  },
  stage_accepted: {
    kind: 'stage_completed',
    recipients: projectMembers,
    enrich: enrichStageTitle,
  },
  stage_paused: {
    kind: 'stage_paused',
    recipients: projectOwnerAndReps,
    enrich: enrichStageTitle,
  },
  note_created: {
    kind: 'note_created_for_me',
    recipients: addresseeFromPayload,
    enrich: enrichNotePreview,
  },
  question_asked: {
    kind: 'question_asked',
    recipients: addresseeFromPayload,
    enrich: enrichQuestionPreview,
  },
  // ---- Project / membership ----
  project_archived: {
    kind: 'project_archived',
    recipients: projectMembers,
    enrich: enrichProjectTitle,
  },
  membership_added: {
    kind: 'membership_added',
    recipients: membershipUserFromPayload,
    enrich: enrichProjectTitle,
  },
  // ТЗ §13.2 — адресат push при удалении из команды это сам удалённый
  // (а не вся команда — у них есть тихий `project:membership_changed`).
  // Шаблон NotificationKind переиспользуем (`membership_added`), чтобы не
  // множить kinds: текст шаблона позже можно специализировать через payload.
  membership_removed: {
    kind: 'membership_added',
    recipients: membershipUserFromPayload,
    enrich: enrichProjectTitle,
  },
  membership_left: {
    kind: 'membership_added',
    recipients: membershipUserFromPayload,
    enrich: enrichProjectTitle,
  },
  // ---- Exports ----
  export_completed: { kind: 'export_completed', recipients: exportRequester },
  export_failed: { kind: 'export_failed', recipients: exportRequester },
  // ---- 2026-05-04: новые события П1.11 / П2.4-2.6 / П2.15 / П2.18 ----
  foreman_assigned: {
    kind: 'stage_foreman_assigned',
    recipients: stageForemanIdFromPayload,
    enrich: enrichStageTitle,
  },
  master_assigned: {
    kind: 'stage_master_assigned',
    recipients: stageMasterFromPayload,
    enrich: enrichStageTitle,
  },
  master_unassigned: {
    kind: 'stage_master_assigned',
    recipients: stageMasterFromPayload,
    enrich: enrichStageTitle,
  },
  stage_pending_approval: {
    kind: 'stage_create_requested',
    recipients: projectOwnerAndReps,
    enrich: enrichStageTitleAsTitle,
  },
  budget_changed_by_customer: { kind: 'budget_changed', recipients: projectMembers },
};

function buildDeepLink(ev: {
  kind: FeedEventKind;
  projectId: string | null;
  payload: Record<string, unknown>;
}): string | undefined {
  if (!ev.projectId) return undefined;
  const payload = ev.payload ?? {};
  const map: Partial<Record<FeedEventKind, string>> = {
    approval_requested: `approvals/${payload.approvalId ?? ''}`,
    approval_approved: `approvals/${payload.approvalId ?? ''}`,
    approval_rejected: `approvals/${payload.approvalId ?? ''}`,
    approval_resubmitted: `approvals/${payload.approvalId ?? ''}`,
    plan_approved: `approvals/${payload.approvalId ?? ''}`,
    deadline_changed: `stages/${payload.stageId ?? ''}`,
    payment_created: `payments/${payload.paymentId ?? ''}`,
    chat_message_sent: `chats/${payload.chatId ?? ''}`,
    export_completed: `exports/${payload.jobId ?? ''}`,
    export_failed: `exports/${payload.jobId ?? ''}`,
    material_request_created: `materials/${payload.requestId ?? ''}`,
    selfpurchase_created: `selfpurchases/${payload.selfPurchaseId ?? ''}`,
    selfpurchase_approved: `selfpurchases/${payload.selfPurchaseId ?? ''}`,
    selfpurchase_rejected: `selfpurchases/${payload.selfPurchaseId ?? ''}`,
    // ---- П2.18 ----
    foreman_assigned: `stages/${payload.stageId ?? ''}`,
    master_assigned: `stages/${payload.stageId ?? ''}`,
    master_unassigned: `stages/${payload.stageId ?? ''}`,
    stage_pending_approval: `stages/${payload.stageId ?? ''}`,
    budget_changed_by_customer: `budget`,
    tool_custody_changed: `tools/${payload.toolItemId ?? ''}`,
    tool_added_to_project: `tools/${payload.toolItemId ?? ''}`,
    tool_removed_from_project: `tools`,
  };
  const tail = map[ev.kind];
  if (!tail) return `repair://projects/${ev.projectId}`;
  return `repair://projects/${ev.projectId}/${tail}`;
}
