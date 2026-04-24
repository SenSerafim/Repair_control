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
