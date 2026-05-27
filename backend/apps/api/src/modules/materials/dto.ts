import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsIn,
  IsISO8601,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Length,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

/**
 * Фото позиции заявки. Загружается через FilesService.presign в scope
 * `materials/items/photos/...` и затем передаётся при создании позиции
 * (структура соответствует MaterialItemPhoto в БД).
 * ТЗ-2 §5.2: «Бригадир может скинуть заявку с фоткой пачки кнауфа».
 */
export class MaterialItemPhotoInputDto {
  @ApiProperty({
    description: 'S3-ключ из presign-эндпоинта',
    example: 'materials/items/photos/2026-05-27/abc.jpg',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  fileKey!: string;

  @ApiPropertyOptional({ description: 'S3-ключ thumbnail (если сгенерирован клиентом)' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  thumbKey?: string;

  @ApiProperty({ enum: ['image/jpeg', 'image/png'], example: 'image/jpeg' })
  @IsString()
  @IsIn(['image/jpeg', 'image/png'])
  mimeType!: string;

  @ApiProperty({ minimum: 1, maximum: 20 * 1024 * 1024, description: 'Размер в байтах' })
  @IsInt()
  @Min(1)
  @Max(20 * 1024 * 1024)
  sizeBytes!: number;

  @ApiPropertyOptional({
    default: false,
    description: 'Подтверждение клиента, что EXIF очищен перед загрузкой',
  })
  @IsOptional()
  @IsBoolean()
  exifCleared?: boolean;
}

export class MaterialItemInputDto {
  @ApiProperty()
  @IsString()
  @Length(1, 200)
  name!: string;

  @ApiProperty()
  @IsNumber()
  @Min(0)
  qty!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 20)
  unit?: string;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @Length(0, 500)
  note?: string;

  @ApiPropertyOptional({ description: 'Цена за единицу в копейках' })
  @IsOptional()
  @IsInt()
  @Min(0)
  pricePerUnit?: number;

  /**
   * Срок поставки позиции — ТЗ-2 §5.5. По истечении cron эмитит
   * material_request_overdue для заявки, если она всё ещё открыта.
   */
  @ApiPropertyOptional({ description: 'Срок поставки (ISO date)', example: '2026-06-15' })
  @IsOptional()
  @IsISO8601()
  dueDate?: string;

  /**
   * Фото позиции — ТЗ-2 §5.2. Опционально. Клиент сначала загружает
   * через FilesService.presign, потом передаёт fileKey/meta здесь.
   */
  @ApiPropertyOptional({ type: () => MaterialItemPhotoInputDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => MaterialItemPhotoInputDto)
  photo?: MaterialItemPhotoInputDto;
}

export class CreateMaterialRequestDto {
  @ApiProperty({ enum: ['foreman', 'customer'] })
  @IsEnum(['foreman', 'customer'])
  recipient!: 'foreman' | 'customer';

  @ApiProperty()
  @IsString()
  @Length(1, 200)
  title!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  stageId?: string;

  @ApiPropertyOptional({ maxLength: 2000 })
  @IsOptional()
  @IsString()
  @Length(0, 2000)
  comment?: string;

  @ApiProperty({ type: [MaterialItemInputDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => MaterialItemInputDto)
  items!: MaterialItemInputDto[];
}

/**
 * DTO для приёмки заявок (ТЗ-2 §5.7).
 *
 * Флоу:
 *   1. Любой member проекта → POST /materials/:id/mark-delivered (MarkDeliveredDto)
 *   2. Foreman/customer →
 *        POST /materials/:id/accept-partial (AcceptPartialDto) — с указанием actualQty
 *        POST /materials/:id/accept-full    (AcceptFullDto)    — actualQty = qty для всех
 */

export class MarkDeliveredDto {
  @ApiPropertyOptional({ description: 'Комментарий к отметке доставки (опционально)' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;
}

export class AcceptedItemInputDto {
  @ApiProperty({ description: 'ID позиции заявки' })
  @IsString()
  @IsNotEmpty()
  itemId!: string;

  @ApiProperty({ description: 'Фактически принятое количество', example: 20 })
  @IsNumber()
  @Min(0)
  actualQty!: number;
}

export class AcceptPartialDto {
  @ApiProperty({
    type: [AcceptedItemInputDto],
    description: 'Позиции с фактически принятыми количествами',
  })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => AcceptedItemInputDto)
  items!: AcceptedItemInputDto[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;
}

export class AcceptFullDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;
}
