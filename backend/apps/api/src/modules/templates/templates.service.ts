import { Injectable } from '@nestjs/common';
import { Prisma, TemplateKind } from '@prisma/client';
import { ErrorCodes, NotFoundError, PrismaService } from '@app/common';
import { FeedService } from '../feed/feed.service';

@Injectable()
export class TemplatesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
  ) {}

  async listPlatform() {
    return this.prisma.template.findMany({
      where: { kind: 'platform' },
      include: { steps: { orderBy: { orderIndex: 'asc' } } },
      orderBy: { title: 'asc' },
    });
  }

  async listUser(authorId: string) {
    return this.prisma.template.findMany({
      where: { kind: 'user', authorId },
      include: { steps: { orderBy: { orderIndex: 'asc' } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async get(id: string) {
    const tpl = await this.prisma.template.findUnique({
      where: { id },
      include: { steps: { orderBy: { orderIndex: 'asc' } } },
    });
    if (!tpl) throw new NotFoundError(ErrorCodes.TEMPLATE_NOT_FOUND, 'template not found');
    return tpl;
  }

  async createFromStage(params: { stageId: string; authorId: string; title: string }) {
    const stage = await this.prisma.stage.findUnique({ where: { id: params.stageId } });
    if (!stage) throw new NotFoundError(ErrorCodes.STAGE_NOT_FOUND, 'stage not found');

    return this.prisma.template.create({
      data: {
        kind: TemplateKind.user,
        authorId: params.authorId,
        title: params.title,
        payload: {} as Prisma.InputJsonValue,
      },
    });
  }

  async applyToProject(params: {
    templateId: string;
    projectId: string;
    actorUserId: string;
    plannedStart?: string;
    plannedEnd?: string;
  }) {
    const tpl = await this.get(params.templateId);
    const count = await this.prisma.stage.count({ where: { projectId: params.projectId } });
    const plannedEnd = params.plannedEnd ? new Date(params.plannedEnd) : null;
    const stage = await this.prisma.stage.create({
      data: {
        projectId: params.projectId,
        title: tpl.title,
        orderIndex: count,
        plannedStart: params.plannedStart ? new Date(params.plannedStart) : null,
        plannedEnd,
        originalEnd: plannedEnd,
      },
    });
    await this.feed.emit({
      kind: 'stage_created',
      projectId: params.projectId,
      actorId: params.actorUserId,
      payload: { stageId: stage.id, title: stage.title, fromTemplateId: params.templateId },
    });
    return stage;
  }
}
