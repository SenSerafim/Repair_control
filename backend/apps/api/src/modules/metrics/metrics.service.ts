import { Injectable, OnModuleInit } from '@nestjs/common';
import * as client from 'prom-client';

/**
 * Prometheus-метрики. Базовый счёт HTTP + BullMQ-очередь глубины (регистрируется извне
 * через registerQueueGauge). Собрано на `prom-client` default registry.
 */
@Injectable()
export class MetricsService implements OnModuleInit {
  readonly registry: client.Registry;

  readonly httpCounter: client.Counter<'method' | 'path' | 'status'>;
  readonly httpHistogram: client.Histogram<'method' | 'path' | 'status'>;
  readonly queueDepth: client.Gauge<'name'>;
  readonly pushSent: client.Counter<'kind' | 'result'>;
  readonly exportJobs: client.Counter<'kind' | 'status'>;

  constructor() {
    this.registry = new client.Registry();
    client.collectDefaultMetrics({ register: this.registry });

    this.httpCounter = new client.Counter({
      name: 'http_requests_total',
      help: 'HTTP requests processed',
      labelNames: ['method', 'path', 'status'],
      registers: [this.registry],
    });
    this.httpHistogram = new client.Histogram({
      name: 'http_request_duration_seconds',
      help: 'HTTP request duration (s)',
      labelNames: ['method', 'path', 'status'],
      buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
      registers: [this.registry],
    });
    this.queueDepth = new client.Gauge({
      name: 'bullmq_queue_depth',
      help: 'Depth of BullMQ queues (waiting+delayed+active)',
      labelNames: ['name'],
      registers: [this.registry],
    });
    this.pushSent = new client.Counter({
      name: 'push_notifications_total',
      help: 'Push notifications dispatched',
      labelNames: ['kind', 'result'],
      registers: [this.registry],
    });
    this.exportJobs = new client.Counter({
      name: 'export_jobs_total',
      help: 'Export jobs requested/finished',
      labelNames: ['kind', 'status'],
      registers: [this.registry],
    });
  }

  async onModuleInit(): Promise<void> {
    // нет особой инициализации, но оставляем хук для будущих подключений.
  }

  async collect(): Promise<string> {
    return this.registry.metrics();
  }
}
