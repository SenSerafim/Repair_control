import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { PrismaService } from '@app/common';
import { ProjectsService } from './projects.service';
import { MembersService } from './members.service';
import { InvitationsService } from './invitations.service';
import {
  AddMemberDto,
  CopyProjectDto,
  CreateProjectDto,
  GenerateInviteCodeDto,
  InviteByPhoneDto,
  JoinByCodeDto,
  SearchUserDto,
  UpdateMembershipDto,
  UpdateProjectDto,
} from './dto';
import { AuthenticatedUser } from '../auth/jwt.strategy';

@ApiTags('projects')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller('projects')
export class ProjectsController {
  constructor(
    private readonly projects: ProjectsService,
    private readonly members: MembersService,
    private readonly invitations: InvitationsService,
    private readonly prismaForRoleLookup: PrismaService,
  ) {}

  @Post()
  @RequireAccess({ action: 'project.create' })
  async create(@Req() req: { user: AuthenticatedUser }, @Body() dto: CreateProjectDto) {
    return this.projects.create({ ownerId: req.user.userId, ...dto });
  }

  // P2: invite-by-code — оба эндпоинта объявлены РАНЬШЕ `:projectId` чтобы
  // 'join-by-code' не попал в paramsMatcher как projectId.
  @Post('join-by-code')
  async joinByCode(@Req() req: { user: AuthenticatedUser }, @Body() dto: JoinByCodeDto) {
    return this.invitations.joinByCode(req.user.userId, dto.code);
  }

  @Get()
  async list(
    @Req() req: { user: AuthenticatedUser },
    @Query('status') status?: 'active' | 'archived',
    @Query('role') roleQuery?: string,
  ) {
    // Активная роль фильтрует видимость: customer видит только свои
    // (ownerId === me), foreman/master/representative — только membership
    // соответствующей роли. Так каждая роль ведёт себя как изолированный
    // «аккаунт» (UX-требование).
    let activeRole = this.parseRole(roleQuery);
    if (!activeRole) {
      const me = await this.prismaForRoleLookup.user.findUnique({
        where: { id: req.user.userId },
        select: { activeRole: true },
      });
      activeRole = me?.activeRole;
    }
    return this.projects.listForUser(req.user.userId, status, activeRole);
  }

  private parseRole(raw?: string) {
    const allowed = ['customer', 'representative', 'contractor', 'master', 'admin'];
    return raw && allowed.includes(raw) ? (raw as any) : undefined;
  }

  @Get(':projectId')
  async get(@Param('projectId') projectId: string) {
    return this.projects.get(projectId);
  }

  @Patch(':projectId')
  @RequireAccess({
    action: 'project.edit',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async update(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: UpdateProjectDto,
  ) {
    return this.projects.update(projectId, dto, req.user.userId);
  }

  @Post(':projectId/archive')
  @RequireAccess({
    action: 'project.archive',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async archive(@Req() req: { user: AuthenticatedUser }, @Param('projectId') projectId: string) {
    return this.projects.archive(projectId, req.user.userId);
  }

  @Post(':projectId/restore')
  @RequireAccess({
    action: 'project.archive',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async restore(@Req() req: { user: AuthenticatedUser }, @Param('projectId') projectId: string) {
    return this.projects.restore(projectId, req.user.userId);
  }

  @Post(':projectId/copy')
  @RequireAccess({
    action: 'project.edit',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async copy(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: CopyProjectDto,
  ) {
    return this.projects.copy(projectId, req.user.userId, dto.newTitle);
  }

  // ---- Memberships ----

  @Get(':projectId/members')
  async listMembers(@Param('projectId') projectId: string) {
    return this.members.list(projectId);
  }

  @Post(':projectId/members')
  @RequireAccess({
    action: 'project.invite_member',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async addMember(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: AddMemberDto,
  ) {
    return this.members.addMembership({
      projectId,
      actorUserId: req.user.userId,
      userId: dto.userId,
      role: dto.role,
      permissions: dto.permissions,
      stageIds: dto.stageIds,
    });
  }

  @Patch(':projectId/members/:membershipId')
  @RequireAccess({
    action: 'project.invite_member',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async updateMember(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Param('membershipId') membershipId: string,
    @Body() dto: UpdateMembershipDto,
  ) {
    return this.members.updateMembership(projectId, membershipId, req.user.userId, dto);
  }

  @Delete(':projectId/members/:membershipId')
  @RequireAccess({
    action: 'project.invite_member',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async removeMember(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Param('membershipId') membershipId: string,
  ) {
    await this.members.removeMembership(projectId, membershipId, req.user.userId);
  }

  // ---- Invitations ----

  @Post(':projectId/invitations')
  @RequireAccess({
    action: 'project.invite_member',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async invite(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: InviteByPhoneDto,
  ) {
    return this.invitations.invite({
      projectId,
      actorUserId: req.user.userId,
      phone: dto.phone,
      role: dto.role,
    });
  }

  @Get(':projectId/invitations')
  async listInvitations(@Param('projectId') projectId: string) {
    return this.invitations.listForProject(projectId);
  }

  @Post(':projectId/invitations/generate-code')
  @RequireAccess({
    action: 'project.invite_member',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async generateInviteCode(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: GenerateInviteCodeDto,
  ) {
    return this.invitations.generateCode({
      projectId,
      byUserId: req.user.userId,
      role: dto.role,
      permissions: dto.permissions,
      stageIds: dto.stageIds,
    });
  }

  @Delete(':projectId/invitations/:invitationId')
  @RequireAccess({
    action: 'project.invite_member',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async cancelInvitation(
    @Param('projectId') projectId: string,
    @Param('invitationId') invitationId: string,
  ) {
    await this.invitations.cancel(projectId, invitationId);
  }

  // ---- User search (for adding members) ----

  @Get(':projectId/search-user')
  async searchUser(@Query() q: SearchUserDto) {
    return this.members.searchUser({ phone: q.phone, email: q.email });
  }
}
