import { ApiProperty } from '@nestjs/swagger';
import {
  IsArray,
  IsDateString,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Length,
  Matches,
  Min,
} from 'class-validator';

const PHONE_REGEX = /^\+?[0-9]{10,15}$/;

export class CreateProjectDto {
  @ApiProperty()
  @IsString()
  @Length(1, 200)
  title!: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @Length(1, 500)
  address?: string;

  @ApiProperty({ required: false, description: 'Описание / комментарий проекта (≤2000 символов)' })
  @IsOptional()
  @IsString()
  @Length(0, 2000)
  description?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsDateString()
  plannedStart?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsDateString()
  plannedEnd?: string;

  @ApiProperty({ required: false, type: 'integer' })
  @IsOptional()
  @IsInt()
  @Min(0)
  workBudget?: number;

  @ApiProperty({ required: false, type: 'integer' })
  @IsOptional()
  @IsInt()
  @Min(0)
  materialsBudget?: number;

  /// П1.8 — список названий этапов для создания вместе с проектом
  /// (в одной транзакции). Если поле опущено — бекенд подставит дефолтные 3
  /// плейсхолдера («Подготовка / Основные работы / Сдача»). Пустой массив
  /// `[]` подавляет авто-создание (для API-клиентов).
  @ApiProperty({
    required: false,
    type: [String],
    description:
      'Названия этапов для создания вместе с проектом. Опустить — 3 плейсхолдера. [] — без этапов.',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @Length(1, 200, { each: true })
  initialStages?: string[];
}

export class UpdateProjectDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @Length(1, 200)
  title?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @Length(1, 500)
  address?: string;

  @ApiProperty({ required: false, description: 'Описание / комментарий проекта (≤2000 символов)' })
  @IsOptional()
  @IsString()
  @Length(0, 2000)
  description?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsDateString()
  plannedStart?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsDateString()
  plannedEnd?: string;

  @ApiProperty({ required: false, type: 'integer' })
  @IsOptional()
  @IsInt()
  @Min(0)
  workBudget?: number;

  @ApiProperty({ required: false, type: 'integer' })
  @IsOptional()
  @IsInt()
  @Min(0)
  materialsBudget?: number;
}

export class AddMemberDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  userId!: string;

  @ApiProperty({ enum: ['customer', 'representative', 'foreman', 'master'] })
  @IsEnum(['customer', 'representative', 'foreman', 'master'])
  role!: 'customer' | 'representative' | 'foreman' | 'master';

  @ApiProperty({ required: false, type: 'object' })
  @IsOptional()
  permissions?: Record<string, boolean>;

  @ApiProperty({ required: false, type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  stageIds?: string[];

  /// Серафим 08.06.2026: специализация (опционально, только для master).
  @ApiProperty({ required: false, type: String })
  @IsOptional()
  @IsString()
  specialization?: string;
}

export class UpdateMembershipDto {
  @ApiProperty({ required: false, type: 'object' })
  @IsOptional()
  permissions?: Record<string, boolean>;

  @ApiProperty({ required: false, type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  stageIds?: string[];
}

export class InviteByPhoneDto {
  @ApiProperty()
  @IsString()
  @Matches(PHONE_REGEX)
  phone!: string;

  @ApiProperty({ enum: ['customer', 'representative', 'foreman', 'master'] })
  @IsEnum(['customer', 'representative', 'foreman', 'master'])
  role!: 'customer' | 'representative' | 'foreman' | 'master';
}

export class CopyProjectDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @Length(1, 200)
  newTitle?: string;
}

export class SearchUserDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  email?: string;
}

// ---------- P2: invite-by-code ----------

export class GenerateInviteCodeDto {
  @ApiProperty({ enum: ['customer', 'representative', 'foreman', 'master'] })
  @IsEnum(['customer', 'representative', 'foreman', 'master'])
  role!: 'customer' | 'representative' | 'foreman' | 'master';

  @ApiProperty({ required: false, type: 'object' })
  @IsOptional()
  permissions?: Record<string, boolean>;

  @ApiProperty({ required: false, type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  stageIds?: string[];
}

export class JoinByCodeDto {
  @ApiProperty()
  @IsString()
  @Length(6, 6, { message: 'code must be exactly 6 digits' })
  @Matches(/^\d{6}$/, { message: 'code must contain only digits' })
  code!: string;
}

// ---------- P2.1 (раздел 5.3) — отдельная форма «Изменить общий бюджет» ----------

export class UpdateBudgetDto {
  @ApiProperty({ required: false, type: 'integer', description: 'Бюджет работ, копейки' })
  @IsOptional()
  @IsInt()
  @Min(0)
  workBudget?: number;

  @ApiProperty({ required: false, type: 'integer', description: 'Бюджет материалов, копейки' })
  @IsOptional()
  @IsInt()
  @Min(0)
  materialsBudget?: number;

  @ApiProperty({ required: false, description: 'Причина изменения (логируется в feed)' })
  @IsOptional()
  @IsString()
  @Length(0, 500)
  reason?: string;
}

// ---------- P2.16 — выход / hide ----------

export class LeaveTeamDto {
  @ApiProperty({
    required: false,
    enum: ['transfer_to_owner', 'take_away'],
    description:
      'Что сделать с инструментами участника, оставшимися в проекте (П2.15). По умолчанию transfer_to_owner.',
  })
  @IsOptional()
  @IsEnum(['transfer_to_owner', 'take_away'])
  toolsAction?: 'transfer_to_owner' | 'take_away';
}
