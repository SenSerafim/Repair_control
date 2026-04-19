import { Body, Controller, HttpCode, Post, Req } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { AuthService } from './auth.service';
import { RecoveryService } from './recovery.service';
import {
  LoginDto,
  LogoutDto,
  RecoveryResetDto,
  RecoverySendDto,
  RecoveryVerifyDto,
  RefreshDto,
  RegisterDto,
} from './dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly recovery: RecoveryService,
  ) {}

  @Post('register')
  @HttpCode(201)
  async register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @Post('login')
  @HttpCode(200)
  async login(@Body() dto: LoginDto, @Req() req: Request) {
    return this.auth.login({
      phone: dto.phone,
      password: dto.password,
      deviceId: dto.deviceId ?? 'unknown',
      ip: req.ip ?? '0.0.0.0',
      userAgent: req.headers['user-agent']?.toString(),
    });
  }

  @Post('refresh')
  @HttpCode(200)
  async refresh(@Body() dto: RefreshDto, @Req() req: Request) {
    return this.auth.refresh(dto.refreshToken, dto.deviceId ?? 'unknown', req.ip ?? '0.0.0.0');
  }

  @Post('logout')
  @HttpCode(204)
  async logout(@Body() dto: LogoutDto): Promise<void> {
    await this.auth.logout(dto.refreshToken);
  }

  @Post('recovery/send')
  @HttpCode(200)
  async recoverySend(@Body() dto: RecoverySendDto) {
    return this.recovery.sendCode(dto.phone);
  }

  @Post('recovery/verify')
  @HttpCode(204)
  async recoveryVerify(@Body() dto: RecoveryVerifyDto): Promise<void> {
    await this.recovery.verifyCode(dto.phone, dto.code);
  }

  @Post('recovery/reset')
  @HttpCode(204)
  async recoveryReset(@Body() dto: RecoveryResetDto): Promise<void> {
    await this.recovery.resetPassword(dto.phone, dto.code, dto.newPassword);
  }
}
