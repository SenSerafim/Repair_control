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
import { AuthGuard } from '@nestjs/passport';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { AdminUsersService } from './admin-users.service';
import { BanUserDto, ListUsersQueryDto, SetRolesDto } from './dto';

@ApiTags('admin-users')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller('admin/users')
export class AdminUsersController {
  constructor(private readonly svc: AdminUsersService) {}

  @Get()
  @RequireAccess({ action: 'admin.users.list', resource: 'none' })
  list(@Query() q: ListUsersQueryDto) {
    return this.svc.list({
      q: q.q,
      role: q.role,
      banned: q.banned,
      limit: q.limit,
      offset: q.offset,
    });
  }

  @Get(':id')
  @RequireAccess({ action: 'admin.users.detail', resource: 'none' })
  detail(@Param('id') id: string) {
    return this.svc.detail(id);
  }

  @Post(':id/ban')
  @RequireAccess({ action: 'admin.users.ban', resource: 'none' })
  ban(@Param('id') id: string, @Body() dto: BanUserDto, @Req() req: any) {
    return this.svc.ban(id, req.user.userId, dto.reason);
  }

  @Post(':id/unban')
  @RequireAccess({ action: 'admin.users.ban', resource: 'none' })
  unban(@Param('id') id: string, @Req() req: any) {
    return this.svc.unban(id, req.user.userId);
  }

  @Post(':id/reset-password')
  @RequireAccess({ action: 'admin.users.reset_password', resource: 'none' })
  resetPassword(@Param('id') id: string, @Req() req: any) {
    return this.svc.resetPassword(id, req.user.userId);
  }

  @Delete(':id/sessions')
  @RequireAccess({ action: 'admin.users.force_logout', resource: 'none' })
  forceLogout(@Param('id') id: string, @Req() req: any) {
    return this.svc.forceLogout(id, req.user.userId);
  }

  @Patch(':id/roles')
  @RequireAccess({ action: 'admin.users.manage_roles', resource: 'none' })
  setRoles(@Param('id') id: string, @Body() dto: SetRolesDto, @Req() req: any) {
    return this.svc.setRoles(id, req.user.userId, dto.roles);
  }

  @Get(':id/audit')
  @RequireAccess({ action: 'admin.audit.read', resource: 'none' })
  audit(@Param('id') id: string) {
    return this.svc.getUserAudit(id);
  }
}
