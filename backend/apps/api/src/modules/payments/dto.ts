import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Length, Min } from 'class-validator';

export class CreateAdvanceDto {
  @ApiProperty({ description: 'Получатель (foreman или master)' })
  @IsString()
  toUserId!: string;

  @ApiProperty({ description: 'Сумма в копейках' })
  @IsInt()
  @Min(1)
  amount!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  stageId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 2000)
  comment?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  photoKey?: string;
}

export class DistributeDto {
  @ApiProperty({ description: 'Получатель (master)' })
  @IsString()
  toUserId!: string;

  @ApiProperty({ description: 'Сумма в копейках' })
  @IsInt()
  @Min(1)
  amount!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  stageId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(0, 2000)
  comment?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  photoKey?: string;
}
