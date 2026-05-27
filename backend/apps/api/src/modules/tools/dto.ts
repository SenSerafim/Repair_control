import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMinSize, IsArray, IsOptional, IsString, Length } from 'class-validator';

/**
 * Создание инструмента в личном профиле (My Tools), без привязки к проекту.
 */
export class CreateToolDto {
  @ApiProperty({ maxLength: 200 })
  @IsString()
  @Length(1, 200)
  name!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  photoKey?: string;

  @ApiPropertyOptional({ maxLength: 100, description: 'Серийный/инвентарный номер' })
  @IsOptional()
  @IsString()
  @Length(0, 100)
  serial?: string;
}

/**
 * Создание инструмента сразу в проекте. Любой member проекта может добавить:
 * — `ownerId` задаёт владельца (по умолчанию = текущий пользователь).
 * Создатель автоматически становится initial-holder.
 */
export class CreateProjectToolDto {
  @ApiProperty({ maxLength: 200 })
  @IsString()
  @Length(1, 200)
  name!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  photoKey?: string;

  @ApiPropertyOptional({ maxLength: 100 })
  @IsOptional()
  @IsString()
  @Length(0, 100)
  serial?: string;

  @ApiPropertyOptional({
    description: 'ID владельца (member проекта). По умолчанию — текущий пользователь.',
  })
  @IsOptional()
  @IsString()
  ownerId?: string;
}

export class UpdateToolDto {
  @ApiPropertyOptional({ maxLength: 200 })
  @IsOptional()
  @IsString()
  @Length(1, 200)
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  photoKey?: string;

  @ApiPropertyOptional({ maxLength: 100 })
  @IsOptional()
  @IsString()
  @Length(0, 100)
  serial?: string;
}

export class AttachToolsToProjectDto {
  @ApiProperty({ type: [String], description: 'IDs ToolItem из «Моих инструментов»' })
  @IsArray()
  @ArrayMinSize(1)
  @IsString({ each: true })
  toolItemIds!: string[];
}

export class ClaimToolDto {
  @ApiPropertyOptional({
    maxLength: 200,
    description: 'Опциональный комментарий («забрал на 3 этаж»)',
  })
  @IsOptional()
  @IsString()
  @Length(0, 200)
  note?: string;
}
