import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Length,
  Min,
  ValidateNested,
} from 'class-validator';

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

export class UpdateMaterialItemDto extends MaterialItemInputDto {}

export class MarkBoughtDto {
  @ApiProperty({ description: 'Цена за единицу в копейках (если не указана при создании)' })
  @IsInt()
  @Min(0)
  pricePerUnit!: number;
}

export class DisputeMaterialDto {
  @ApiProperty({ maxLength: 2000 })
  @IsString()
  @Length(1, 2000)
  reason!: string;
}

export class ResolveMaterialDto {
  @ApiProperty({ maxLength: 2000 })
  @IsString()
  @Length(1, 2000)
  resolution!: string;
}

/// §6.1 — заявка на согласование закупки материалов от бригадира.
/// Создаёт Approval(scope=material_purchase). MaterialRequest появляется
/// только после approve заказчиком.
export class RequestMaterialPurchaseDto {
  @ApiProperty()
  @IsString()
  @Length(1, 200)
  title!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  stageId?: string;

  @ApiProperty({ description: 'Сумма в копейках' })
  @IsInt()
  @Min(1)
  amount!: number;

  @ApiProperty({ type: [MaterialItemInputDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => MaterialItemInputDto)
  items!: MaterialItemInputDto[];

  @ApiPropertyOptional({ maxLength: 2000 })
  @IsOptional()
  @IsString()
  @Length(0, 2000)
  comment?: string;

  @ApiPropertyOptional({ maxLength: 200 })
  @IsOptional()
  @IsString()
  @Length(0, 200)
  supplier?: string;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoKeys?: string[];
}
