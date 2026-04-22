import { INestApplicationContext } from '@nestjs/common';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { ServerOptions, Server } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { Redis } from 'ioredis';

/**
 * Socket.IO adapter with Redis pub/sub для горизонтального масштабирования.
 * При нескольких инстансах API-сервера сообщение из одного доходит клиентов всех инстансов.
 */
export class RedisIoAdapter extends IoAdapter {
  private pub?: Redis;
  private sub?: Redis;

  constructor(app: INestApplicationContext) {
    super(app);
  }

  async init(): Promise<void> {
    const url =
      process.env.REDIS_URL ??
      `redis://${process.env.REDIS_HOST ?? 'localhost'}:${process.env.REDIS_PORT ?? 6379}`;
    this.pub = new Redis(url, { maxRetriesPerRequest: null });
    this.sub = this.pub.duplicate();
  }

  createIOServer(port: number, options?: ServerOptions): Server {
    const mergedOptions: Partial<ServerOptions> = {
      ...options,
      cors: {
        origin: process.env.WS_CORS_ORIGIN ?? '*',
        credentials: true,
      },
      pingInterval: Number(process.env.WS_PING_INTERVAL_MS ?? 25_000),
      pingTimeout: Number(process.env.WS_PING_TIMEOUT_MS ?? 20_000),
    };
    const server = super.createIOServer(port, mergedOptions as ServerOptions) as Server;
    if (this.pub && this.sub) {
      server.adapter(createAdapter(this.pub, this.sub));
    }
    return server;
  }
}
