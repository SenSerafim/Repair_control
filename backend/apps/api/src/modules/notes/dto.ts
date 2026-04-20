import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, Length } from 'class-validator';

export class CreateNoteDto {
  @ApiProperty({ enum: ['personal', 'for_me', 'stage'] })
  @IsEnum(['personal', 'for_me', 'stage'])
  scope!: 'personal' | 'for_me' | 'stage';

  @ApiProperty({ maxLength: 5000 })
  @IsString()
  @Length(1, 5000)
  text!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  addresseeId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  stageId?: string;
}

export class UpdateNoteDto {
  @ApiProperty({ maxLength: 5000 })
  @IsString()
  @Length(1, 5000)
  text!: string;
}
