import { ProgressCalculator, StageSnapshot } from './progress-calculator';
import { FixedClock, PrismaService } from '@app/common';

const NOW = new Date('2026-06-01T12:00:00Z');

const stage = (overrides: Partial<StageSnapshot> = {}): StageSnapshot => ({
  id: 's1',
  status: 'active',
  plannedStart: new Date('2026-05-20T00:00:00Z'),
  plannedEnd: new Date('2026-06-20T00:00:00Z'),
  pauseDurationMs: BigInt(0),
  startedAt: new Date('2026-05-20T00:00:00Z'),
  ...overrides,
});

const calc = () => {
  const prisma = {} as PrismaService;
  return new ProgressCalculator(prisma, new FixedClock(NOW));
};

describe('ProgressCalculator — 5 веток светофора (ТЗ §2.4)', () => {
  it('green: штатная работа, дедлайн далеко', () => {
    const c = calc();
    const r = c.stageSemaphore(stage({ status: 'active' }));
    expect(r.color).toBe('green');
  });

  it('yellow: ≤3 дня до дедлайна', () => {
    const c = calc();
    const r = c.stageSemaphore(
      stage({ status: 'active', plannedEnd: new Date('2026-06-03T12:00:00Z') }),
    );
    expect(r.color).toBe('yellow');
    expect(r.reasons).toContain('close_to_deadline');
  });

  it('red: дедлайн просрочен', () => {
    const c = calc();
    const r = c.stageSemaphore(
      stage({ status: 'active', plannedEnd: new Date('2026-05-01T00:00:00Z') }),
    );
    expect(r.color).toBe('red');
    expect(r.reasons).toContain('overdue');
  });

  it('red: дата старта прошла, но Старт не нажат (late_start)', () => {
    const c = calc();
    const r = c.stageSemaphore(
      stage({
        status: 'pending',
        plannedStart: new Date('2026-05-01T00:00:00Z'),
        plannedEnd: new Date('2026-06-20T00:00:00Z'),
        startedAt: null,
      }),
    );
    expect(r.color).toBe('red');
    expect(r.reasons).toContain('late_start');
  });

  it('blue: ожидает приёмки (review)', () => {
    const c = calc();
    const r = c.stageSemaphore(stage({ status: 'review' }));
    expect(r.color).toBe('blue');
  });

  it('blue: отклонён (rejected) — требует действий бригадира', () => {
    const c = calc();
    const r = c.stageSemaphore(stage({ status: 'rejected' }));
    expect(r.color).toBe('blue');
  });

  it('yellow: на паузе, но до дедлайна ещё больше 3 дней', () => {
    const c = calc();
    const r = c.stageSemaphore(stage({ status: 'paused' }));
    expect(r.color).toBe('yellow');
  });

  it('done: завершён', () => {
    const c = calc();
    const r = c.stageSemaphore(stage({ status: 'done' }));
    expect(r.color).toBe('done');
  });

  it('дедлайн расширяется за счёт pauseDurationMs', () => {
    const c = calc();
    // Плановый конец уже в прошлом, но накоплены паузы, сдвигающие его в будущее.
    const past = new Date('2026-05-25T00:00:00Z');
    const pauseMs = 10 * 24 * 60 * 60 * 1000; // 10 дней
    const r = c.stageSemaphore(
      stage({ status: 'active', plannedEnd: past, pauseDurationMs: BigInt(pauseMs) }),
    );
    // pastEnd + 10 дней = 2026-06-04; now = 2026-06-01; до дедлайна 3 дня → yellow
    expect(r.color).toBe('yellow');
  });
});

describe('project-level semaphore', () => {
  it('пустой проект — green', () => {
    const c = calc();
    expect(c.computeProjectSemaphore([])).toBe('green');
  });
  it('все этапы done → done', () => {
    const c = calc();
    const stages = [
      { ...stage(), status: 'done' },
      { ...stage(), status: 'done' },
    ] as any;
    expect(c.computeProjectSemaphore(stages)).toBe('done');
  });
  it('есть red → red', () => {
    const c = calc();
    const stages = [
      { ...stage(), status: 'active' },
      { ...stage(), status: 'active', plannedEnd: new Date('2026-01-01T00:00:00Z') },
    ] as any;
    expect(c.computeProjectSemaphore(stages)).toBe('red');
  });
  it('есть blue и нет red → blue', () => {
    const c = calc();
    const stages = [
      { ...stage(), status: 'active' },
      { ...stage(), status: 'review' },
    ] as any;
    expect(c.computeProjectSemaphore(stages)).toBe('blue');
  });
  it('есть yellow и нет red/blue → yellow', () => {
    const c = calc();
    const stages = [
      { ...stage(), status: 'active' },
      { ...stage(), status: 'paused' },
    ] as any;
    expect(c.computeProjectSemaphore(stages)).toBe('yellow');
  });
});

describe('project progress', () => {
  it('0% при пустом списке', () => {
    expect(calc().computeProjectProgress([])).toBe(0);
  });
  it('25% когда 1 из 4 done', () => {
    const c = calc();
    const stages = [
      { ...stage(), status: 'done' },
      { ...stage(), status: 'active' },
      { ...stage(), status: 'paused' },
      { ...stage(), status: 'pending' },
    ] as any;
    expect(c.computeProjectProgress(stages)).toBe(25);
  });
  it('100% когда все done', () => {
    const c = calc();
    const stages = [
      { ...stage(), status: 'done' },
      { ...stage(), status: 'done' },
    ] as any;
    expect(c.computeProjectProgress(stages)).toBe(100);
  });
});
