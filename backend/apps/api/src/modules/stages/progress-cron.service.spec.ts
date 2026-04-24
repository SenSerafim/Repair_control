import { ProgressCronService } from './progress-cron.service';
import { ProgressCalculator } from './progress-calculator';
import { PrismaService } from '@app/common';

describe('ProgressCronService', () => {
  const makePrisma = (active: { id: string }[]): PrismaService =>
    ({
      project: {
        findMany: jest.fn().mockResolvedValue(active),
      },
    }) as unknown as PrismaService;

  const makeCalc = (): jest.Mocked<ProgressCalculator> =>
    ({
      recalcProject: jest.fn().mockResolvedValue(undefined),
    }) as unknown as jest.Mocked<ProgressCalculator>;

  it('пересчитывает каждый активный проект', async () => {
    const active = [{ id: 'p1' }, { id: 'p2' }, { id: 'p3' }];
    const prisma = makePrisma(active);
    const calc = makeCalc();
    const svc = new ProgressCronService(prisma, calc);

    await svc.tick();

    expect(prisma.project.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { status: 'active' } }),
    );
    expect(calc.recalcProject).toHaveBeenCalledTimes(3);
    expect(calc.recalcProject).toHaveBeenCalledWith('p1');
    expect(calc.recalcProject).toHaveBeenCalledWith('p2');
    expect(calc.recalcProject).toHaveBeenCalledWith('p3');
  });

  it('не падает если один проект вылетел — продолжает остальные', async () => {
    const active = [{ id: 'p1' }, { id: 'p2' }];
    const prisma = makePrisma(active);
    const calc = makeCalc();
    (calc.recalcProject as jest.Mock).mockImplementationOnce(() => {
      throw new Error('boom on p1');
    });
    const svc = new ProgressCronService(prisma, calc);

    await expect(svc.tick()).resolves.toBeUndefined();
    expect(calc.recalcProject).toHaveBeenCalledWith('p2');
  });

  it('не падает если findMany сам вылетел', async () => {
    const prisma = {
      project: { findMany: jest.fn().mockRejectedValue(new Error('db down')) },
    } as unknown as PrismaService;
    const svc = new ProgressCronService(prisma, makeCalc());
    await expect(svc.tick()).resolves.toBeUndefined();
  });
});
