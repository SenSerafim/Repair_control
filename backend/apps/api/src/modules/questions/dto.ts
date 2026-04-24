import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, Length } from 'class-validator';

export class AskQuestionDto {
  @ApiProperty()
  @IsString()
  @Length(1, 2000)
  text!: string;

  @ApiProperty()
  @IsString()
  addresseeId!: string;
}

export class AnswerQuestionDto {
  @ApiProperty()
  @IsString()
  @Length(1, 2000)
  answer!: string;
}

export class ListQuestionsFilterDto {
  @ApiPropertyOptional({ enum: ['inbox', 'sent', 'open', 'closed'] })
  @IsOptional()
  @IsEnum(['inbox', 'sent', 'open', 'closed'])
  filter?: 'inbox' | 'sent' | 'open' | 'closed';
}
