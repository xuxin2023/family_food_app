import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'LifecycleGuard';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

type DisposeAction = () => void;

export class LifecycleGuard {
  private disposables: DisposeAction[] = [];
  private timerIds: number[] = [];
  private intervalIds: number[] = [];
  private ownerId: string = '';

  constructor(ownerId: string = '') {
    this.ownerId = ownerId;
  }

  register(disposeAction: DisposeAction): void {
    this.disposables.push(disposeAction);
  }

  registerEventUnsubscribe(unsubscribeFn: DisposeAction): void {
    this.disposables.push(unsubscribeFn);
  }

  registerTimer(timerId: number): void {
    this.timerIds.push(timerId);
    this.disposables.push(() => clearTimeout(timerId));
  }

  registerInterval(intervalId: number): void {
    this.intervalIds.push(intervalId);
    this.disposables.push(() => clearInterval(intervalId));
  }

  disposeAll(): void {
    for (const dispose of this.disposables) {
      try {
        dispose();
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Dispose error in %{public}s: %{public}s',
          this.ownerId, JSON.stringify(e));
      }
    }
    this.disposables = [];
    this.timerIds = [];
    this.intervalIds = [];

    hilog.info(DOMAIN_ZERO, TAG, 'LifecycleGuard disposed all for %{public}s', this.ownerId);
  }

  getActiveCount(): number {
    return this.disposables.length;
  }

  getOwnerId(): string {
    return this.ownerId;
  }
}

export function createLifecycleGuard(ownerId: string): LifecycleGuard {
  return new LifecycleGuard(ownerId);
}
