import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { Clock, PrismaService } from '@app/common';
import { FilesService } from '@app/files';

/**
 * Soft-удаляет «orphan» документы — те, у которых `thumbStatus='pending'`,
 * прошло > 1 часа, а файл в S3 так и не появился.
 *
 * Сценарий: мобильный клиент успешно вызвал `presign-upload` (запись в DB
 * создалась), а PUT в S3 не дошёл (потеря сети, force-kill приложения,
 * cancel пользователя). Без cleanup в списках накапливаются документы
 * без файла, на которые `confirm` не вызвать — `attachUrls` отдаст
 * `null`-ссылку и в UI это сломанный документ.
 *
 * Почему не удалять физически: храним мягко (`deletedAt`), чтобы фид
 * не потерял ссылку (event `document_uploaded` остаётся), и чтобы admin
 * мог посмотреть удалённые при разборе инцидента.
 */
@Injectable()
export class DocumentsCleanupCron {
  private readonly logger = new Logger(DocumentsCleanupCron.name);

  /** Сколько ждать до признания документа orphan-ом. */
  private static readonly ORPHAN_THRESHOLD_MS = 60 * 60 * 1000;

  /** Сколько записей обрабатывать за тик (защита от лавинного S3-stat). */
  private static readonly BATCH = 200;

  constructor(
    private readonly prisma: PrismaService,
    private readonly files: FilesService,
    private readonly clock: Clock,
  ) {}

  @Cron(CronExpression.EVERY_HOUR)
  async tick(): Promise<void> {
    await this.runOnce();
  }

  /**
   * Публично — чтобы можно было дёрнуть из теста и admin-эндпоинта
   * без ожидания cron-тика.
   */
  async runOnce(): Promise<{ scanned: number; orphaned: number }> {
    const cutoff = new Date(this.clock.now().getTime() - DocumentsCleanupCron.ORPHAN_THRESHOLD_MS);
    const candidates = await this.prisma.document.findMany({
      where: {
        thumbStatus: 'pending',
        deletedAt: null,
        createdAt: { lt: cutoff },
      },
      select: { id: true, fileKey: true },
      take: DocumentsCleanupCron.BATCH,
    });
    if (candidates.length === 0) {
      return { scanned: 0, orphaned: 0 };
    }
    let orphaned = 0;
    for (const doc of candidates) {
      let exists = true;
      try {
        await this.files.statObject(doc.fileKey);
      } catch {
        exists = false;
      }
      if (!exists) {
        await this.prisma.document.update({
          where: { id: doc.id },
          data: { deletedAt: this.clock.now() },
        });
        orphaned++;
      }
    }
    if (orphaned > 0) {
      this.logger.log(
        `cleanup: ${orphaned} orphan documents soft-deleted ` + `(scanned ${candidates.length})`,
      );
    }
    return { scanned: candidates.length, orphaned };
  }
}
