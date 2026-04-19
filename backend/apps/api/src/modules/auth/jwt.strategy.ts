import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { SystemRole } from '@app/rbac';

export interface AuthenticatedUser {
  userId: string;
  systemRole: SystemRole;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(cfg: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: cfg.get<string>('JWT_ACCESS_SECRET') || 'dev',
    });
  }

  async validate(payload: { sub: string; systemRole: SystemRole }): Promise<AuthenticatedUser> {
    return { userId: payload.sub, systemRole: payload.systemRole };
  }
}
