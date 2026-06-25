import { LifecycleGuard, createLifecycleGuard } from './LifecycleGuard';
import { MemoryMonitor } from './MemoryMonitor';
import { PerformanceMonitor } from './PerformanceMonitor';
import { NullGuard } from './NullGuard';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'MemoryLeakGuard';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class MemoryLeakGuard {
  private lifecycle: LifecycleGuard = createLifecycleGuard('');
  private pageName: string = '';

  private constructor(pageName: string) {
    this.pageName = pageName;
  }

  static forPage(pageName: string): MemoryLeakGuard {
    return new MemoryLeakGuard(pageName);
  }

  registerTimeout(timerId: number): MemoryLeakGuard {
    this.lifecycle.registerTimer(timerId);
    return this;
  }

  registerInterval(intervalId: number): MemoryLeakGuard {
    this.lifecycle.registerInterval(intervalId);
    return this;
  }

  registerDisposable(disposable: Object | null): MemoryLeakGuard {
    if (disposable !== null) {
      this.lifecycle.register(() => {
        const d: Record<string, Function> = disposable as Record<string, Function>;
        if (typeof d['dispose'] === 'function') {
          d['dispose']();
        }
      });
    }
    return this;
  }

  onAppear(): void {
    PerformanceMonitor.getInstance().pageEnter(this.pageName);
    MemoryMonitor.getInstance().captureSnapshot();
    hilog.info(DOMAIN_ZERO, TAG, 'Page appeared: %{public}s', this.pageName);
  }

  onDisappear(): void {
    this.lifecycle.disposeAll();
    PerformanceMonitor.getInstance().pageLeave(this.pageName);
    const usage = MemoryMonitor.getInstance().getFormattedMemoryUsage();
    hilog.info(DOMAIN_ZERO, TAG, 'Page disposed: %{public}s, memory=%{public}s', this.pageName, usage);

    const trend = MemoryMonitor.getInstance().getMemoryTrend();
    if (trend === 'increasing') {
      hilog.warn(DOMAIN_ZERO, TAG, 'Memory trend increasing after %{public}s disposed', this.pageName);
      MemoryMonitor.getInstance().triggerGC();
    }
  }

  onShakeCheck(): boolean {
    const leak = MemoryMonitor.getInstance().detectLeak();
    if (leak) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Potential leak detected for %{public}s', this.pageName);
    }
    return leak;
  }
}

export function createMemoryLeakGuard(pageName: string): MemoryLeakGuard {
  return MemoryLeakGuard.forPage(pageName);
}