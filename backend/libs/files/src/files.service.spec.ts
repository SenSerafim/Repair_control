import { FilesService } from './files.service';
import { MinioConfig } from './minio.client';
import { InvalidInputError } from '@app/common';

const ALLOWED_MIMES = ['image/jpeg', 'image/png', 'application/pdf'];
const MAX_SIZE_MB = 10;

const buildService = () => {
  const config: MinioConfig = {
    endPoint: 'localhost',
    port: 9000,
    useSSL: false,
    accessKey: 'a',
    secretKey: 'b',
    bucket: 'test',
    presignTtlSeconds: 300,
  };
  const minio = {
    presignedPutObject: jest.fn().mockResolvedValue('https://presigned-put/example'),
    presignedGetObject: jest.fn().mockResolvedValue('https://presigned-get/example'),
    bucketExists: jest.fn().mockResolvedValue(true),
    makeBucket: jest.fn().mockResolvedValue(undefined),
  } as any;
  return { service: new FilesService(minio, config, ALLOWED_MIMES, MAX_SIZE_MB), minio, config };
};

describe('FilesService.validate', () => {
  it('отклоняет неподдерживаемый mime', () => {
    const { service } = buildService();
    expect(() =>
      service.validate({
        originalName: 'a.exe',
        mimeType: 'application/x-msdownload',
        sizeBytes: 1000,
        scope: 'avatars',
      }),
    ).toThrow(InvalidInputError);
  });

  it('отклоняет превышение размера', () => {
    const { service } = buildService();
    expect(() =>
      service.validate({
        originalName: 'a.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 100 * 1024 * 1024,
        scope: 'avatars',
      }),
    ).toThrow(InvalidInputError);
  });

  it('отклоняет нулевой или отрицательный размер', () => {
    const { service } = buildService();
    expect(() =>
      service.validate({
        originalName: 'a.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 0,
        scope: 'avatars',
      }),
    ).toThrow(InvalidInputError);
  });

  it('отклоняет пустой scope', () => {
    const { service } = buildService();
    expect(() =>
      service.validate({
        originalName: 'a.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 1000,
        scope: '',
      }),
    ).toThrow(InvalidInputError);
  });

  it('пропускает корректный запрос', () => {
    const { service } = buildService();
    expect(() =>
      service.validate({
        originalName: 'a.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 1024 * 1024,
        scope: 'stages/abc/photos',
      }),
    ).not.toThrow();
  });
});

describe('FilesService.buildKey', () => {
  it('содержит scope и расширение, отражающее mime', () => {
    const { service } = buildService();
    const key = service.buildKey({
      originalName: 'avatar.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 1000,
      scope: 'avatars',
    });
    expect(key).toMatch(/^avatars\/.+\.jpg$/);
  });

  it('санитизирует небезопасные символы scope', () => {
    const { service } = buildService();
    const key = service.buildKey({
      originalName: 'x.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 1000,
      scope: '../etc/passwd',
    });
    expect(key).not.toContain('..');
    expect(key).toMatch(/\.pdf$/);
  });
});

describe('FilesService.createPresignedUpload', () => {
  it('возвращает ключ, url и TTL', async () => {
    const { service, minio } = buildService();
    const res = await service.createPresignedUpload({
      originalName: 'a.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 1024,
      scope: 'docs',
    });
    expect(res.key).toMatch(/^docs\/.+\.pdf$/);
    expect(res.uploadUrl).toContain('presigned-put');
    expect(res.expiresAt.getTime()).toBeGreaterThan(Date.now());
    expect(minio.presignedPutObject).toHaveBeenCalledWith('test', expect.any(String), 300);
  });
});
