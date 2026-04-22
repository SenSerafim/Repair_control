import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { PrismaService } from '@app/common';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { AdminAuditService } from './admin-audit.service';

@ApiTags('admin-audit')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller()
export class AdminAuditController {
  constructor(
    private readonly svc: AdminAuditService,
    private readonly prisma: PrismaService,
  ) {}

  @Get('admin/audit')
  @RequireAccess({ action: 'admin.audit.read', resource: 'none' })
  list(
    @Query('actorId') actorId?: string,
    @Query('action') action?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('limit') limit?: string,
  ) {
    return this.svc.list({ actorId, action, from, to, limit: limit ? Number(limit) : undefined });
  }

  @Get('admin/stats')
  @RequireAccess({ action: 'admin.stats.read', resource: 'none' })
  async stats() {
    const now = new Date();
    const dayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);

    const [
      usersTotal,
      usersBanned,
      usersByRoleAgg,
      projectsActive,
      projectsArchived,
      feedbackNew,
      feedbackRead,
      feedbackArchived,
      broadcastsSentDay,
      notifDelivered24h,
      notifFailed24h,
      chatsTotal,
      documentsTotal,
      exportsDone,
      exportsFailed,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { bannedAt: { not: null } } }),
      this.prisma.userRole.groupBy({ by: ['role'], _count: { role: true } }),
      this.prisma.project.count({ where: { status: 'active' } }),
      this.prisma.project.count({ where: { status: 'archived' } }),
      this.prisma.feedbackMessage.count({ where: { status: 'new' } }),
      this.prisma.feedbackMessage.count({ where: { status: 'read' } }),
      this.prisma.feedbackMessage.count({ where: { status: 'archived' } }),
      this.prisma.broadcastCampaign.count({ where: { sentAt: { gte: dayAgo } } }),
      this.prisma.notificationLog.count({ where: { deliveredAt: { gte: dayAgo } } }),
      this.prisma.notificationLog.count({ where: { failedAt: { gte: dayAgo } } }),
      this.prisma.chat.count(),
      this.prisma.document.count({ where: { deletedAt: null } }),
      this.prisma.exportJob.count({ where: { status: 'done' } }),
      this.prisma.exportJob.count({ where: { status: 'failed' } }),
    ]);

    const byRole: Record<string, number> = {};
    for (const r of usersByRoleAgg) byRole[r.role] = r._count.role;

    return {
      users: {
        total: usersTotal,
        banned: usersBanned,
        active: usersTotal - usersBanned,
        byRole,
      },
      projects: {
        active: projectsActive,
        archived: projectsArchived,
        total: projectsActive + projectsArchived,
      },
      feedback: {
        new: feedbackNew,
        read: feedbackRead,
        archived: feedbackArchived,
      },
      broadcasts: { sent_24h: broadcastsSentDay },
      notifications: {
        delivered_24h: notifDelivered24h,
        failed_24h: notifFailed24h,
      },
      chats: { total: chatsTotal },
      documents: { total: documentsTotal },
      exports: { done: exportsDone, failed: exportsFailed },
    };
  }
}
