import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { AdminOverviewService } from './admin-overview.service';

/**
 * Глобальные списки всех сущностей для системного админа —
 * документы / платежи / материалы / согласования / чаты / сессии / устройства.
 *
 * Все эндпоинты доступны только `SystemRole.admin` (rbac.matrix — в ветке
 * `admin → true` любой action проходит).
 */
@ApiTags('admin-overview')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller('admin')
export class AdminOverviewController {
  constructor(private readonly svc: AdminOverviewService) {}

  // ───────── Documents ─────────
  @Get('documents')
  @RequireAccess({ action: 'admin.stats.read', resource: 'none' })
  listDocuments(
    @Query('projectId') projectId?: string,
    @Query('q') q?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.svc.listDocuments({
      projectId,
      q,
      limit: limit ? Number(limit) : 50,
      offset: offset ? Number(offset) : 0,
    });
  }

  // ───────── Payments ─────────
  @Get('payments')
  @RequireAccess({ action: 'admin.stats.read', resource: 'none' })
  listPayments(
    @Query('projectId') projectId?: string,
    @Query('status') status?: string,
    @Query('kind') kind?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.svc.listPayments({
      projectId,
      status,
      kind,
      limit: limit ? Number(limit) : 50,
      offset: offset ? Number(offset) : 0,
    });
  }

  // ───────── Materials ─────────
  @Get('materials')
  @RequireAccess({ action: 'admin.stats.read', resource: 'none' })
  listMaterials(
    @Query('projectId') projectId?: string,
    @Query('status') status?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.svc.listMaterials({
      projectId,
      status,
      limit: limit ? Number(limit) : 50,
      offset: offset ? Number(offset) : 0,
    });
  }

  // ───────── Approvals ─────────
  @Get('approvals')
  @RequireAccess({ action: 'admin.stats.read', resource: 'none' })
  listApprovals(
    @Query('projectId') projectId?: string,
    @Query('status') status?: string,
    @Query('scope') scope?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.svc.listApprovals({
      projectId,
      status,
      scope,
      limit: limit ? Number(limit) : 50,
      offset: offset ? Number(offset) : 0,
    });
  }

  // ───────── Chats ─────────
  @Get('chats')
  @RequireAccess({ action: 'admin.stats.read', resource: 'none' })
  listChats(
    @Query('projectId') projectId?: string,
    @Query('type') type?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.svc.listChats({
      projectId,
      type,
      limit: limit ? Number(limit) : 50,
      offset: offset ? Number(offset) : 0,
    });
  }

  // ───────── Stages ─────────
  @Get('stages')
  @RequireAccess({ action: 'admin.stats.read', resource: 'none' })
  listStages(
    @Query('projectId') projectId?: string,
    @Query('status') status?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.svc.listStages({
      projectId,
      status,
      limit: limit ? Number(limit) : 50,
      offset: offset ? Number(offset) : 0,
    });
  }

  // ───────── Sessions ─────────
  @Get('users/:userId/sessions')
  @RequireAccess({ action: 'admin.users.detail', resource: 'none' })
  listUserSessions(@Param('userId') userId: string) {
    return this.svc.listUserSessions(userId);
  }

  // ───────── Devices ─────────
  @Get('users/:userId/devices')
  @RequireAccess({ action: 'admin.users.detail', resource: 'none' })
  listUserDevices(@Param('userId') userId: string) {
    return this.svc.listUserDevices(userId);
  }

  // ───────── Projects-of-user ─────────
  @Get('users/:userId/projects')
  @RequireAccess({ action: 'admin.users.detail', resource: 'none' })
  listUserProjects(@Param('userId') userId: string) {
    return this.svc.listUserProjects(userId);
  }
}
