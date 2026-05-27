import {
  Body,
  Controller,
  Get,
  Header,
  Param,
  Post,
  Query,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { MaterialsPdfService } from './materials-pdf.service';
import { MaterialsService } from './materials.service';
import { AcceptFullDto, AcceptPartialDto, CreateMaterialRequestDto, MarkDeliveredDto } from './dto';

@ApiTags('materials')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller()
export class MaterialsController {
  constructor(
    private readonly materials: MaterialsService,
    private readonly pdf: MaterialsPdfService,
  ) {}

  /**
   * Создать заявку. customer-owner / representative.canApprove → сразу «Согласовано» (`open`).
   * foreman / master → «Ждёт согласования» + Approval(material_purchase) заказчику.
   */
  @Post('projects/:projectId/materials')
  @RequireAccess({
    action: 'materials.manage',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async create(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: CreateMaterialRequestDto,
  ) {
    return this.materials.createRequest({
      projectId,
      stageId: dto.stageId,
      recipient: dto.recipient,
      title: dto.title,
      comment: dto.comment,
      items: dto.items,
      actorUserId: req.user.userId,
    });
  }

  @Get('projects/:projectId/materials')
  @RequireAccess({
    action: 'materials.manage',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async list(
    @Param('projectId') projectId: string,
    @Query('status') status?: string,
    @Query('stageId') stageId?: string,
  ) {
    return this.materials.listForProject(projectId, { status, stageId });
  }

  @Get('materials/:id')
  async get(@Param('id') id: string) {
    return this.materials.get(id);
  }

  /**
   * ТЗ NEWFIX §5.3: «Сформировать PDF» по заявке. RBAC reuse'нем тот же
   * `materials.manage` — все, кому видна сама заявка, могут скачать PDF.
   * Возвращаем поток напрямую (inline), без записи в S3 — документ короткий
   * (десяток позиций) и одноразовый.
   */
  @Get('materials/:id/pdf')
  @RequireAccess({
    action: 'materials.manage',
    resource: 'material_request',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  @Header('Content-Type', 'application/pdf')
  async pdfForRequest(@Param('id') id: string, @Res({ passthrough: false }) res: Response) {
    const buffer = await this.pdf.renderForRequest(id);
    res.setHeader('Content-Disposition', `inline; filename="request-${id}.pdf"`);
    res.setHeader('Content-Length', buffer.length.toString());
    res.end(buffer);
  }

  /**
   * Отметить заявку «Доставлено». ТЗ NEWFIX §5.7 шаг 1.
   * RBAC: любой активный member проекта (materials.mark_delivered).
   * Допустимые переходы: open → delivered, accepted_partial → delivered (довоз).
   * Идемпотентно из delivered.
   */
  @Post('materials/:id/mark-delivered')
  @RequireAccess({
    action: 'materials.mark_delivered',
    resource: 'material_request',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async markDelivered(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() _dto: MarkDeliveredDto,
  ) {
    return this.materials.markDelivered({
      requestId: id,
      actorUserId: req.user.userId,
    });
  }

  /**
   * Частичная приёмка. ТЗ NEWFIX §5.7 шаги 4–5.
   * RBAC: foreman / customer-owner / representative.canApprove (materials.accept).
   */
  @Post('materials/:id/accept-partial')
  @RequireAccess({
    action: 'materials.accept',
    resource: 'material_request',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async acceptPartial(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: AcceptPartialDto,
  ) {
    return this.materials.acceptPartial({
      requestId: id,
      actorUserId: req.user.userId,
      items: dto.items,
      comment: dto.comment,
    });
  }

  /**
   * Полная приёмка. ТЗ NEWFIX §5.7 шаг 4.
   * RBAC: foreman / customer-owner / representative.canApprove (materials.accept).
   */
  @Post('materials/:id/accept-full')
  @RequireAccess({
    action: 'materials.accept',
    resource: 'material_request',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async acceptFull(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: AcceptFullDto,
  ) {
    return this.materials.acceptFull({
      requestId: id,
      actorUserId: req.user.userId,
      comment: dto.comment,
    });
  }
}
