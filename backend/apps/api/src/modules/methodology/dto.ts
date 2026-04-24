import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Length, Min } from 'class-validator';

export class CreateSectionDto {
  @ApiProperty()
  @IsString()
  @Length(1, 200)
  title!: string;

  @ApiProperty()
  @IsInt()
  @Min(0)
  orderIndex!: number;
}

export class UpdateSectionDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 200)
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  orderIndex?: number;
}

export class CreateArticleDto {
  @ApiProperty()
  @IsString()
  @Length(1, 300)
  title!: string;

  @ApiProperty({ description: 'Markdown' })
  @IsString()
  @Length(1, 50000)
  body!: string;

  @ApiProperty()
  @IsInt()
  @Min(0)
  orderIndex!: number;
}

export class UpdateArticleDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 300)
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 50000)
  body?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  orderIndex?: number;
}
