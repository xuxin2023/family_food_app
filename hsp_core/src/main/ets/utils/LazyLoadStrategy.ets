// LazyLoadStrategy.ets
// 列表懒加载优化策略 — 按需加载 + 预加载 + 虚拟列表优化

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'LazyLoadStrategy';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface LazyLoadConfig {
  pageSize: number;
  preloadThreshold: number;
  maxCacheSize: number;
  debounceMs: number;
}

const DEFAULT_CONFIG: LazyLoadConfig = {
  pageSize: 20,
  preloadThreshold: 5,
  maxCacheSize: 200,
  debounceMs: 300
};

export class LazyLoadStrategy<T> {
  private config: LazyLoadConfig;
  private allData: T[] = [];
  private visibleStart: number = 0;
  private visibleEnd: number = 0;
  private loadCallback: (start: number, count: number) => Promise<T[]>;
  private lastLoadTime: number = 0;

  constructor(
    loadCallback: (start: number, count: number) => Promise<T[]>,
    config?: Partial<LazyLoadConfig>
  ) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.loadCallback = loadCallback;
  }

  async loadInitial(): Promise<T[]> {
    this.allData = await this.loadCallback(0, this.config.pageSize);
    this.visibleStart = 0;
    this.visibleEnd = Math.min(this.config.pageSize, this.allData.length);
    return this.getVisible();
  }

  getVisible(): T[] {
    const end = Math.min(this.visibleEnd, this.allData.length);
    return this.allData.slice(this.visibleStart, end);
  }

  async loadMore(): Promise<T[]> {
    const now = Date.now();
    if (now - this.lastLoadTime < this.config.debounceMs) {
      return [];
    }
    this.lastLoadTime = now;

    const start = this.allData.length;
    const newData = await this.loadCallback(start, this.config.pageSize);

    if (newData.length > 0) {
      this.allData.push(...newData);
      this.visibleEnd = this.allData.length;

      if (this.allData.length > this.config.maxCacheSize) {
        const removeCount = this.allData.length - this.config.maxCacheSize;
        this.allData.splice(0, removeCount);
        this.visibleStart = Math.max(0, this.visibleStart - removeCount);
        this.visibleEnd = this.allData.length;
      }
    }

    return newData;
  }

  onScroll(firstVisible: number, lastVisible: number): void {
    const totalVisible = lastVisible - firstVisible + 1;
    this.visibleStart = firstVisible;
    this.visibleEnd = lastVisible + 1;

    if (lastVisible >= this.allData.length - this.config.preloadThreshold &&
      this.allData.length < this.config.maxCacheSize) {
      this.loadMore();
    }
  }

  hasMore(): boolean {
    return this.allData.length < this.config.maxCacheSize &&
      this.allData.length > 0;
  }

  getTotalCount(): number {
    return this.allData.length;
  }

  reset(): void {
    this.allData = [];
    this.visibleStart = 0;
    this.visibleEnd = 0;
    this.lastLoadTime = 0;
  }

  static forList<T>(
    loadCallback: (start: number, count: number) => Promise<T[]>,
    pageSize?: number
  ): LazyLoadStrategy<T> {
    return new LazyLoadStrategy<T>(loadCallback, { pageSize: pageSize ?? 20 });
  }
}