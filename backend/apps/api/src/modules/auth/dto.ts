import { ApiProperty } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  Length,
  Matches,
  MinLength,
} from 'class-validator';
import { SystemRole } from '@app/rbac';

const PHONE_REGEX = /^\+?[0-9]{10,15}$/;

export class RegisterDto {
  @ApiProperty({ example: '+79991112233' })
  @IsString()
  @Matches(PHONE_REGEX, { message: 'phone must be E.164-like, 10–15 digits, optional leading +' })
  phone!: string;

  @ApiProperty({ minLength: 8 })
  @IsString()
  @MinLength(8)
  password!: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @Length(1, 100)
  firstName!: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @Length(1, 100)
  lastName!: string;

  @ApiProperty({ enum: ['customer', 'representative', 'contractor', 'master'] })
  @IsEnum(['customer', 'representative', 'contractor', 'master'])
  role!: Exclude<SystemRole, 'admin'>;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  language?: string;
}

export class LoginDto {
  @ApiProperty()
  @IsString()
  @Matches(PHONE_REGEX)
  phone!: string;

  @ApiProperty()
  @IsString()
  @MinLength(1)
  password!: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  deviceId?: string;
}

export class RefreshDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  deviceId?: string;
}

export class LogoutDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;
}

export class RecoverySendDto {
  @ApiProperty()
  @IsString()
  @Matches(PHONE_REGEX)
  phone!: string;
}

export class RecoveryVerifyDto {
  @ApiProperty()
  @IsString()
  @Matches(PHONE_REGEX)
  phone!: string;

  @ApiProperty()
  @IsString()
  @Length(6, 6)
  code!: string;
}

export class RecoveryResetDto {
  @ApiProperty()
  @IsString()
  @Matches(PHONE_REGEX)
  phone!: string;

  @ApiProperty()
  @IsString()
  @Length(6, 6)
  code!: string;

  @ApiProperty()
  @IsString()
  @MinLength(8)
  newPassword!: string;
}
