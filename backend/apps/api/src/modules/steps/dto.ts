import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Min,
  ValidateNested,
  IsMimeType,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateStepDto {
  @ApiProperty({ maxLength: 200 })
  @IsString()
  @Length(1, 200)
  title!: string;

  @ApiPropertyOptional({ enum: ['regular', 'extra'], default: 'regular' })
  @IsOptional()
  @IsEnum(['regular', 'extra'])
  type?: 'regular' | 'extra';

  @ApiPropertyOptional({ description: 'Цена в копейках (обязательно для type=extra)' })
  @IsOptional()
  @IsInt()
  @Min(0)
  price?: number;

  @ApiPropertyOptional({ maxLength: 2000 })
  @IsOptional()
  @IsString()
  @Length(0, 2000)
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  orderIndex?: number;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @IsString({ each: true })
  assigneeIds?: string[];

  @ApiPropertyOptional({ description: 'ID статьи методички (опционально)' })
  @IsOptional()
  @IsString()
  methodologyArticleId?: string;
}

export class UpdateStepDto {
  @ApiPropertyOptional({ maxLength: 200 })
  @IsOptional()
  @IsString()
  @Length(1, 200)
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  price?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 2000)
  description?: string;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @IsString({ each: true })
  assigneeIds?: string[];

  @ApiPropertyOptional({ description: 'ID статьи методички (null для очистки)' })
  @IsOptional()
  @IsString()
  methodologyArticleId?: string | null;
}

export class ReorderStepItemDto {
  @ApiProperty()
  @IsString()
  id!: string;

  @ApiProperty()
  @IsInt()
  @Min(0)
  orderIndex!: number;
}

export class ReorderStepsDto {
  @ApiProperty({ type: [ReorderStepItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ReorderStepItemDto)
  items!: ReorderStepItemDto[];
}

export class AddSubstepDto {
  @ApiProperty({ maxLength: 1000 })
  @IsString()
  @Length(1, 1000)
  text!: string;
}

export class UpdateSubstepDto {
  @ApiPropertyOptional({ maxLength: 1000 })
  @IsOptional()
  @IsString()
  @Length(1, 1000)
  text?: string;
}

export class PresignPhotoDto {
  @ApiProperty({ description: 'MIME-type: image/jpeg | image/png' })
  @IsMimeType()
  mime!: string;

  @ApiProperty({ description: 'Размер файла в байтах' })
  @IsInt()
  @Min(1)
  size!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  originalName?: string;
}

export class ConfirmPhotoDto {
  @ApiProperty()
  @IsString()
  fileKey!: string;

  @ApiProperty({ description: 'MIME-type финализированного файла' })
  @IsMimeType()
  mimeType!: string;

  @ApiProperty()
  @IsInt()
  @Min(1)
  sizeBytes!: number;
}
