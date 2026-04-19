import { StageLifecycle } from './stage-lifecycle';
import { InvalidInputError } from '@app/common';

describe('StageLifecycle — FSM этапа (ТЗ §4.2)', () => {
  const fsm = new StageLifecycle();

  it('pending → active on start', () => {
    expect(fsm.nextStatus('pending', 'start')).toBe('active');
  });

  it('active → paused on pause', () => {
    expect(fsm.nextStatus('active', 'pause')).toBe('paused');
  });

  it('paused → active on resume', () => {
    expect(fsm.nextStatus('paused', 'resume')).toBe('active');
  });

  it('active → review on send_to_review', () => {
    expect(fsm.nextStatus('active', 'send_to_review')).toBe('review');
  });

  it('review → done on accept', () => {
    expect(fsm.nextStatus('review', 'accept')).toBe('done');
  });

  it('review → rejected on reject', () => {
    expect(fsm.nextStatus('review', 'reject')).toBe('rejected');
  });

  it('rejected → active on resume (бригадир исправляет)', () => {
    expect(fsm.nextStatus('rejected', 'resume')).toBe('active');
  });

  describe('invalid transitions throw', () => {
    it('pending → pause (не стартовал)', () => {
      expect(() => fsm.nextStatus('pending', 'pause')).toThrow(InvalidInputError);
    });
    it('active → start (уже активен)', () => {
      expect(() => fsm.nextStatus('active', 'start')).toThrow(InvalidInputError);
    });
    it('done → start (завершён)', () => {
      expect(() => fsm.nextStatus('done', 'start')).toThrow(InvalidInputError);
    });
    it('paused → send_to_review (нужно резюмировать сначала)', () => {
      expect(() => fsm.nextStatus('paused', 'send_to_review')).toThrow(InvalidInputError);
    });
    it('review → pause (в согласовании — нельзя паузить)', () => {
      expect(() => fsm.nextStatus('review', 'pause')).toThrow(InvalidInputError);
    });
  });
});
