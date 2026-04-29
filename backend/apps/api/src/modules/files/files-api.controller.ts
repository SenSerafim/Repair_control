import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsIn, IsInt, IsString, Length, Max, Min } from 'class-validator';
import { FilesService } from '@app/files';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

// Top-level whitelist для DTO. Реальные ограничения mime/size — per-scope через
// FilesService.policyForScope (см. libs/files/src/files.service.ts). Здесь только
// синтаксический guard от заведомо невалидных типов и обрезка экстремальных размеров.
const ALLOWED = [
  'image/jpeg',
  'image/png',
  'application/pdf',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'video/mp4',
  'video/quicktime',
];

class PresignDto {
  @IsString()
  @Length(1, 200)
  originalName!: string;

  @IsIn(ALLOWED)
  mimeType!: string;

  @IsInt()
  @Min(1)
  @Max(200 * 1024 * 1024)
  sizeBytes!: number;

  @IsString()
  @Length(1, 200)
  scope!: string;
}

@ApiTags('files')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('files')
export class FilesApiController {
  constructor(private readonly files: FilesService) {}

  @Post('presign-upload')
  async presign(@Body() dto: PresignDto) {
    return this.files.createPresignedUpload(dto);
  }
}
