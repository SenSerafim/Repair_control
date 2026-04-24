import { Body, Controller, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { IsEnum, IsOptional, IsString, Length } from 'class-validator';
import { LegalKind } from '@prisma/client';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { LegalService } from './legal.service';

class CreateLegalDto {
  @ApiProperty({ enum: LegalKind })
  @IsEnum(LegalKind)
  kind!: LegalKind;

  @ApiProperty()
  @IsString()
  @Length(1, 200)
  title!: string;

  @ApiProperty()
  @IsString()
  @Length(1, 200_000)
  bodyMd!: string;
}

class UpdateLegalDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 200)
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 200_000)
  bodyMd?: string;
}

class AcceptLegalDto {
  @ApiProperty({ enum: LegalKind })
  @IsEnum(LegalKind)
  kind!: LegalKind;
}

@ApiTags('legal')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller()
export class LegalController {
  constructor(private readonly svc: LegalService) {}

  // ---- User endpoints ----

  @Get('me/legal-acceptance')
  @RequireAccess({ action: 'legal.accept', resource: 'none' })
  status(@Req() req: any) {
    return this.svc.getAcceptanceStatus(req.user.userId);
  }

  @Post('me/legal-acceptance')
  @RequireAccess({ action: 'legal.accept', resource: 'none' })
  accept(@Body() dto: AcceptLegalDto, @Req() req: any) {
    return this.svc.accept(req.user.userId, dto.kind);
  }

  // ---- Admin ----

  @Get('admin/legal/documents')
  @RequireAccess({ action: 'admin.legal.read_admin', resource: 'none' })
  listAll(@Query('kind') kind?: LegalKind) {
    return this.svc.listAll(kind);
  }

  @Get('admin/legal/documents/:id')
  @RequireAccess({ action: 'admin.legal.read_admin', resource: 'none' })
  get(@Param('id') id: string) {
    return this.svc.getById(id);
  }

  @Post('admin/legal/documents')
  @RequireAccess({ action: 'admin.legal.manage', resource: 'none' })
  create(@Body() dto: CreateLegalDto, @Req() req: any) {
    return this.svc.createDraft(req.user.userId, dto);
  }

  @Patch('admin/legal/documents/:id')
  @RequireAccess({ action: 'admin.legal.manage', resource: 'none' })
  update(@Param('id') id: string, @Body() dto: UpdateLegalDto, @Req() req: any) {
    return this.svc.updateDraft(id, req.user.userId, dto);
  }

  @Post('admin/legal/documents/:id/publish')
  @RequireAccess({ action: 'admin.legal.manage', resource: 'none' })
  publish(@Param('id') id: string, @Req() req: any) {
    return this.svc.publish(id, req.user.userId);
  }
}
