import { Controller, Get, Headers, Res } from '@nestjs/common';
import { ApiExcludeEndpoint } from '@nestjs/swagger';
import type { Response } from 'express';
import { ForbiddenError, ErrorCodes } from '@app/common';
import { MetricsService } from './metrics.service';

@Controller()
export class MetricsController {
  constructor(private readonly metrics: MetricsService) {}

  @ApiExcludeEndpoint()
  @Get('metrics')
  async collect(
    @Headers('x-metrics-token') token: string | undefined,
    @Res() res: Response,
  ): Promise<void> {
    const expected = process.env.METRICS_TOKEN ?? '';
    if (expected && token !== expected) {
      throw new ForbiddenError(ErrorCodes.FORBIDDEN, 'invalid metrics token');
    }
    const body = await this.metrics.collect();
    res.setHeader('Content-Type', 'text/plain; version=0.0.4; charset=utf-8');
    res.send(body);
  }
}
