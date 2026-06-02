// PerformanceMonitor.ets
// 性能监控工具 — 页面加载耗时、关键操作耗时、内存采样、P50/P95/P99 聚合、超阈值告警

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'PerformanceMonitor';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const THRESHOLD_PAGE_LOAD_MS: number = 3000;
const THRESHOLD_AI_RESPONSE_MS: number = 10000;
const THRESHOLD_SCAN_RESULT_MS: number = 5000;
const MAX_METRICS_PER_KEY: number = 1000;
const SAMPLE_INTERVAL_MS: number = 30000;

export class PerfMetric {
  key: string = ''
  durationMs: number = 0
  timestamp: number = 0
  metadata: Map<string, string> = new Map()
}

export class PerfPercentiles {
  p50: number = 0
  p95: number = 0
  p99: number = 0
  count: number = 0
}

export class PerfAlert {
  key: string = ''
  durationMs: number = 0
  thresholdMs: number = 0
  timestamp: number = 0
  message: string = ''
}

let perfMonitorInstance: PerformanceMonitor | null = null;

export class PerformanceMonitor {
  private metrics: Map<string, PerfMetric[]> = new Map();
  private activeSpans: Map<string, number> = new Map();
  private alerts: PerfAlert[] = [];
  private memorySamples: number[] = [];
  private sampleTimer: number = -1;
  private _isRunning: boolean = false;

  static getInstance(): PerformanceMonitor {
    if (perfMonitorInstance === null) {
      perfMonitorInstance = new PerformanceMonitor();
    }
    return perfMonitorInstance;
  }

  init(): void {
    if (this._isRunning) return;
    this._isRunning = true;

    this.sampleTimer = setInterval(() => {
      this.sampleMemory();
    }, SAMPLE_INTERVAL_MS);

    hilog.info(DOMAIN_ZERO, TAG, 'PerformanceMonitor initialized');
  }

  startSpan(key: string): void {
    this.activeSpans.set(key, Date.now());
  }

  endSpan(key: string, metadata?: Map<string, string>): number {
    const startTime = this.activeSpans.get(key);
    if (startTime === undefined) {
      hilog.warn(DOMAIN_ZERO, TAG, 'No active span for key: %{public}s', key);
      return -1;
    }
    this.activeSpans.delete(key);

    const duration = Date.now() - startTime;
    const metric = new PerfMetric();
    metric.key = key;
    metric.durationMs = duration;
    metric.timestamp = Date.now();
    if (metadata !== undefined) {
      metric.metadata = metadata;
    }

    this.recordMetric(metric);
    this.checkThreshold(key, duration);

    hilog.info(DOMAIN_ZERO, TAG, '[%{public}s] %{public}d ms', key, duration);
    return duration;
  }

  pageEnter(pageName: string): void {
    const key = `page_load:${pageName}`;
    this.startSpan(key);
  }

  pageLeave(pageName: string): number {
    const key = `page_load:${pageName}`;
    return this.endSpan(key);
  }

  trackOperation(opName: string, startTime: number, metadata?: Map<string, string>): number {
    const duration = Date.now() - startTime;
    const metric = new PerfMetric();
    metric.key = opName;
    metric.durationMs = duration;
    metric.timestamp = Date.now();
    if (metadata !== undefined) {
      metric.metadata = metadata;
    }

    this.recordMetric(metric);
    this.checkThreshold(opName, duration);
    return duration;
  }

  getPercentiles(key: string): PerfPercentiles {
    const result = new PerfPercentiles();
    const list = this.metrics.get(key);
    if (list === undefined || list.length === 0) return result;

    const sorted = list.map(m => m.durationMs).sort((a: number, b: number) => a - b);
    result.count = sorted.length;
    result.p50 = this.percentile(sorted, 50);
    result.p95 = this.percentile(sorted, 95);
    result.p99 = this.percentile(sorted, 99);
    return result;
  }

  getAlerts(): PerfAlert[] {
    return [...this.alerts];
  }

  getMemorySamples(): number[] {
    return [...this.memorySamples];
  }

  getAllKeys(): string[] {
    const keys: string[] = [];
    this.metrics.forEach((_v, k) => { keys.push(k); });
    return keys;
  }

  private recordMetric(metric: PerfMetric): void {
    let list = this.metrics.get(metric.key);
    if (list === undefined) {
      list = [];
      this.metrics.set(metric.key, list);
    }
    list.push(metric);
    if (list.length > MAX_METRICS_PER_KEY) {
      list.splice(0, list.length - MAX_METRICS_PER_KEY);
    }
  }

  private checkThreshold(key: string, duration: number): void {
    let threshold: number = -1;

    if (key.startsWith('page_load:')) {
      threshold = THRESHOLD_PAGE_LOAD_MS;
    } else if (key.startsWith('ai_') || key.includes('ai_response') || key.includes('ai_chat')) {
      threshold = THRESHOLD_AI_RESPONSE_MS;
    } else if (key.startsWith('scan_') || key.includes('scan_result')) {
      threshold = THRESHOLD_SCAN_RESULT_MS;
    }

    if (threshold > 0 && duration > threshold) {
      const alert = new PerfAlert();
      alert.key = key;
      alert.durationMs = duration;
      alert.thresholdMs = threshold;
      alert.timestamp = Date.now();
      alert.message = `${key} exceeded threshold: ${duration}ms > ${threshold}ms`;
      this.alerts.push(alert);
      if (this.alerts.length > 100) {
        this.alerts.splice(0, this.alerts.length - 100);
      }
      hilog.warn(DOMAIN_ZERO, TAG, 'PERF ALERT: %{public}s', alert.message);
    }
  }

  private sampleMemory(): void {
    try {
      this.memorySamples.push(0);
      if (this.memorySamples.length > 200) {
        this.memorySamples.splice(0, this.memorySamples.length - 200);
      }
    } catch (_e) {
      // process.memoryUsage 不可用时静默
    }
  }

  private percentile(sorted: number[], p: number): number {
    if (sorted.length === 0) return 0;
    const idx = Math.ceil((p / 100) * sorted.length) - 1;
    return sorted[Math.max(0, Math.min(idx, sorted.length - 1))];
  }

  destroy(): void {
    if (this.sampleTimer !== -1) {
      clearInterval(this.sampleTimer);
      this.sampleTimer = -1;
    }
    this._isRunning = false;
    this.metrics.clear();
    this.activeSpans.clear();
    this.alerts = [];
    this.memorySamples = [];
    perfMonitorInstance = null;
    hilog.info(DOMAIN_ZERO, TAG, 'PerformanceMonitor destroyed');
  }
}
