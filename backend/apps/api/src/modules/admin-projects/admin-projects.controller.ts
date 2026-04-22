import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { IsEnum, IsInt, IsOptional, IsString, Length, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ProjectStatus } from '@prisma/client';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { AdminProjectsService } from './admin-projects.service';

class ListProjectsQueryDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  q?: string;

  @ApiPropertyOptional({ enum: ProjectStatus })
  @IsOptional()
  @IsEnum(ProjectStatus)
  status?: ProjectStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  ownerId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  offset?: number;
}

class ForceArchiveDto {
  @ApiProperty()
  @IsString()
  @Length(1, 500)
  reason!: string;
}

@ApiTags('admin-projects')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller('admin/projects')
export class AdminProjectsController {
  constructor(private readonly svc: AdminProjectsService) {}

  @Get()
  @RequireAccess({ action: 'admin.projects.list_all', resource: 'none' })
  list(@Query() q: ListProjectsQueryDto) {
    return this.svc.list(q);
  }

  @Get(':id')
  @RequireAccess({ action: 'admin.projects.list_all', resource: 'none' })
  detail(@Param('id') id: string) {
    return this.svc.detail(id);
  }

  @Post(':id/force-archive')
  @RequireAccess({ action: 'admin.projects.force_archive', resource: 'none' })
  forceArchive(@Param('id') id: string, @Body() dto: ForceArchiveDto, @Req() req: any) {
    return this.svc.forceArchive(id, req.user.userId, dto.reason);
  }
}
