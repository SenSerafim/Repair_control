import { Injectable } from '@nestjs/common';
import { Clock, ErrorCodes, NotFoundError, PrismaService } from '@app/common';
import { FeedService } from '../feed/feed.service';

@Injectable()
export class FeedbackService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly feed: FeedService,
  ) {}

  async create(userId: string, text: string, attachmentKeys: string[] = []) {
    const msg = await this.prisma.feedbackMessage.create({
      data: {
        userId,
        text,
        attachmentKeys,
        createdAt: this.clock.now(),
      },
    });
    await this.feed.emit({
      kind: 'feedback_received',
      projectId: null,
      actorId: userId,
      payload: { feedbackId: msg.id, hasAttachments: attachmentKeys.length > 0 },
    });
    return msg;
  }

  async listForAdmin(status?: string, _cursor?: string) {
    return this.prisma.feedbackMessage.findMany({
      where: status ? { status } : {},
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async get(id: string) {
    const m = await this.prisma.feedbackMessage.findUnique({ where: { id } });
    if (!m) throw new NotFoundError(ErrorCodes.FEEDBACK_NOT_FOUND, 'feedback not found');
    return m;
  }

  async patch(id: string, actorUserId: string, status: string) {
    await this.get(id);
    return this.prisma.feedbackMessage.update({
      where: { id },
      data: {
        status,
        readById: status === 'read' || status === 'archived' ? actorUserId : undefined,
        readAt: status === 'read' || status === 'archived' ? this.clock.now() : undefined,
      },
    });
  }
}
