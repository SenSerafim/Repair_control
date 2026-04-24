import { Injectable } from '@nestjs/common';
import { Clock, ErrorCodes, ForbiddenError, NotFoundError, PrismaService } from '@app/common';
import { FeedService } from '../feed/feed.service';

@Injectable()
export class SubstepsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly clock: Clock,
  ) {}

  async add(stepId: string, text: string, actorUserId: string) {
    const step = await this.prisma.step.findUnique({
      where: { id: stepId },
      select: { id: true, stageId: true, stage: { select: { projectId: true } } },
    });
    if (!step) throw new NotFoundError(ErrorCodes.STEP_NOT_FOUND, 'step not found');

    return this.prisma.$transaction(async (tx) => {
      const sub = await tx.substep.create({
        data: { stepId: step.id, text: text.trim(), authorId: actorUserId },
      });
      await this.feed.emit({
        tx,
        kind: 'substep_added',
        projectId: step.stage.projectId,
        actorId: actorUserId,
        payload: { stepId: step.id, substepId: sub.id, stageId: step.stageId },
      });
      return sub;
    });
  }

  async update(substepId: string, text: string, actorUserId: string) {
    const sub = await this.prisma.substep.findUnique({
      where: { id: substepId },
      include: { step: { select: { stageId: true, stage: { select: { projectId: true } } } } },
    });
    if (!sub) throw new NotFoundError(ErrorCodes.SUBSTEP_NOT_FOUND, 'substep not found');
    // ТЗ §6.4: редактировать подшаг может только его автор
    if (sub.authorId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.SUBSTEP_EDIT_AUTHOR_ONLY, 'only substep author can edit');
    }
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.substep.update({
        where: { id: substepId },
        data: { text: text.trim() },
      });
      await this.feed.emit({
        tx,
        kind: 'substep_updated',
        projectId: sub.step.stage.projectId,
        actorId: actorUserId,
        payload: { substepId, stepId: sub.stepId },
      });
      return u;
    });
    return updated;
  }

  async complete(substepId: string, actorUserId: string) {
    const sub = await this.prisma.substep.findUnique({
      where: { id: substepId },
      include: { step: { select: { stageId: true, stage: { select: { projectId: true } } } } },
    });
    if (!sub) throw new NotFoundError(ErrorCodes.SUBSTEP_NOT_FOUND, 'substep not found');

    const now = this.clock.now();
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.substep.update({
        where: { id: substepId },
        data: { isDone: true, doneAt: now, doneById: actorUserId },
      });
      await this.feed.emit({
        tx,
        kind: 'substep_completed',
        projectId: sub.step.stage.projectId,
        actorId: actorUserId,
        payload: { substepId, stepId: sub.stepId },
      });
      return u;
    });
    return updated;
  }

  async uncomplete(substepId: string, actorUserId: string) {
    const sub = await this.prisma.substep.findUnique({
      where: { id: substepId },
      include: { step: { select: { stageId: true, stage: { select: { projectId: true } } } } },
    });
    if (!sub) throw new NotFoundError(ErrorCodes.SUBSTEP_NOT_FOUND, 'substep not found');

    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.substep.update({
        where: { id: substepId },
        data: { isDone: false, doneAt: null, doneById: null },
      });
      await this.feed.emit({
        tx,
        kind: 'substep_uncompleted',
        projectId: sub.step.stage.projectId,
        actorId: actorUserId,
        payload: { substepId, stepId: sub.stepId },
      });
      return u;
    });
    return updated;
  }

  async delete(substepId: string, actorUserId: string) {
    const sub = await this.prisma.substep.findUnique({
      where: { id: substepId },
      include: { step: { select: { stageId: true, stage: { select: { projectId: true } } } } },
    });
    if (!sub) throw new NotFoundError(ErrorCodes.SUBSTEP_NOT_FOUND, 'substep not found');
    if (sub.authorId !== actorUserId) {
      throw new ForbiddenError(
        ErrorCodes.SUBSTEP_EDIT_AUTHOR_ONLY,
        'only substep author can delete',
      );
    }
    await this.prisma.$transaction(async (tx) => {
      await tx.substep.delete({ where: { id: substepId } });
      await this.feed.emit({
        tx,
        kind: 'substep_deleted',
        projectId: sub.step.stage.projectId,
        actorId: actorUserId,
        payload: { substepId, stepId: sub.stepId },
      });
    });
  }
}
