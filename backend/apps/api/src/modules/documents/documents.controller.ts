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
import { PrismaService } from '@app/common';
import { DocumentsService, DocumentViewer } from './documents.service';
import { ListDocumentsQueryDto, PatchDocumentDto, PresignUploadDto } from './dto';

@ApiTags('documents')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller()
export class DocumentsController {
  constructor(
    private readonly docs: DocumentsService,
    private readonly prisma: PrismaService,
  ) {}

  private async buildViewer(userId: string, projectId: string): Promise<DocumentViewer> {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerId: true },
    });
    const membership = await this.prisma.membership.findFirst({
      where: { projectId, userId },
      select: { role: true, permissions: true },
    });
    const perms = (membership?.permissions ?? {}) as { canSeeBudget?: boolean };
    return {
      userId,
      isOwner: project?.ownerId === userId,
      membershipRole: membership?.role as DocumentViewer['membershipRole'],
      canSeeBudget: perms.canSeeBudget === true,
    };
  }

  @Post('projects/:projectId/documents/presign-upload')
  @RequireAccess({
    action: 'document.write',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  presign(@Param('projectId') projectId: string, @Body() dto: PresignUploadDto, @Req() req: any) {
    return this.docs.presignUpload(projectId, req.user.userId, dto);
  }

  @Post('documents/:id/confirm')
  @RequireAccess({
    action: 'document.write',
    resource: 'document',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  confirm(@Param('id') id: string, @Req() req: any) {
    return this.docs.confirm(id, req.user.userId);
  }

  @Get('projects/:projectId/documents')
  @RequireAccess({
    action: 'document.read',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async list(
    @Param('projectId') projectId: string,
    @Query() q: ListDocumentsQueryDto,
    @Req() req: any,
  ) {
    const viewer = await this.buildViewer(req.user.userId, projectId);
    return this.docs.list(projectId, q, viewer);
  }

  @Get('documents/:id')
  @RequireAccess({
    action: 'document.read',
    resource: 'document',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async get(@Param('id') id: string, @Req() req: any) {
    const doc = await this.prisma.document.findUnique({
      where: { id },
      select: { projectId: true },
    });
    const viewer = doc
      ? await this.buildViewer(req.user.userId, doc.projectId)
      : { userId: req.user.userId };
    return this.docs.get(id, viewer);
  }

  @Get('documents/:id/download')
  @RequireAccess({
    action: 'document.read',
    resource: 'document',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  download(@Param('id') id: string) {
    return this.docs.download(id);
  }

  @Get('documents/:id/thumbnail')
  @RequireAccess({
    action: 'document.read',
    resource: 'document',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  thumbnail(@Param('id') id: string) {
    return this.docs.thumbnail(id);
  }

  @Patch('documents/:id')
  @RequireAccess({
    action: 'document.write',
    resource: 'document',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  patch(@Param('id') id: string, @Body() dto: PatchDocumentDto, @Req() req: any) {
    return this.docs.patch(id, req.user.userId, dto);
  }

  @Delete('documents/:id')
  @RequireAccess({
    action: 'document.delete',
    resource: 'document',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async delete(@Param('id') id: string, @Req() req: any) {
    await this.docs.softDelete(id, req.user.userId);
    return { deleted: true };
  }
}
