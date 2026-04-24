import { OnWorkerEvent, Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import type { Job } from 'bullmq';
import { ExportKind } from '@prisma/client';
import { PrismaService } from '@app/common';
import { FilesService } from '@app/files';
import { QUEUE_EXPORTS } from '../queues/queues.module';
import { ExportService } from './export.service';
import { PdfRendererService } from './pdf-renderer.service';
import { ZipPackerService } from './zip-packer.service';

@Processor(QUEUE_EXPORTS)
export class ExportProcessor extends WorkerHost {
  private readonly logger = new Logger(ExportProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly files: FilesService,
    private readonly exports: ExportService,
    private readonly pdf: PdfRendererService,
    private readonly zip: ZipPackerService,
  ) {
    super();
  }

  async process(job: Job<{ jobId: string }>): Promise<void> {
    const exportJob = await this.prisma.exportJob.findUnique({
      where: { id: job.data.jobId },
    });
    if (!exportJob) return;
    await this.exports.markRunning(exportJob.id);
    try {
      if (exportJob.kind === ExportKind.feed_pdf) {
        const buffer = await this.buildFeedPdf(
          exportJob.id,
          exportJob.projectId,
          (exportJob.filtersPayload as any) ?? {},
        );
        const fileKey = `exports/${exportJob.projectId}/${exportJob.id}/feed.pdf`;
        await this.files.putObject(fileKey, buffer, 'application/pdf');
        await this.exports.markDone(exportJob.id, fileKey, buffer.length);
      } else if (exportJob.kind === ExportKind.project_zip) {
        const buffer = await this.buildProjectZip(exportJob.id, exportJob.projectId);
        const fileKey = `exports/${exportJob.projectId}/${exportJob.id}/project.zip`;
        await this.files.putObject(fileKey, buffer, 'application/zip');
        await this.exports.markDone(exportJob.id, fileKey, buffer.length);
      }
    } catch (e) {
      const msg = (e as Error).message;
      this.logger.error(`export ${exportJob.id} failed: ${msg}`);
      await this.exports.markFailed(exportJob.id, msg);
      throw e;
    }
  }

  private async buildFeedPdf(
    _jobId: string,
    projectId: string,
    filters: Record<string, unknown>,
  ): Promise<Buffer> {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: {
        title: true,
        address: true,
        owner: { select: { firstName: true, lastName: true } },
      },
    });
    const events = await this.exports.listFeed(projectId, { ...filters, limit: 200 });
    return this.pdf.renderFeedPdf({
      projectTitle: project?.title ?? 'Проект',
      projectAddress: project?.address ?? null,
      ownerName: `${project?.owner.firstName ?? ''} ${project?.owner.lastName ?? ''}`.trim(),
      events: events.items.map((e) => ({
        createdAt: e.createdAt,
        kind: e.kind,
        actorId: e.actorId,
        payload: e.payload as Record<string, unknown>,
      })),
      pdfLogoUrl: process.env.PDF_LOGO_URL,
    });
  }

  private async buildProjectZip(jobId: string, projectId: string): Promise<Buffer> {
    const entries: Array<{ name: string; buffer: Buffer }> = [];
    // 1. feed.pdf
    const feedPdf = await this.buildFeedPdf(jobId, projectId, {});
    entries.push({ name: 'feed.pdf', buffer: feedPdf });
    // 2. documents (не-PDF + PDF)
    const docs = await this.prisma.document.findMany({
      where: { projectId, deletedAt: null },
    });
    for (const d of docs) {
      try {
        const buf = await this.files.getObjectBuffer(d.fileKey);
        const safeTitle = d.title.replace(/[\\/:*?"<>|]+/g, '_');
        entries.push({ name: `documents/${d.category}/${safeTitle}`, buffer: buf });
      } catch (e) {
        this.logger.warn(`skip missing doc ${d.id}: ${(e as Error).message}`);
      }
    }
    // 3. step photos
    const photos = await this.prisma.stepPhoto.findMany({
      where: { step: { stage: { projectId } } },
      include: { step: { select: { title: true, stage: { select: { title: true } } } } },
    });
    for (const p of photos) {
      try {
        const buf = await this.files.getObjectBuffer(p.fileKey);
        const stage = p.step.stage.title.replace(/[\\/:*?"<>|]+/g, '_');
        const step = p.step.title.replace(/[\\/:*?"<>|]+/g, '_');
        entries.push({ name: `photos/${stage}/${step}/${p.id}.jpg`, buffer: buf });
      } catch (e) {
        this.logger.warn(`skip missing photo ${p.id}: ${(e as Error).message}`);
      }
    }
    return this.zip.pack(entries);
  }

  @OnWorkerEvent('failed')
  onFailed(job: Job, err: Error): void {
    this.logger.error(`BullMQ job ${job.id} failed: ${err.message}`);
  }
}
