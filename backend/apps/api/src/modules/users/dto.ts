import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsEnum, IsIn, IsOptional, IsString, Length } from 'class-validator';
import { SystemRole } from '@app/rbac';

export class UpdateProfileDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @Length(1, 100)
  firstName?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @Length(1, 100)
  lastName?: string;

  @ApiProperty({ required: false, nullable: true })
  @IsOptional()
  @IsString()
  avatarUrl?: string | null;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @Length(2, 5)
  language?: string;

  @ApiProperty({ required: false, nullable: true })
  @IsOptional()
  @IsEmail()
  email?: string | null;
}

export class AddRoleDto {
  @ApiProperty({ enum: ['customer', 'representative', 'contractor', 'master'] })
  @IsEnum(['customer', 'representative', 'contractor', 'master'])
  role!: Exclude<SystemRole, 'admin'>;
}

export class SetActiveRoleDto {
  @ApiProperty({ enum: ['customer', 'representative', 'contractor', 'master'] })
  @IsEnum(['customer', 'representative', 'contractor', 'master'])
  role!: Exclude<SystemRole, 'admin'>;
}

export class RegisterDeviceDto {
  @ApiProperty({ enum: ['ios', 'android'] })
  @IsIn(['ios', 'android'])
  platform!: 'ios' | 'android';

  @ApiProperty()
  @IsString()
  @Length(10, 300)
  token!: string;
}
