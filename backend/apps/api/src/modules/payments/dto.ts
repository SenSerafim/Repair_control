import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Length, Min } from 'class-validator';

export class CreateAdvanceDto {
  @ApiProperty({ description: 'Получатель (foreman)' })
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

export class DisputePaymentDto {
  @ApiProperty({ maxLength: 2000 })
  @IsString()
  @Length(1, 2000)
  reason!: string;
}

export class ResolvePaymentDto {
  @ApiProperty({ maxLength: 2000 })
  @IsString()
  @Length(1, 2000)
  resolution!: string;

  @ApiPropertyOptional({ description: 'Корректирующая сумма в копейках' })
  @IsOptional()
  @IsInt()
  @Min(0)
  adjustAmount?: number;
}
