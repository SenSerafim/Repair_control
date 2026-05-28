import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMinSize, IsArray, IsEnum, IsOptional, IsString, Length } from 'class-validator';

/// NEWFIX-2 §7.1 — статус инструмента; синхронизирован с enum Prisma `ToolStatus`.
export type ToolStatusValue = 'in_storage' | 'on_project' | 'with_employee';

/**
 * Создание инструмента в личном профиле (My Tools), без привязки к проекту.
 * NEWFIX-2 §7.1 — теперь поддерживаем артикул, статус и локацию.
 */
export class CreateToolDto {
  @ApiProperty({ maxLength: 200 })
  @IsString()
  @Length(1, 200)
  name!: string;

  @ApiPropertyOptional({ maxLength: 100, description: 'Артикул производителя' })
  @IsOptional()
  @IsString()
  @Length(0, 100)
  article?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  photoKey?: string;

  @ApiPropertyOptional({ maxLength: 100, description: 'Серийный/инвентарный номер' })
  @IsOptional()
  @IsString()
  @Length(0, 100)
  serial?: string;

  @ApiPropertyOptional({
    enum: ['in_storage', 'on_project', 'with_employee'],
    description: 'NEWFIX-2 §7.1; по умолчанию in_storage.',
  })
  @IsOptional()
  @IsEnum(['in_storage', 'on_project', 'with_employee'])
  status?: ToolStatusValue;

  @ApiPropertyOptional({
    maxLength: 200,
    description: 'Свободный текст — «Склад №1», адрес, «Гараж». Для status=in_storage.',
  })
  @IsOptional()
  @IsString()
  @Length(0, 200)
  storageLocation?: string;

  @ApiPropertyOptional({
    description: 'Если status=with_employee — ID сотрудника, за которым закреплён.',
  })
  @IsOptional()
  @IsString()
  assignedEmployeeId?: string;
}

/**
 * Создание инструмента сразу в проекте. Любой member проекта может добавить:
 * — `ownerId` задаёт владельца (по умолчанию = текущий пользователь).
 * Создатель автоматически становится initial-holder. Статус автоматически
 * становится 'on_project'.
 */
export class CreateProjectToolDto {
  @ApiProperty({ maxLength: 200 })
  @IsString()
  @Length(1, 200)
  name!: string;

  @ApiPropertyOptional({ maxLength: 100, description: 'Артикул производителя' })
  @IsOptional()
  @IsString()
  @Length(0, 100)
  article?: string;

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

/**
 * NEWFIX-2 §7.2 — Edit / Сменить статус. Любое из полей опционально;
 * валидируем согласованность сервисом (storageLocation требует status=in_storage и т.д.).
 */
export class UpdateToolDto {
  @ApiPropertyOptional({ maxLength: 200 })
  @IsOptional()
  @IsString()
  @Length(1, 200)
  name?: string;

  @ApiPropertyOptional({ maxLength: 100 })
  @IsOptional()
  @IsString()
  @Length(0, 100)
  article?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  photoKey?: string;

  @ApiPropertyOptional({ maxLength: 100 })
  @IsOptional()
  @IsString()
  @Length(0, 100)
  serial?: string;

  @ApiPropertyOptional({ enum: ['in_storage', 'on_project', 'with_employee'] })
  @IsOptional()
  @IsEnum(['in_storage', 'on_project', 'with_employee'])
  status?: ToolStatusValue;

  @ApiPropertyOptional({ maxLength: 200 })
  @IsOptional()
  @IsString()
  @Length(0, 200)
  storageLocation?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  assignedEmployeeId?: string;
}

export class AttachToolsToProjectDto {
  @ApiProperty({ type: [String], description: 'IDs ToolItem из «Моих инструментов»' })
  @IsArray()
  @ArrayMinSize(1)
  @IsString({ each: true })
  toolItemIds!: string[];

  @ApiPropertyOptional({
    description:
      'NEWFIX-2 §8.3 — ответственный за инструмент (member проекта). По умолчанию бригадир проекта.',
  })
  @IsOptional()
  @IsString()
  responsibleUserId?: string;
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
