import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { LegalPublicationKind } from '@prisma/client';
import {
  IsEnum,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Matches,
  Max,
  Min,
} from 'class-validator';

const SLUG_PATTERN = /^[a-z0-9][a-z0-9-]{1,79}$/;

/** Создание новой публикации (после presigned upload). */
export class CreateLegalPublicationDto {
  @ApiProperty({ enum: LegalPublicationKind })
  @IsEnum(LegalPublicationKind)
  kind!: LegalPublicationKind;

  @ApiProperty({
    example: 'privacy-policy',
    description: 'Стабильный slug (ascii-lowercase, dash)',
  })
  @IsString()
  @Length(2, 80)
  @Matches(SLUG_PATTERN)
  slug!: string;

  @ApiProperty()
  @IsString()
  @Length(1, 200)
  title!: string;

  @ApiProperty({
    description: 'fileKey, полученный из /api/files/presign-upload (scope=legal/<slug>)',
  })
  @IsString()
  @Length(1, 500)
  fileKey!: string;

  @ApiProperty({ enum: ['application/pdf'] })
  @IsIn(['application/pdf'])
  mimeType!: string;

  @ApiProperty({ minimum: 1, maximum: 25 * 1024 * 1024 })
  @IsInt()
  @Min(1)
  @Max(25 * 1024 * 1024)
  sizeBytes!: number;
}

/** Обновление: title и/или новая версия файла. Если передан новый fileKey — version++. */
export class UpdateLegalPublicationDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 200)
  title?: string;

  @ApiPropertyOptional({ description: 'Новый fileKey → version++' })
  @IsOptional()
  @IsString()
  @Length(1, 500)
  fileKey?: string;

  @ApiPropertyOptional({ enum: ['application/pdf'] })
  @IsOptional()
  @IsIn(['application/pdf'])
  mimeType?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(25 * 1024 * 1024)
  sizeBytes?: number;
}
