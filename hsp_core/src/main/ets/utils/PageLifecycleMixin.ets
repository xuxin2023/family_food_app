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

export class PageResourceTracker {
  private timers: number[] = [];
  private intervals: number[] = [];
  private listeners: Array<{ obj: Record<string, Object>; event: string; callback: Function }> = [];
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
    this.listeners.push({ obj, event, callback });
  }

  registerDisposable(disposable: TrackedDisposable): void {
    this.disposables.push(disposable);
    this.leakGuard.registerDisposable(disposable);
  }

  onAppear(): void {
    this.leakGuard.onAppear();
  }

  onDisappear(): void {
    this.timers.forEach((id: number) => {
      try { clearTimeout(id); } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_)); /* ignore */ }
    });
    this.intervals.forEach((id: number) => {
      try { clearInterval(id); } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_)); /* ignore */ }
    });
    this.listeners.forEach((l: { obj: Record<string, Object>; event: string; callback: Function }) => {
      try {
        const obj = l.obj as Record<string, Function>;
        if (typeof obj.off === 'function') {
          obj.off(l.event, l.callback);
        }
      } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_)); /* ignore */ }
    });
    this.disposables.forEach((d: TrackedDisposable) => {
      try { d.dispose(); } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_)); /* ignore */ }
    });

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