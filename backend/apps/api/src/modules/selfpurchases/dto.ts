import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Min,
} from 'class-validator';

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

  /**
   * 3-tier forwarding: при approve бригадиром master-самозакупа автоматически
   * создать вторую запись foreman→customer. Игнорируется при reject и для
   * foreman-самозакупов.
   */
  @ApiPropertyOptional({
    description:
      'Если true и approve мастер-самозакупа бригадиром — создать forward foreman→customer.',
  })
  @IsOptional()
  @IsBoolean()
  forwardOnApprove?: boolean;
}
