import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PrismaModule } from '@app/common';
import { WsAuthService } from './ws-auth.service';
import { ChatsGateway } from './chats.gateway';

@Module({
  imports: [
    PrismaModule,
    JwtModule.register({
      secret: process.env.JWT_ACCESS_SECRET,
      signOptions: { expiresIn: Number(process.env.JWT_ACCESS_TTL ?? 900) },
    }),
  ],
  providers: [WsAuthService, ChatsGateway],
  exports: [ChatsGateway, WsAuthService],
})
export class RealtimeModule {}
