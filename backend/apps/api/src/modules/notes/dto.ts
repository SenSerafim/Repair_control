import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, Length } from 'class-validator';

export class CreateNoteDto {
  @ApiProperty({
    enum: ['personal', 'for_me', 'stage', 'team_broadcast'],
    description: 'team_broadcast (П1.10/П2.19) — заметка для всей команды проекта.',
  })
  @IsEnum(['personal', 'for_me', 'stage', 'team_broadcast'])
  scope!: 'personal' | 'for_me' | 'stage' | 'team_broadcast';

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
