import { OnWorkerEvent, Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import type { Job } from 'bullmq';
import { ExportKind } from '@prisma/client';
import { PrismaService } from '@app/common';
import { FilesService } from '@app/files';
import { QUEUE_EXPORTS } from '../queues/queues.module';
import { ExportService } from './export.service';
import { PdfRendererService } from './pdf-renderer.service';
import { ProjectReportPdfService, ReportViewer } from './project-report-pdf.service';
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
    private readonly reportPdf: ProjectReportPdfService,
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
        const buffer = await this.buildProjectZip(
          exportJob.id,
          exportJob.projectId,
          exportJob.requestedById,
        );
        const fileKey = `exports/${exportJob.projectId}/${exportJob.id}/project.zip`;
        await this.files.putObject(fileKey, buffer, 'application/zip');
        await this.exports.markDone(exportJob.id, fileKey, buffer.length);
      } else if (exportJob.kind === ExportKind.project_report_pdf) {
        const viewer = await this.buildReportViewer(exportJob.requestedById, exportJob.projectId);
        const buffer = await this.reportPdf.build(exportJob.projectId, viewer);
        const fileKey = `exports/${exportJob.projectId}/${exportJob.id}/project-report.pdf`;
        await this.files.putObject(fileKey, buffer, 'application/pdf');
        await this.exports.markDone(exportJob.id, fileKey, buffer.length);
      } else if (exportJob.kind === ExportKind.stage_report_pdf) {
        const filters = (exportJob.filtersPayload as { stageId?: string } | null) ?? {};
        const stageId = filters.stageId;
        if (!stageId) {
          throw new Error('stage_report_pdf requires filtersPayload.stageId');
        }
        const viewer = await this.buildReportViewer(exportJob.requestedById, exportJob.projectId);
        const buffer = await this.reportPdf.build(exportJob.projectId, viewer, stageId);
        const fileKey = `exports/${exportJob.projectId}/${exportJob.id}/stage-report.pdf`;
        await this.files.putObject(fileKey, buffer, 'application/pdf');
        await this.exports.markDone(exportJob.id, fileKey, buffer.length);
      } else if (exportJob.kind === ExportKind.project_summary_txt) {
        // Deprecated TXT-сводка — реализация удалена, но историческими записями
        // (created до 2026-05-12) обрабатываем через тот же ProjectReportPdfService,
        // чтобы старые re-enqueue работали и отдавали PDF.
        const viewer = await this.buildReportViewer(exportJob.requestedById, exportJob.projectId);
        const buffer = await this.reportPdf.build(exportJob.projectId, viewer);
        const fileKey = `exports/${exportJob.projectId}/${exportJob.id}/project-report.pdf`;
        await this.files.putObject(fileKey, buffer, 'application/pdf');
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

  private async buildProjectZip(
    jobId: string,
    projectId: string,
    requestedById: string,
  ): Promise<Buffer> {
    const entries: Array<{ name: string; buffer: Buffer }> = [];
    // 1. feed.pdf
    const feedPdf = await this.buildFeedPdf(jobId, projectId, {});
    entries.push({ name: 'feed.pdf', buffer: feedPdf });
    // 2. project-report.pdf — полный отчёт со всеми блоками (бюджеты, этапы,
    //    шаги с фото, материалы, инструменты, документы, лента событий).
    try {
      const viewer = await this.buildReportViewer(requestedById, projectId);
      const reportPdf = await this.reportPdf.build(projectId, viewer);
      entries.push({ name: 'project-report.pdf', buffer: reportPdf });
    } catch (e) {
      this.logger.warn(`project-report.pdf failed: ${(e as Error).message}`);
    }
    // 3. documents (не-PDF + PDF)
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
    // 4. step photos
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

  private async buildReportViewer(userId: string, projectId: string): Promise<ReportViewer> {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerId: true },
    });
    const membership = await this.prisma.membership.findFirst({
      where: { projectId, userId, removedAt: null },
      select: { role: true, permissions: true, stageIds: true },
    });
    const isOwner = project?.ownerId === userId;
    const role = membership?.role as ReportViewer['membershipRole'];
    const perms = (membership?.permissions ?? {}) as { canSeeBudget?: boolean };

    // §3.2: подрядчик видит только бюджет своих этапов и свои выплаты.
    // Общий бюджет проекта — только owner / rep.canSeeBudget.
    const canSeeProjectBudget = isOwner || (role === 'representative' && !!perms.canSeeBudget);
    const canSeeStageBudget = canSeeProjectBudget || role === 'foreman';
    const canSeeAllPayments = canSeeProjectBudget;

    const myForemanStages = await this.prisma.stage.findMany({
      where: { projectId, foremanIds: { has: userId } },
      select: { id: true },
    });
    const myMasterStages = await this.prisma.stage.findMany({
      where: { projectId, masterId: userId },
      select: { id: true },
    });
    const assignedStageIds = Array.from(
      new Set([...(membership?.stageIds ?? []), ...myMasterStages.map((s) => s.id)]),
    );
    const foremanStageIds = myForemanStages.map((s) => s.id);

    return {
      userId,
      isOwner,
      membershipRole: role,
      assignedStageIds,
      foremanStageIds,
      canSeeProjectBudget,
      canSeeStageBudget,
      canSeeAllPayments,
    };
  }

  @OnWorkerEvent('failed')
  onFailed(job: Job, err: Error): void {
    this.logger.error(`BullMQ job ${job.id} failed: ${err.message}`);
  }
}
