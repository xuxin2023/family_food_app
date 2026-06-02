// PageLifecycleMixin.ets
// 全局页面生命周期资源追踪器 — 统一管理定时器/事件监听/订阅的释放
// 用于防止页面销毁后的内存泄漏和定时器残留

import { MemoryLeakGuard } from './MemoryLeakGuard';
import { PerformanceMonitor } from './PerformanceMonitor';
import { NullGuard } from './NullGuard';

export interface TrackedDisposable {
  dispose(): void;
}

export class PageResourceTracker {
  private timers: number[] = [];
  private intervals: number[] = [];
  private listeners: Array<{ obj: object; event: string; callback: Function }> = [];
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

  registerListener(obj: object, event: string, callback: Function): void {
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
      try { clearTimeout(id); } catch (_) { /* ignore */ }
    });
    this.intervals.forEach((id: number) => {
      try { clearInterval(id); } catch (_) { /* ignore */ }
    });
    this.listeners.forEach((l: { obj: object; event: string; callback: Function }) => {
      try {
        const obj = l.obj as Record<string, Function>;
        if (typeof obj['off'] === 'function') {
          obj['off'](l.event, l.callback);
        }
      } catch (_) { /* ignore */ }
    });
    this.disposables.forEach((d: TrackedDisposable) => {
      try { d.dispose(); } catch (_) { /* ignore */ }
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