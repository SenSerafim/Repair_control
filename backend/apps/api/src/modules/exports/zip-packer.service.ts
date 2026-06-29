import { Injectable } from '@nestjs/common';
import archiver from 'archiver';

@Injectable()
export class ZipPackerService {
  /**
   * Пакует набор файлов в ZIP-архив (в памяти). Возвращает Buffer.
   * Для больших архивов в будущем — streaming напрямую в S3 putObject.
   *
   * Важно: слушатели 'data'/'end'/'error' навешиваются ДО append/finalize,
   * иначе при синхронном завершении мы упускаем событие 'end' и await
   * висит вечно (наблюдалось на проде — ZIP-jobs зависали в running).
   */
  async pack(entries: Array<{ name: string; buffer: Buffer }>): Promise<Buffer> {
    const archive = archiver('zip', { zlib: { level: 9 } });
    const chunks: Buffer[] = [];

    const finished = new Promise<Buffer>((resolve, reject) => {
      archive.on('data', (c: Buffer) => chunks.push(c));
      archive.on('end', () => resolve(Buffer.concat(chunks)));
      archive.on('error', reject);
      archive.on('warning', (err) => {
        // ENOENT-предупреждения (отсутствующий файл при append-from-fs)
        // здесь не возникают — мы append'им Buffer'ы. Любое другое
        // предупреждение трактуем как ошибку, чтобы не получить тихо
        // битый архив.
        reject(err);
      });
    });

    for (const entry of entries) {
      archive.append(entry.buffer, { name: entry.name });
    }
    await archive.finalize();
    return finished;
  }
}
