import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { SelfPurchaseStatus } from '@prisma/client';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { Idempotent } from '../idempotency/idempotent.decorator';
import { SelfPurchasesService } from './selfpurchases.service';
import { CreateSelfPurchaseDto, DecideSelfPurchaseDto } from './dto';

@ApiTags('selfpurchases')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller()
export class SelfPurchasesController {
  constructor(private readonly svc: SelfPurchasesService) {}

  @Post('projects/:projectId/selfpurchases')
  @Idempotent()
  @RequireAccess({
    action: 'selfpurchase.create',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async create(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Headers('idempotency-key') idempotencyKey: string,
    @Body() dto: CreateSelfPurchaseDto,
  ) {
    return this.svc.create({
      projectId,
      stageId: dto.stageId,
      amount: dto.amount,
      comment: dto.comment,
      photoKeys: dto.photoKeys,
      actorUserId: req.user.userId,
      idempotencyKey,
    });
  }

  @Get('projects/:projectId/selfpurchases')
  @RequireAccess({
    action: 'selfpurchase.create',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async list(
    @Param('projectId') projectId: string,
    @Query('status') status?: SelfPurchaseStatus,
    @Query('byUserId') byUserId?: string,
  ) {
    return this.svc.listForProject(projectId, { status, byUserId });
  }

  @Get('selfpurchases/:id')
  async get(@Param('id') id: string) {
    return this.svc.get(id);
  }

  @Post('selfpurchases/:id/approve')
  @HttpCode(200)
  @RequireAccess({
    action: 'selfpurchase.confirm',
    resource: 'selfpurchase',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async approve(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: DecideSelfPurchaseDto,
  ) {
    return this.svc.decide(id, {
      decision: 'approved',
      comment: dto.comment,
      actorUserId: req.user.userId,
    });
  }

  @Post('selfpurchases/:id/reject')
  @HttpCode(200)
  @RequireAccess({
    action: 'selfpurchase.confirm',
    resource: 'selfpurchase',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async reject(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: DecideSelfPurchaseDto,
  ) {
    return this.svc.decide(id, {
      decision: 'rejected',
      comment: dto.comment,
      actorUserId: req.user.userId,
    });
  }
}
