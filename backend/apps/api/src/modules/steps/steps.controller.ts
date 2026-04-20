import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { StepsService } from './steps.service';
import { SubstepsService } from './substeps.service';
import { StepPhotosService } from './step-photos.service';
import {
  AddSubstepDto,
  ConfirmPhotoDto,
  CreateStepDto,
  PresignPhotoDto,
  ReorderStepsDto,
  UpdateStepDto,
  UpdateSubstepDto,
} from './dto';

@ApiTags('steps')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller()
export class StepsController {
  constructor(
    private readonly steps: StepsService,
    private readonly substeps: SubstepsService,
    private readonly photos: StepPhotosService,
  ) {}

  // ----- Steps -----

  @Post('stages/:stageId/steps')
  @RequireAccess({
    action: 'step.manage',
    resource: 'stage',
    resourceIdFrom: { source: 'params', key: 'stageId' },
  })
  async createStep(
    @Req() req: { user: AuthenticatedUser },
    @Param('stageId') stageId: string,
    @Body() dto: CreateStepDto,
  ) {
    return this.steps.create({ ...dto, stageId, actorUserId: req.user.userId });
  }

  @Get('stages/:stageId/steps')
  async listSteps(@Param('stageId') _stageId: string) {
    return this.steps.listForStage(_stageId);
  }

  @Get('steps/:stepId')
  async getStep(@Param('stepId') stepId: string) {
    return this.steps.get(stepId);
  }

  @Patch('steps/:stepId')
  @RequireAccess({
    action: 'step.manage',
    resource: 'step',
    resourceIdFrom: { source: 'params', key: 'stepId' },
  })
  async updateStep(
    @Req() req: { user: AuthenticatedUser },
    @Param('stepId') stepId: string,
    @Body() dto: UpdateStepDto,
  ) {
    return this.steps.update(stepId, { ...dto, actorUserId: req.user.userId });
  }

  @Delete('steps/:stepId')
  @HttpCode(204)
  @RequireAccess({
    action: 'step.manage',
    resource: 'step',
    resourceIdFrom: { source: 'params', key: 'stepId' },
  })
  async deleteStep(@Req() req: { user: AuthenticatedUser }, @Param('stepId') stepId: string) {
    await this.steps.delete(stepId, req.user.userId);
  }

  @Patch('stages/:stageId/steps/reorder')
  @RequireAccess({
    action: 'step.manage',
    resource: 'stage',
    resourceIdFrom: { source: 'params', key: 'stageId' },
  })
  async reorderSteps(
    @Req() req: { user: AuthenticatedUser },
    @Param('stageId') stageId: string,
    @Body() dto: ReorderStepsDto,
  ) {
    return this.steps.reorder(stageId, dto.items, req.user.userId);
  }

  @Post('steps/:stepId/complete')
  @RequireAccess({
    action: 'step.manage',
    resource: 'step',
    resourceIdFrom: { source: 'params', key: 'stepId' },
  })
  async completeStep(@Req() req: { user: AuthenticatedUser }, @Param('stepId') stepId: string) {
    return this.steps.complete(stepId, req.user.userId);
  }

  @Post('steps/:stepId/uncomplete')
  @RequireAccess({
    action: 'step.manage',
    resource: 'step',
    resourceIdFrom: { source: 'params', key: 'stepId' },
  })
  async uncompleteStep(@Req() req: { user: AuthenticatedUser }, @Param('stepId') stepId: string) {
    return this.steps.uncomplete(stepId, req.user.userId);
  }

  // ----- Substeps -----

  @Post('steps/:stepId/substeps')
  @RequireAccess({
    action: 'step.add_substep',
    resource: 'step',
    resourceIdFrom: { source: 'params', key: 'stepId' },
  })
  async addSubstep(
    @Req() req: { user: AuthenticatedUser },
    @Param('stepId') stepId: string,
    @Body() dto: AddSubstepDto,
  ) {
    return this.substeps.add(stepId, dto.text, req.user.userId);
  }

  @Patch('substeps/:substepId')
  async updateSubstep(
    @Req() req: { user: AuthenticatedUser },
    @Param('substepId') substepId: string,
    @Body() dto: UpdateSubstepDto,
  ) {
    return this.substeps.update(substepId, dto.text ?? '', req.user.userId);
  }

  @Post('substeps/:substepId/complete')
  async completeSubstep(
    @Req() req: { user: AuthenticatedUser },
    @Param('substepId') substepId: string,
  ) {
    return this.substeps.complete(substepId, req.user.userId);
  }

  @Post('substeps/:substepId/uncomplete')
  async uncompleteSubstep(
    @Req() req: { user: AuthenticatedUser },
    @Param('substepId') substepId: string,
  ) {
    return this.substeps.uncomplete(substepId, req.user.userId);
  }

  @Delete('substeps/:substepId')
  @HttpCode(204)
  async deleteSubstep(
    @Req() req: { user: AuthenticatedUser },
    @Param('substepId') substepId: string,
  ) {
    await this.substeps.delete(substepId, req.user.userId);
  }

  // ----- Photos -----

  @Post('steps/:stepId/photos/presign')
  @RequireAccess({
    action: 'step.photo.upload',
    resource: 'step',
    resourceIdFrom: { source: 'params', key: 'stepId' },
  })
  async presignPhoto(
    @Req() req: { user: AuthenticatedUser },
    @Param('stepId') stepId: string,
    @Body() dto: PresignPhotoDto,
  ) {
    return this.photos.presign(stepId, dto.mime, dto.size, dto.originalName, req.user.userId);
  }

  @Post('steps/:stepId/photos/confirm')
  @RequireAccess({
    action: 'step.photo.upload',
    resource: 'step',
    resourceIdFrom: { source: 'params', key: 'stepId' },
  })
  async confirmPhoto(
    @Req() req: { user: AuthenticatedUser },
    @Param('stepId') stepId: string,
    @Body() dto: ConfirmPhotoDto,
  ) {
    return this.photos.confirm(stepId, dto, req.user.userId);
  }

  @Get('steps/:stepId/photos')
  async listPhotos(@Param('stepId') stepId: string) {
    return this.photos.listForStep(stepId);
  }

  @Delete('photos/:photoId')
  @HttpCode(204)
  async deletePhoto(@Req() req: { user: AuthenticatedUser }, @Param('photoId') photoId: string) {
    await this.photos.delete(photoId, req.user.userId);
  }
}
