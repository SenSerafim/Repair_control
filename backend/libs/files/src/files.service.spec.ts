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
    region: 'us-east-1',
    pathStyle: true,
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

describe('FilesService.validate с per-scope policy', () => {
  const buildWithPolicies = () => {
    const config: MinioConfig = {
      endPoint: 'localhost',
      port: 9000,
      useSSL: false,
      accessKey: 'a',
      secretKey: 'b',
      bucket: 'test',
      presignTtlSeconds: 300,
      region: 'us-east-1',
      pathStyle: true,
    };
    const minio = {} as any;
    return new FilesService(minio, config, ['image/jpeg'], 10, [
      {
        prefix: 'knowledge/',
        allowedMimes: ['image/jpeg', 'image/png', 'video/mp4'],
        maxSizeMb: 200,
      },
      { prefix: 'legal/', allowedMimes: ['application/pdf'], maxSizeMb: 25 },
    ]);
  };

  it('knowledge/* пропускает video/mp4 до 200 MB', () => {
    const service = buildWithPolicies();
    expect(() =>
      service.validate({
        originalName: 'lesson.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 150 * 1024 * 1024,
        scope: 'knowledge/articles/abc',
      }),
    ).not.toThrow();
  });

  it('knowledge/* отклоняет video > 200 MB', () => {
    const service = buildWithPolicies();
    expect(() =>
      service.validate({
        originalName: 'big.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 250 * 1024 * 1024,
        scope: 'knowledge/articles/abc',
      }),
    ).toThrow(InvalidInputError);
  });

  it('legal/* отклоняет всё кроме PDF', () => {
    const service = buildWithPolicies();
    expect(() =>
      service.validate({
        originalName: 'doc.docx',
        mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        sizeBytes: 1024,
        scope: 'legal/privacy',
      }),
    ).toThrow(InvalidInputError);
  });

  it('default scope не получает knowledge-привилегий (video отвергается)', () => {
    const service = buildWithPolicies();
    expect(() =>
      service.validate({
        originalName: 'x.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 1024,
        scope: 'avatars',
      }),
    ).toThrow(InvalidInputError);
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
