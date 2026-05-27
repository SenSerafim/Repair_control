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
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { Response } from 'express';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { InvalidInputError, PrismaService } from '@app/common';
import { DocumentsService, DocumentViewer } from './documents.service';
import {
  ListDocumentsQueryDto,
  PatchDocumentDto,
  PresignUploadDto,
  UploadDocumentDto,
} from './dto';

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

  /**
   * Server-side multipart upload. Принимает файл напрямую в API (multer
   * в памяти, лимит 200 МБ — совпадает с docs/-policy в FilesService).
   * Используется мобилкой как основной путь загрузки: presigned-PUT в
   * Selectel оказался нестабилен с части устройств (TLS / chunked).
   */
  @Post('projects/:projectId/documents/upload')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 200 * 1024 * 1024, files: 1 },
    }),
  )
  @RequireAccess({
    action: 'document.write',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async upload(
    @Param('projectId') projectId: string,
    @UploadedFile()
    file: { buffer: Buffer; mimetype: string; size: number; originalname: string } | undefined,
    @Body() dto: UploadDocumentDto,
    @Req() req: any,
  ) {
    if (!file) {
      throw new InvalidInputError('files.no_file', 'file is required (multipart field "file")');
    }
    return this.docs.uploadDocument(
      projectId,
      req.user.userId,
      {
        buffer: file.buffer,
        mimeType: file.mimetype,
        size: file.size,
        originalName: file.originalname,
      },
      {
        category: dto.category,
        title: dto.title,
        stageId: dto.stageId,
        stepId: dto.stepId,
        description: dto.description,
        documentDate: dto.documentDate,
      },
    );
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

  /**
   * Стрим самого файла через API. URL отдаётся клиентам через `attachUrls()`
   * (поле `url` объекта Document) и через `download()` — заменяет presigned
   * redirect на S3. Auth — обычный AuthGuard + AccessGuard.
   */
  @Get('documents/:id/file')
  @RequireAccess({
    action: 'document.read',
    resource: 'document',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async streamFile(@Param('id') id: string, @Req() req: any, @Res() res: Response) {
    const doc = await this.prisma.document.findUnique({
      where: { id },
      select: { projectId: true },
    });
    const viewer = doc
      ? await this.buildViewer(req.user.userId, doc.projectId)
      : { userId: req.user.userId };
    const { stream, mimeType, contentLength, filename } = await this.docs.streamFile(id, viewer);
    res.setHeader('Content-Type', mimeType);
    res.setHeader('Content-Length', contentLength);
    res.setHeader(
      'Content-Disposition',
      `inline; filename*=UTF-8''${encodeURIComponent(filename)}`,
    );
    res.setHeader('Cache-Control', 'private, max-age=300');
    stream.on('error', (err) => {
      res.destroy(err);
    });
    stream.pipe(res);
  }

  @Get('documents/:id/thumbnail-file')
  @RequireAccess({
    action: 'document.read',
    resource: 'document',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async streamThumbnail(@Param('id') id: string, @Req() req: any, @Res() res: Response) {
    const doc = await this.prisma.document.findUnique({
      where: { id },
      select: { projectId: true },
    });
    const viewer = doc
      ? await this.buildViewer(req.user.userId, doc.projectId)
      : { userId: req.user.userId };
    const { stream, mimeType } = await this.docs.streamThumbnail(id, viewer);
    res.setHeader('Content-Type', mimeType);
    res.setHeader('Cache-Control', 'private, max-age=600');
    stream.on('error', (err) => {
      res.destroy(err);
    });
    stream.pipe(res);
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
