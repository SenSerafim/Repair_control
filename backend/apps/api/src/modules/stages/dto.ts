import { ApiProperty } from '@nestjs/swagger';
import {
  ArrayMinSize,
  IsArray,
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateStageDto {
  @ApiProperty()
  @IsString()
  @Length(1, 200)
  title!: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  orderIndex?: number;

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

  @ApiProperty({ required: false, type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  foremanIds?: string[];
}

export class UpdateStageDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @Length(1, 200)
  title?: string;

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

  @ApiProperty({ required: false, type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  foremanIds?: string[];
}

export class ReorderItemDto {
  @ApiProperty()
  @IsString()
  id!: string;

  @ApiProperty()
  @IsInt()
  @Min(0)
  orderIndex!: number;
}

export class ReorderStagesDto {
  @ApiProperty({ type: [ReorderItemDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => ReorderItemDto)
  items!: ReorderItemDto[];
}

export class PauseStageDto {
  @ApiProperty({ enum: ['materials', 'approval', 'force_majeure', 'other'] })
  @IsEnum(['materials', 'approval', 'force_majeure', 'other'])
  reason!: 'materials' | 'approval' | 'force_majeure' | 'other';

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @Length(1, 500)
  comment?: string;
}

export class CreateStageFromTemplateDto {
  @ApiProperty()
  @IsString()
  projectId!: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsDateString()
  plannedStart?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsDateString()
  plannedEnd?: string;
}

export class SaveAsTemplateDto {
  @ApiProperty()
  @IsString()
  @Length(1, 200)
  title!: string;
}
