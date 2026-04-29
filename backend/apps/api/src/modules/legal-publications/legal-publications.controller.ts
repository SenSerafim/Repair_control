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
import { LegalPublicationKind } from '@prisma/client';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { LegalPublicationsService } from './legal-publications.service';
import { CreateLegalPublicationDto, UpdateLegalPublicationDto } from './dto';

@ApiTags('legal-publications')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller()
export class LegalPublicationsController {
  constructor(private readonly svc: LegalPublicationsService) {}

  // ---- Authenticated public-list (mobile app) ----

  /** Список активных публикаций для mobile bottom-sheet.
   * Путь использует дефис вместо слэша, чтобы не попасть под `legal/(.*)`
   * exclude в `setGlobalPrefix` (main.ts) и получить нормальный `/api` prefix. */
  @Get('legal-publications/list')
  list() {
    return this.svc.listActive();
  }

  // ---- Admin CRUD ----

  @Get('admin/legal-publications')
  @RequireAccess({ action: 'admin.legal_publications.manage', resource: 'none' })
  listAll(@Query('kind') kind?: LegalPublicationKind) {
    return this.svc.listAll(kind);
  }

  @Get('admin/legal-publications/:id')
  @RequireAccess({ action: 'admin.legal_publications.manage', resource: 'none' })
  get(@Param('id') id: string) {
    return this.svc.getById(id);
  }

  @Post('admin/legal-publications')
  @RequireAccess({ action: 'admin.legal_publications.manage', resource: 'none' })
  create(@Body() dto: CreateLegalPublicationDto, @Req() req: any) {
    return this.svc.create(req.user.userId, dto);
  }

  @Patch('admin/legal-publications/:id')
  @RequireAccess({ action: 'admin.legal_publications.manage', resource: 'none' })
  update(@Param('id') id: string, @Body() dto: UpdateLegalPublicationDto, @Req() req: any) {
    return this.svc.update(id, req.user.userId, dto);
  }

  @Post('admin/legal-publications/:id/publish')
  @RequireAccess({ action: 'admin.legal_publications.manage', resource: 'none' })
  publish(@Param('id') id: string, @Req() req: any) {
    return this.svc.publish(id, req.user.userId);
  }

  @Delete('admin/legal-publications/:id')
  @RequireAccess({ action: 'admin.legal_publications.manage', resource: 'none' })
  deactivate(@Param('id') id: string, @Req() req: any) {
    return this.svc.deactivate(id, req.user.userId);
  }
}
