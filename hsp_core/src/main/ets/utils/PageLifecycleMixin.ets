// PageLifecycleMixin.ets
// 全局页面生命周期资源追踪器 — 统一管理定时器/事件监听/订阅的释放
// 用于防止页面销毁后的内存泄漏和定时器残留

import { MemoryLeakGuard } from './MemoryLeakGuard';
import { PerformanceMonitor } from './PerformanceMonitor';
import { NullGuard } from './NullGuard';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'PageLifecycleMixin';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface TrackedDisposable {
  dispose(): void;
}

export interface TrackedListener {
  obj: Record<string, Object>;
  event: string;
  callback: Function;
}

export class PageResourceTracker {
  private timers: number[] = [];
  private intervals: number[] = [];
  private listeners: TrackedListener[] = [];
  private disposables: TrackedDisposable[] = [];
  private pageName: string = '';
  private leakGuard: MemoryLeakGuard;

  constructor(pageName: string) {
    this.pageName = pageName;
    this.leakGuard = MemoryLeakGuard.forPage(pageName);
  }

  registerTimeout(timerId: number): void {
    this.timers.push(timerId);
    this.leakGuard.registerTimeout(timerId);
  }

  registerInterval(intervalId: number): void {
    this.intervals.push(intervalId);
    this.leakGuard.registerInterval(intervalId);
  }

  registerListener(obj: Record<string, Object>, event: string, callback: Function): void {
    const listener: TrackedListener = { obj: obj, event: event, callback: callback };
    this.listeners.push(listener);
  }

  registerDisposable(disposable: TrackedDisposable): void {
    this.disposables.push(disposable);
    this.leakGuard.registerDisposable(disposable);
  }

  onAppear(): void {
    this.leakGuard.onAppear();
  }

  onDisappear(): void {
    for (let i = 0; i < this.timers.length; i++) {
      try {
        clearTimeout(this.timers[i]);
      } catch (_err) {
        hilog.warn(DOMAIN_ZERO, TAG, "Timer clear error: %{public}s", JSON.stringify(_err));
      }
    }
    for (let i = 0; i < this.intervals.length; i++) {
      try {
        clearInterval(this.intervals[i]);
      } catch (_err) {
        hilog.warn(DOMAIN_ZERO, TAG, "Interval clear error: %{public}s", JSON.stringify(_err));
      }
    }
    for (let i = 0; i < this.listeners.length; i++) {
      try {
        const l: TrackedListener = this.listeners[i];
        const objFn: Record<string, Function> = l.obj as Record<string, Function>;
        if (typeof objFn['off'] === 'function') {
          objFn['off'](l.event, l.callback);
        }
      } catch (_err) {
        hilog.warn(DOMAIN_ZERO, TAG, "Listener off error: %{public}s", JSON.stringify(_err));
      }
    }
    for (let i = 0; i < this.disposables.length; i++) {
      try {
        this.disposables[i].dispose();
      } catch (_err) {
        hilog.warn(DOMAIN_ZERO, TAG, "Dispose error: %{public}s", JSON.stringify(_err));
      }
    }

    this.timers.length = 0;
    this.intervals.length = 0;
    this.listeners.length = 0;
    this.disposables.length = 0;

    this.leakGuard.onDisappear();
  }

  onShakeCheck(): boolean {
    return this.leakGuard.onShakeCheck();
  }

  getPageName(): string {
    return this.pageName;
  }
}

export function createPageTracker(pageName: string): PageResourceTracker {
  return new PageResourceTracker(pageName);
}
