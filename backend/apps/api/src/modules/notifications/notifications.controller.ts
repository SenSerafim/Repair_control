import { Body, Controller, Get, Patch, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { NotificationKind } from '@prisma/client';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { NotificationsService } from './notifications.service';
import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsEnum } from 'class-validator';

class PatchSettingDto {
  @ApiProperty({ enum: NotificationKind })
  @IsEnum(NotificationKind)
  kind!: NotificationKind;

  @ApiProperty()
  @IsBoolean()
  pushEnabled!: boolean;
}

@ApiTags('notifications')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller()
export class NotificationsController {
  constructor(private readonly svc: NotificationsService) {}

  @Get('me/notification-settings')
  @RequireAccess({ action: 'notification.settings.self', resource: 'none' })
  getSettings(@Req() req: any) {
    return this.svc.getSettings(req.user.userId);
  }

  @Patch('me/notification-settings')
  @RequireAccess({ action: 'notification.settings.self', resource: 'none' })
  async patchSetting(@Body() dto: PatchSettingDto, @Req() req: any) {
    await this.svc.patchSetting(req.user.userId, dto.kind, dto.pushEnabled);
    return { ok: true };
  }

  @Get('admin/notification-logs')
  @RequireAccess({ action: 'admin.notifications.inspect', resource: 'none' })
  logs(
    @Query('userId') userId?: string,
    @Query('kind') kind?: NotificationKind,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.svc.adminLogs({ userId, kind, from, to });
  }
}
