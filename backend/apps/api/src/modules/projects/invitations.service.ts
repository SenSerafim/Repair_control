import { Injectable } from '@nestjs/common';
import { nanoid } from 'nanoid';
import { Clock, ErrorCodes, NotFoundError, PrismaService } from '@app/common';
import { MembershipRole } from './members.service';

const INVITATION_TTL_DAYS = 14;

@Injectable()
export class InvitationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
  ) {}

  async invite(params: {
    projectId: string;
    actorUserId: string;
    phone: string;
    role: MembershipRole;
  }) {
    const project = await this.prisma.project.findUnique({ where: { id: params.projectId } });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');

    const token = nanoid(32);
    const expiresAt = new Date(
      this.clock.now().getTime() + INVITATION_TTL_DAYS * 24 * 60 * 60 * 1000,
    );

    return this.prisma.projectInvitation.create({
      data: {
        projectId: params.projectId,
        phone: params.phone,
        role: params.role,
        invitedById: params.actorUserId,
        token,
        expiresAt,
      },
      select: { id: true, token: true, expiresAt: true, phone: true, role: true },
    });
  }

  async listForProject(projectId: string) {
    return this.prisma.projectInvitation.findMany({
      where: { projectId, status: 'pending' },
      orderBy: { createdAt: 'desc' },
    });
  }

  async cancel(projectId: string, invitationId: string) {
    await this.prisma.projectInvitation.updateMany({
      where: { id: invitationId, projectId, status: 'pending' },
      data: { status: 'cancelled' },
    });
  }
}
