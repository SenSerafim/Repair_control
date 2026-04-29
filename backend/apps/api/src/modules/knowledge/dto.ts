import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { KnowledgeAssetKind, KnowledgeCategoryScope } from '@prisma/client';
import {
  IsBoolean,
  IsEnum,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Max,
  Min,
} from 'class-validator';

/** Whitelisted module-slug'и — соответствуют разделам мобильного app_router. */
export const VALID_MODULE_SLUGS = [
  'stages',
  'approvals',
  'finance',
  'materials',
  'tools',
  'chats',
  'documents',
  'team',
  'console',
] as const;

export class CreateKnowledgeCategoryDto {
  @ApiProperty()
  @IsString()
  @Length(1, 200)
  title!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 500)
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 80)
  iconKey?: string;

  @ApiProperty({ enum: KnowledgeCategoryScope })
  @IsEnum(KnowledgeCategoryScope)
  scope!: KnowledgeCategoryScope;

  @ApiPropertyOptional({ enum: VALID_MODULE_SLUGS })
  @IsOptional()
  @IsIn(VALID_MODULE_SLUGS as unknown as string[])
  moduleSlug?: string;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  orderIndex?: number;
}

export class UpdateKnowledgeCategoryDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 200)
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 500)
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 80)
  iconKey?: string;

  @ApiPropertyOptional({ enum: KnowledgeCategoryScope })
  @IsOptional()
  @IsEnum(KnowledgeCategoryScope)
  scope?: KnowledgeCategoryScope;

  @ApiPropertyOptional({ enum: VALID_MODULE_SLUGS })
  @IsOptional()
  @IsIn(VALID_MODULE_SLUGS as unknown as string[])
  moduleSlug?: string | null;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  orderIndex?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

export class CreateKnowledgeArticleDto {
  @ApiProperty()
  @IsString()
  @Length(1, 80)
  categoryId!: string;

  @ApiProperty()
  @IsString()
  @Length(1, 300)
  title!: string;

  @ApiProperty({ description: 'Markdown body, до ~200k символов' })
  @IsString()
  @Length(1, 200_000)
  body!: string;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  orderIndex?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

export class UpdateKnowledgeArticleDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 300)
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 200_000)
  body?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  orderIndex?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 80)
  categoryId?: string;
}

export class ConfirmKnowledgeAssetDto {
  @ApiProperty({ enum: KnowledgeAssetKind })
  @IsEnum(KnowledgeAssetKind)
  kind!: KnowledgeAssetKind;

  @ApiProperty({
    description: 'fileKey из /api/files/presign-upload (scope=knowledge/articles/<id>)',
  })
  @IsString()
  @Length(1, 500)
  fileKey!: string;

  @ApiProperty()
  @IsString()
  @Length(1, 100)
  mimeType!: string;

  @ApiProperty({ minimum: 1, maximum: 200 * 1024 * 1024 })
  @IsInt()
  @Min(1)
  @Max(200 * 1024 * 1024)
  sizeBytes!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  durationSec?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  width?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  height?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 500)
  caption?: string;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  orderIndex?: number;
}

export class SetAssetThumbnailDto {
  @ApiProperty()
  @IsString()
  @Length(1, 500)
  fileKey!: string;
}
