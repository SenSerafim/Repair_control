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
    const { kind: notificationKind, recipients } = mapping;
    const userIds = await recipients(ev, this.prisma);
    const unique = Array.from(new Set(userIds.filter((u) => u && u !== ev.actorId)));
    if (unique.length === 0) return;
    await this.notifications.dispatch({
      userIds: unique,
      kind: notificationKind,
      projectId: ev.projectId,
      payload: ev.payload,
      deepLink: buildDeepLink(ev),
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

interface RoutingRule {
  kind: NotificationKind;
  recipients: RecipientResolver;
}

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

const requesterFromPayload: RecipientResolver = async (ev) => {
  const r = (ev.payload as any)?.requestedById;
  return typeof r === 'string' ? [r] : [];
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

const MAPPINGS: Partial<Record<FeedEventKind, RoutingRule>> = {
  approval_requested: { kind: 'approval_requested', recipients: addresseeFromPayload },
  approval_approved: { kind: 'approval_approved', recipients: requesterFromPayload },
  approval_rejected: { kind: 'approval_rejected', recipients: requesterFromPayload },
  payment_created: { kind: 'payment_created', recipients: paymentParties },
  payment_confirmed: { kind: 'payment_confirmed', recipients: paymentParties },
  payment_disputed: { kind: 'payment_disputed', recipients: paymentParties },
  payment_resolved: { kind: 'payment_resolved', recipients: paymentParties },
  stage_rejected_by_customer: { kind: 'stage_rejected_by_customer', recipients: projectMembers },
  stage_deadline_exceeds_project: {
    kind: 'stage_deadline_exceeds_project',
    recipients: projectOwnerAndReps,
  },
  material_request_created: { kind: 'material_request_created', recipients: projectMembers },
  material_delivered: { kind: 'material_delivered', recipients: projectMembers },
  material_disputed: { kind: 'material_disputed', recipients: projectOwnerAndReps },
  selfpurchase_created: { kind: 'selfpurchase_created', recipients: addresseeFromPayload },
  tool_issued: { kind: 'tool_issued', recipients: addresseeFromPayload },
  chat_message_sent: { kind: 'chat_message_new', recipients: chatParticipantsExceptAuthor },
  step_completed: { kind: 'step_completed', recipients: projectOwnerAndReps },
  stage_accepted: { kind: 'stage_completed', recipients: projectMembers },
  stage_paused: { kind: 'stage_paused', recipients: projectOwnerAndReps },
  note_created: { kind: 'note_created_for_me', recipients: addresseeFromPayload },
  question_asked: { kind: 'question_asked', recipients: addresseeFromPayload },
  project_archived: { kind: 'project_archived', recipients: projectMembers },
  membership_added: { kind: 'membership_added', recipients: addresseeFromPayload },
  export_completed: { kind: 'export_completed', recipients: exportRequester },
  export_failed: { kind: 'export_failed', recipients: exportRequester },
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
    payment_created: `payments/${payload.paymentId ?? ''}`,
    payment_confirmed: `payments/${payload.paymentId ?? ''}`,
    payment_disputed: `payments/${payload.paymentId ?? ''}`,
    chat_message_sent: `chats/${payload.chatId ?? ''}`,
    export_completed: `exports/${payload.jobId ?? ''}`,
    export_failed: `exports/${payload.jobId ?? ''}`,
    material_request_created: `materials/${payload.requestId ?? ''}`,
    selfpurchase_created: `selfpurchases/${payload.selfPurchaseId ?? ''}`,
  };
  const tail = map[ev.kind];
  if (!tail) return `repair://projects/${ev.projectId}`;
  return `repair://projects/${ev.projectId}/${tail}`;
}
