import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMaxSize, IsArray, IsInt, IsOptional, IsString, Length, Min } from 'class-validator';

export class CreateSelfPurchaseDto {
  @ApiProperty({ description: 'Сумма в копейках' })
  @IsInt()
  @Min(1)
  amount!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  stageId?: string;

  @ApiPropertyOptional({ maxLength: 2000 })
  @IsOptional()
  @IsString()
  @Length(0, 2000)
  comment?: string;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @IsString({ each: true })
  photoKeys?: string[];
}

export class DecideSelfPurchaseDto {
  @ApiPropertyOptional({ maxLength: 2000 })
  @IsOptional()
  @IsString()
  @Length(0, 2000)
  comment?: string;
}
