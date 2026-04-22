import { Injectable } from '@nestjs/common';
import archiver from 'archiver';
import { PassThrough } from 'stream';

@Injectable()
export class ZipPackerService {
  /**
   * Пакует набор файлов в ZIP-архив (в памяти). Возвращает Buffer.
   * Для больших архивов в будущем — streaming напрямую в MinIO putObject.
   */
  async pack(entries: Array<{ name: string; buffer: Buffer }>): Promise<Buffer> {
    const archive = archiver('zip', { zlib: { level: 9 } });
    const chunks: Buffer[] = [];
    const passthrough = new PassThrough();
    passthrough.on('data', (c: Buffer) => chunks.push(c));

    archive.pipe(passthrough);
    for (const entry of entries) {
      archive.append(entry.buffer, { name: entry.name });
    }
    await archive.finalize();

    await new Promise<void>((resolve) => passthrough.on('end', () => resolve()));
    return Buffer.concat(chunks);
  }
}
