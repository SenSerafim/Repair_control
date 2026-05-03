import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Length, Min } from 'class-validator';

export class CreateToolDto {
  @ApiProperty({ maxLength: 200 })
  @IsString()
  @Length(1, 200)
  name!: string;

  @ApiProperty()
  @IsInt()
  @Min(1)
  totalQty!: number;

  @ApiPropertyOptional({ maxLength: 20 })
  @IsOptional()
  @IsString()
  @Length(0, 20)
  unit?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  photoKey?: string;

  /// П2.14 — серийник, опц. свободный текст
  @ApiPropertyOptional({ maxLength: 100 })
  @IsOptional()
  @IsString()
  @Length(0, 100)
  serial?: string;

  /// П2.15 — сразу добавить в проект (необязательно)
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  projectId?: string;
}

export class UpdateToolDto {
  @ApiPropertyOptional({ maxLength: 200 })
  @IsOptional()
  @IsString()
  @Length(1, 200)
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  totalQty?: number;

  @ApiPropertyOptional({ maxLength: 20 })
  @IsOptional()
  @IsString()
  @Length(0, 20)
  unit?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  photoKey?: string;
}

export class IssueToolDto {
  @ApiProperty()
  @IsString()
  toolItemId!: string;

  @ApiProperty()
  @IsString()
  toUserId!: string;

  @ApiProperty()
  @IsInt()
  @Min(1)
  qty!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  stageId?: string;
}

export class ReturnToolDto {
  @ApiProperty()
  @IsInt()
  @Min(0)
  returnedQty!: number;
}

// ---------- П2.15 — заявка на инструмент ----------

export class RequestToolDto {
  @ApiProperty()
  @IsString()
  toolItemId!: string;

  @ApiPropertyOptional({ description: 'Кол-во запрашиваемых единиц (default 1)' })
  @IsOptional()
  @IsInt()
  @Min(1)
  qty?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  stageId?: string;
}

export class RejectRequestDto {
  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @Length(0, 500)
  comment?: string;
}

export class AddToolsToProjectDto {
  @ApiProperty({ type: [String], description: 'IDs ToolItem из «Моих инструментов»' })
  toolItemIds!: string[];
}
