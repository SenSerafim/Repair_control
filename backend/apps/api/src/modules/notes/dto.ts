import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';

export class CreateNoteDto {
  @ApiProperty({
    enum: ['personal', 'for_me', 'stage', 'team_broadcast'],
    description: 'team_broadcast (П1.10/П2.19) — заметка для всей команды проекта.',
  })
  @IsEnum(['personal', 'for_me', 'stage', 'team_broadcast'])
  scope!: 'personal' | 'for_me' | 'stage' | 'team_broadcast';

  @ApiPropertyOptional({
    enum: ['text', 'audio'],
    description: 'NEWFIX-2 §11.4. По умолчанию text. Для audio обязателен audioKey.',
  })
  @IsOptional()
  @IsEnum(['text', 'audio'])
  kind?: 'text' | 'audio';

  @ApiPropertyOptional({
    maxLength: 5000,
    description: 'Для kind=text — обязателен. Для kind=audio — опциональная подпись/caption.',
  })
  @IsOptional()
  @IsString()
  @Length(0, 5000)
  text?: string;

  @ApiPropertyOptional({
    description: 'S3 key, полученный из POST /files/presign-upload (scope=notes/audio).',
  })
  @IsOptional()
  @IsString()
  @Length(1, 500)
  audioKey?: string;

  @ApiPropertyOptional({
    description: 'MIME аудио-файла, должен совпадать со значением при presign.',
  })
  @IsOptional()
  @IsString()
  @Length(1, 100)
  audioMimeType?: string;

  @ApiPropertyOptional({ description: 'Длительность аудио в миллисекундах.' })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(60 * 60 * 1000)
  audioDurationMs?: number;

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
  @ApiProperty({
    maxLength: 5000,
    description:
      'Для text-заметок — новый текст (1..5000). Для audio — caption (можно пустую строку).',
  })
  @IsString()
  @Length(0, 5000)
  text!: string;
}
