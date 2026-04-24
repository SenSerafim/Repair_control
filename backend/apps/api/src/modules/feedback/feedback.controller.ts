import { Body, Controller, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { IsArray, IsOptional, IsString, Length } from 'class-validator';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { FeedbackService } from './feedback.service';

class CreateFeedbackDto {
  @ApiProperty()
  @IsString()
  @Length(1, 5000)
  text!: string;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  attachmentKeys?: string[];
}

class PatchFeedbackDto {
  @ApiProperty({ enum: ['new', 'read', 'archived'] })
  @IsString()
  status!: 'new' | 'read' | 'archived';
}

@ApiTags('feedback')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller()
export class FeedbackController {
  constructor(private readonly svc: FeedbackService) {}

  @Post('feedback')
  @RequireAccess({ action: 'feedback.create', resource: 'none' })
  create(@Body() dto: CreateFeedbackDto, @Req() req: any) {
    return this.svc.create(req.user.userId, dto.text, dto.attachmentKeys ?? []);
  }

  @Get('admin/feedback')
  @RequireAccess({ action: 'admin.feedback.read', resource: 'none' })
  list(@Query('status') status?: string, @Query('cursor') cursor?: string) {
    return this.svc.listForAdmin(status, cursor);
  }

  @Get('admin/feedback/:id')
  @RequireAccess({ action: 'admin.feedback.read', resource: 'none' })
  get(@Param('id') id: string) {
    return this.svc.get(id);
  }

  @Patch('admin/feedback/:id')
  @RequireAccess({ action: 'admin.feedback.read', resource: 'none' })
  patch(@Param('id') id: string, @Body() dto: PatchFeedbackDto, @Req() req: any) {
    return this.svc.patch(id, req.user.userId, dto.status);
  }
}
