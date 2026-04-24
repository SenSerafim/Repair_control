import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { SystemRole } from '@app/rbac';

export interface AccessTokenPayload {
  sub: string;
  systemRole: SystemRole;
}

@Injectable()
export class TokenService {
  constructor(
    private readonly jwt: JwtService,
    private readonly cfg: ConfigService,
  ) {}

  async signAccess(payload: AccessTokenPayload): Promise<string> {
    return this.jwt.signAsync(payload, {
      secret: this.cfg.get<string>('JWT_ACCESS_SECRET'),
      expiresIn: this.cfg.get<number>('JWT_ACCESS_TTL', 900),
    });
  }

  async signRefresh(payload: { sub: string; sid: string }): Promise<string> {
    return this.jwt.signAsync(payload, {
      secret: this.cfg.get<string>('JWT_REFRESH_SECRET'),
      expiresIn: this.cfg.get<number>('JWT_REFRESH_TTL', 2_592_000),
    });
  }

  async verifyRefresh<T extends object = { sub: string; sid: string }>(token: string): Promise<T> {
    return (await this.jwt.verifyAsync(token, {
      secret: this.cfg.get<string>('JWT_REFRESH_SECRET'),
    })) as T;
  }

  async hashRefresh(token: string): Promise<string> {
    return bcrypt.hash(token, 10);
  }

  async compareRefresh(token: string, hash: string): Promise<boolean> {
    return bcrypt.compare(token, hash);
  }
}
