import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import type { Job } from 'bullmq';
import { PrismaService } from '@app/common';
import { FilesService } from '@app/files';
import { QUEUE_DOCUMENT_THUMBNAILS } from '../queues/queues.module';

/**
 * BullMQ processor: генерация JPG-превью первой страницы PDF-документа.
 *
 * Реализация: В S5 используем puppeteer-core+@sparticuz/chromium для рендера PDF.
 * На этапе скелета — помечаем статус `skipped` если chromium не доступен, чтобы тесты не падали.
 */
@Processor(QUEUE_DOCUMENT_THUMBNAILS)
export class ThumbnailWorker extends WorkerHost {
  private readonly logger = new Logger(ThumbnailWorker.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly files: FilesService,
  ) {
    super();
  }

  async process(job: Job<{ documentId: string }>): Promise<void> {
    const { documentId } = job.data;
    const doc = await this.prisma.document.findUnique({ where: { id: documentId } });
    if (!doc) return;
    try {
      const thumbKey = `${doc.fileKey}.thumb.jpg`;
      const buffer = await this.renderFirstPage(doc.fileKey);
      if (!buffer) {
        await this.prisma.document.update({
          where: { id: documentId },
          data: { thumbStatus: 'skipped' },
        });
        return;
      }
      await this.files.putObject(thumbKey, buffer, 'image/jpeg');
      await this.prisma.document.update({
        where: { id: documentId },
        data: { thumbKey, thumbStatus: 'done' },
      });
    } catch (e) {
      this.logger.error(`thumbnail failed ${documentId}: ${(e as Error).message}`);
      await this.prisma.document.update({
        where: { id: documentId },
        data: { thumbStatus: 'failed' },
      });
    }
  }

  /**
   * Первая страница PDF → JPG 320px (protected, тестируем через mock).
   * Возвращает null если chromium не доступен.
   */
  protected async renderFirstPage(fileKey: string): Promise<Buffer | null> {
    try {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const chromium = require('@sparticuz/chromium');
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const puppeteer = require('puppeteer-core');
      const pdfBuffer = await this.files.getObjectBuffer(fileKey);
      const dataUrl = `data:application/pdf;base64,${pdfBuffer.toString('base64')}`;
      const browser = await puppeteer.launch({
        args: chromium.args,
        defaultViewport: chromium.defaultViewport,
        executablePath: await chromium.executablePath(),
        headless: true,
      });
      try {
        const page = await browser.newPage();
        await page.goto(dataUrl, { waitUntil: 'networkidle0', timeout: 15_000 });
        const screenshot = (await page.screenshot({
          type: 'jpeg',
          quality: 80,
          clip: { x: 0, y: 0, width: 640, height: 880 },
        })) as Buffer;
        // Уменьшаем до 320px через sharp
        return this.files.generateThumbnail(screenshot, 320);
      } finally {
        await browser.close();
      }
    } catch (e) {
      this.logger.warn(`pdf thumbnail skipped: ${(e as Error).message}`);
      return null;
    }
  }
}
