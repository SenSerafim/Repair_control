import { Injectable } from '@nestjs/common';

/**
 * Clock — injectable wrapper around "now" so tests can freeze time.
 */
export abstract class Clock {
  abstract now(): Date;
}

@Injectable()
export class SystemClock extends Clock {
  now(): Date {
    return new Date();
  }
}

export class FixedClock extends Clock {
  constructor(private current: Date) {
    super();
  }
  now(): Date {
    return this.current;
  }
  set(d: Date): void {
    this.current = d;
  }
  advanceMs(ms: number): void {
    this.current = new Date(this.current.getTime() + ms);
  }
}
