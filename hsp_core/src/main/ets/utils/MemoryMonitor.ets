// MemoryMonitor.ets
// 内存监控与泄漏检测工具 — 定期采样 + 阈值告警 + 趋势分析

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'MemoryMonitor';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class MemorySnapshot {
  timestamp: number = 0;
  totalJSHeapSize: number = 0;
  usedJSHeapSize: number = 0;
  jsHeapSizeLimit: number = 0;
  imageCacheSize: number = 0;
  gcCount: number = 0;
}

export class MemoryHealth {
  status: string = '';
  percentage: number = 0;
  warning: string = '';
}

export class MemoryMonitor {
  private static instance: MemoryMonitor;
  private snapshots: MemorySnapshot[] = [];
  private monitorTimer: number = -1;
  private warningThreshold: number = 100 * 1024 * 1024;
  private criticalThreshold: number = 150 * 1024 * 1024;
  private gcTriggerCount: number = 0;
  private isMonitoring: boolean = false;

  private constructor() {}

  static getInstance(): MemoryMonitor {
    if (!MemoryMonitor.instance) {
      MemoryMonitor.instance = new MemoryMonitor();
    }
    return MemoryMonitor.instance;
  }

  startMonitoring(intervalMs: number = 30000): void {
    if (this.isMonitoring) return;

    this.isMonitoring = true;
    this.snapshots = [];
    hilog.info(DOMAIN_ZERO, TAG, 'Memory monitoring started, interval=%{public}dms', intervalMs);

    this.monitorTimer = setInterval(() => {
      this.captureSnapshot();
    }, intervalMs);
  }

  stopMonitoring(): void {
    this.isMonitoring = false;
    if (this.monitorTimer !== -1) {
      clearInterval(this.monitorTimer);
      this.monitorTimer = -1;
    }
    hilog.info(DOMAIN_ZERO, TAG, 'Memory monitoring stopped. Total snapshots: %{public}d', this.snapshots.length);
  }

  captureSnapshot(): MemorySnapshot {
    const snapshot: MemorySnapshot = new MemorySnapshot()
    snapshot.timestamp = Date.now();
    snapshot.imageCacheSize = 0;
    snapshot.gcCount = this.gcTriggerCount;
    try {
      const perf = (Object.create(null) as Record<string, Object>)['performance'] as Record<string, Object> | undefined;
      if (perf) {
        const mem = perf['memory'] as Record<string, Object> | undefined;
        if (mem) {
          snapshot.totalJSHeapSize = (mem['totalJSHeapSize'] as number) ?? 0;
          snapshot.usedJSHeapSize = (mem['usedJSHeapSize'] as number) ?? 0;
          snapshot.jsHeapSizeLimit = (mem['jsHeapSizeLimit'] as number) ?? 0;
        }
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));}

    this.snapshots.push(snapshot);

    if (this.snapshots.length > 60) {
      this.snapshots.shift();
    }

    this.checkThresholds(snapshot);

    return snapshot;
  }

  getMemoryUsage(): number {
    if (this.snapshots.length === 0) return 0;
    return this.snapshots[this.snapshots.length - 1].usedJSHeapSize;
  }

  getMemoryTrend(): 'increasing' | 'stable' | 'decreasing' {
    if (this.snapshots.length < 3) return 'stable';

    const recent = this.snapshots.slice(-3);
    const first = recent[0].usedJSHeapSize;
    const last = recent[recent.length - 1].usedJSHeapSize;

    if (last > first * 1.1) return 'increasing';
    if (last < first * 0.9) return 'decreasing';
    return 'stable';
  }

  detectLeak(): boolean {
    if (this.snapshots.length < 10) return false;
    return this.getMemoryTrend() === 'increasing' && this.getMemoryUsage() > this.warningThreshold;
  }

  triggerGC(): void {
    this.gcTriggerCount++;
    try {
      const globalRecord: Object = globalThis as Object;
      const gcFn = (globalRecord as Record<string, Object>)['gc'];
      if (gcFn !== undefined && gcFn !== null) {
        (gcFn as Function)();
        hilog.info(DOMAIN_ZERO, TAG, 'Manual GC triggered (#%{public}d)', this.gcTriggerCount);
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      // gc不可用
    }
  }

  getLatestSnapshot(): MemorySnapshot | null {
    return this.snapshots.length > 0 ? this.snapshots[this.snapshots.length - 1] : null;
  }

  getMemoryHealth(): MemoryHealth {
    const usage = this.getMemoryUsage();
    const result: MemoryHealth = new MemoryHealth(
    if (usage >= this.criticalThreshold) {
      result.status = 'critical';
      result.percentage = Math.round(usage / this.criticalThreshold * 100);
      result.warning = '内存使用接近上限，建议释放不必要资源';
    } else if (usage >= this.warningThreshold) {
      result.status = 'warning';
      result.percentage = Math.round(usage / this.warningThreshold * 100);
      result.warning = '内存使用较高，注意监控趋势';
    } else {
      result.status = 'healthy';
      result.percentage = Math.round(usage / this.warningThreshold * 100);
      result.warning = '';
    }
    return result;
  }

  getFormattedMemoryUsage(): string {
    const usage = this.getMemoryUsage();
    if (usage > 1024 * 1024 * 1024) {
      return `${(usage / (1024 * 1024 * 1024)).toFixed(2)}GB`;
    }
    return `${(usage / (1024 * 1024)).toFixed(1)}MB`;
  }

  private checkThresholds(snapshot: MemorySnapshot): void {
    if (snapshot.usedJSHeapSize >= this.criticalThreshold) {
      hilog.error(DOMAIN_ZERO, TAG,
        'CRITICAL: Memory usage %{public}s (%{public}d%%)',
        this.getFormattedMemoryUsage(),
        Math.round(snapshot.usedJSHeapSize / this.criticalThreshold * 100));
      this.triggerGC();
    } else if (snapshot.usedJSHeapSize >= this.warningThreshold) {
      hilog.warn(DOMAIN_ZERO, TAG,
        'WARNING: Memory usage %{public}s (%{public}d%%)',
        this.getFormattedMemoryUsage(),
        Math.round(snapshot.usedJSHeapSize / this.warningThreshold * 100));
    }
  }
}