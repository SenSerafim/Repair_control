import { Injectable } from '@nestjs/common';
import { StageStatus } from '@prisma/client';
import { ErrorCodes, InvalidInputError } from '@app/common';

/**
 * FSM этапа (ТЗ §4.2). 6 явных состояний + overdue (computed).
 *
 *   pending ─start→ active ─pause→ paused ─resume→ active
 *                      │                           │
 *                      ├──send-to-review──────────►│ review ─accept→ done
 *                      │                           │        └─reject→ rejected
 *                      └──accept(hard-done)───────► done
 */
const TRANSITIONS: Record<StageStatus, Record<string, StageStatus>> = {
  pending: { start: 'active' },
  active: {
    pause: 'paused',
    send_to_review: 'review',
    complete: 'done',
  },
  paused: { resume: 'active' },
  review: { accept: 'done', reject: 'rejected' },
  rejected: { resume: 'active' },
  done: {},
};

export type StageTransition =
  | 'start'
  | 'pause'
  | 'resume'
  | 'send_to_review'
  | 'accept'
  | 'reject'
  | 'complete';

@Injectable()
export class StageLifecycle {
  nextStatus(current: StageStatus, action: StageTransition): StageStatus {
    const next = TRANSITIONS[current]?.[action];
    if (!next) {
      throw new InvalidInputError(
        ErrorCodes.STAGE_INVALID_TRANSITION,
        `cannot ${action} from ${current}`,
      );
    }
    return next;
  }
}
