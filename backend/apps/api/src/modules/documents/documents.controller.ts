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
import { DocumentsService } from './documents.service';
import { ListDocumentsQueryDto, PatchDocumentDto, PresignUploadDto } from './dto';

@ApiTags('documents')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller()
export class DocumentsController {
  constructor(private readonly docs: DocumentsService) {}

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
  list(@Param('projectId') projectId: string, @Query() q: ListDocumentsQueryDto) {
    return this.docs.list(projectId, q);
  }

  @Get('documents/:id')
  @RequireAccess({
    action: 'document.read',
    resource: 'document',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  get(@Param('id') id: string) {
    return this.docs.get(id);
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
