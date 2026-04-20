import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import {
  Clock,
  ConflictError,
  ErrorCodes,
  ForbiddenError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FeedService } from '../feed/feed.service';

@Injectable()
export class QuestionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly clock: Clock,
  ) {}

  async ask(stepId: string, addresseeId: string, text: string, authorId: string) {
    const step = await this.prisma.step.findUnique({
      where: { id: stepId },
      select: { id: true, stageId: true, stage: { select: { projectId: true } } },
    });
    if (!step) throw new NotFoundError(ErrorCodes.STEP_NOT_FOUND, 'step not found');

    const question = await this.prisma.$transaction(async (tx) => {
      const q = await tx.question.create({
        data: { stepId: step.id, addresseeId, text: text.trim(), authorId },
      });
      await this.feed.emit({
        tx,
        kind: 'question_asked',
        projectId: step.stage.projectId,
        actorId: authorId,
        payload: { questionId: q.id, stepId: step.id, addresseeId },
      });
      return q;
    });
    return question;
  }

  async answer(id: string, answer: string, actorUserId: string) {
    const q = await this.prisma.question.findUnique({
      where: { id },
      include: { step: { select: { stageId: true, stage: { select: { projectId: true } } } } },
    });
    if (!q) throw new NotFoundError(ErrorCodes.QUESTION_NOT_FOUND, 'question not found');
    if (q.addresseeId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.QUESTION_ADDRESSEE_ONLY, 'only addressee can answer');
    }
    if (q.status === 'answered') {
      throw new ConflictError(ErrorCodes.QUESTION_ALREADY_ANSWERED, 'already answered');
    }
    if (q.status === 'closed') {
      throw new ConflictError(ErrorCodes.QUESTION_ALREADY_CLOSED, 'question is closed');
    }

    const now = this.clock.now();
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.question.update({
        where: { id },
        data: {
          status: 'answered',
          answer: answer.trim(),
          answeredAt: now,
          answeredBy: actorUserId,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'question_answered',
        projectId: q.step.stage.projectId,
        actorId: actorUserId,
        payload: { questionId: id, stepId: q.stepId },
      });
      return u;
    });
    return updated;
  }

  async close(id: string, actorUserId: string) {
    const q = await this.prisma.question.findUnique({
      where: { id },
      include: { step: { select: { stageId: true, stage: { select: { projectId: true } } } } },
    });
    if (!q) throw new NotFoundError(ErrorCodes.QUESTION_NOT_FOUND, 'question not found');
    if (q.authorId !== actorUserId) {
      throw new ForbiddenError(
        ErrorCodes.QUESTION_AUTHOR_ONLY_CLOSE,
        'only author can close question',
      );
    }
    if (q.status === 'closed') {
      throw new ConflictError(ErrorCodes.QUESTION_ALREADY_CLOSED, 'already closed');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.question.update({ where: { id }, data: { status: 'closed' } });
      await this.feed.emit({
        tx,
        kind: 'question_closed',
        projectId: q.step.stage.projectId,
        actorId: actorUserId,
        payload: { questionId: id },
      });
      return u;
    });
    return updated;
  }

  async listForStep(stepId: string) {
    return this.prisma.question.findMany({
      where: { stepId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async listForUser(userId: string, filter?: 'inbox' | 'sent' | 'open' | 'closed') {
    const where: Prisma.QuestionWhereInput = {};
    if (filter === 'inbox') where.addresseeId = userId;
    else if (filter === 'sent') where.authorId = userId;
    else if (filter === 'open') {
      where.status = 'open';
      where.OR = [{ authorId: userId }, { addresseeId: userId }];
    } else if (filter === 'closed') {
      where.status = 'closed';
      where.OR = [{ authorId: userId }, { addresseeId: userId }];
    } else {
      where.OR = [{ authorId: userId }, { addresseeId: userId }];
    }
    return this.prisma.question.findMany({ where, orderBy: { createdAt: 'desc' } });
  }
}
