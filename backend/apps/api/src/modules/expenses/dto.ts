import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';

const CATEGORIES = ['materials', 'transport', 'rental', 'services', 'other'] as const;
export type ExpenseCategoryLike = (typeof CATEGORIES)[number];

export class CreateExpenseDto {
  @ApiProperty({ enum: CATEGORIES })
  @IsEnum(CATEGORIES)
  category!: ExpenseCategoryLike;

  @ApiProperty()
  @IsString()
  @Length(1, 300)
  name!: string;

  @ApiProperty({ description: 'kopecks (int64)' })
  @IsInt()
  @Min(1)
  @Max(Number.MAX_SAFE_INTEGER)
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

  /**
   * S3 key чека, полученный из POST /api/files/presign-upload (scope=expenses/receipts).
   */
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 500)
  photoKey?: string;
}
