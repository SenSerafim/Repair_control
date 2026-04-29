import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  Length,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { BroadcastStatus, DevicePlatform, SystemRole } from '@prisma/client';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { BroadcastsService } from './broadcasts.service';

class BroadcastFilterDto {
  @ApiPropertyOptional({ enum: SystemRole, isArray: true })
  @IsOptional()
  @IsArray()
  @IsEnum(SystemRole, { each: true })
  roles?: SystemRole[];

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  projectIds?: string[];

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  userIds?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  bannedOnly?: boolean;

  @ApiPropertyOptional({ enum: DevicePlatform })
  @IsOptional()
  @IsEnum(DevicePlatform)
  platform?: DevicePlatform;
}

class PreviewDto {
  @ApiProperty({ type: () => BroadcastFilterDto })
  @ValidateNested()
  @Type(() => BroadcastFilterDto)
  filter!: BroadcastFilterDto;
}

class SendBroadcastDto {
  @ApiProperty()
  @IsString()
  @Length(1, 200)
  title!: string;

  @ApiProperty()
  @IsString()
  @Length(1, 4000)
  body!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 500)
  deepLink?: string;

  @ApiProperty({ type: () => BroadcastFilterDto })
  @ValidateNested()
  @Type(() => BroadcastFilterDto)
  filter!: BroadcastFilterDto;
}

@ApiTags('admin-broadcasts')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller('admin/broadcasts')
export class BroadcastsController {
  constructor(private readonly svc: BroadcastsService) {}

  @Post('preview')
  @RequireAccess({ action: 'admin.broadcast.list', resource: 'none' })
  preview(@Body() dto: PreviewDto) {
    return this.svc.previewTargets(dto.filter);
  }

  @Post()
  @RequireAccess({ action: 'admin.broadcast.send', resource: 'none' })
  send(@Body() dto: SendBroadcastDto, @Req() req: any) {
    return this.svc.send(req.user.userId, {
      title: dto.title,
      body: dto.body,
      deepLink: dto.deepLink,
      filter: dto.filter,
    });
  }

  @Get()
  @RequireAccess({ action: 'admin.broadcast.list', resource: 'none' })
  list(@Query('status') status?: BroadcastStatus) {
    return this.svc.list({ status });
  }

  @Get(':id')
  @RequireAccess({ action: 'admin.broadcast.list', resource: 'none' })
  get(@Param('id') id: string) {
    return this.svc.get(id);
  }
}
