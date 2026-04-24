import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsObject,
  IsOptional,
  IsString,
  Length,
  IsArray,
  ArrayMaxSize,
} from 'class-validator';

export class CreateApprovalDto {
  @ApiProperty({ enum: ['plan', 'step', 'extra_work', 'deadline_change', 'stage_accept'] })
  @IsEnum(['plan', 'step', 'extra_work', 'deadline_change', 'stage_accept'])
  scope!: 'plan' | 'step' | 'extra_work' | 'deadline_change' | 'stage_accept';

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  stageId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  stepId?: string;

  @ApiProperty({ description: 'Адресат решения (foreman/customer)', type: String })
  @IsString()
  addresseeId!: string;

  @ApiPropertyOptional({ description: 'Payload scope-specific (newEnd, stages[], price, ...)' })
  @IsOptional()
  @IsObject()
  payload?: Record<string, unknown>;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  attachmentKeys?: string[];
}

export class DecideApprovalDto {
  @ApiPropertyOptional({ maxLength: 2000 })
  @IsOptional()
  @IsString()
  @Length(0, 2000)
  comment?: string;
}

export class ResubmitApprovalDto {
  @ApiPropertyOptional({ description: 'Обновлённый payload' })
  @IsOptional()
  @IsObject()
  payload?: Record<string, unknown>;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  attachmentKeys?: string[];
}
