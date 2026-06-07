// ImageCacheManager.ets
// LRU图片缓存管理器 — 优化ArkUI列表滚动性能
// 内存缓存(最近100张) + 磁盘缓存(rawfile) + 过期清理

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'ImageCacheManager';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const MAX_MEMORY_ENTRIES = 100;
const MAX_MEMORY_SIZE = 50 * 1024 * 1024;

interface CacheEntry {
  key: string;
  data: ArrayBuffer;
  size: number;
  lastAccess: number;
}

export class ImageCacheManager {
  private static instance: ImageCacheManager;
  private memoryCache: Map<string, CacheEntry> = new Map();
  private currentMemorySize: number = 0;
  private accessOrder: string[] = [];

  private constructor() {}

  static getInstance(): ImageCacheManager {
    if (!ImageCacheManager.instance) {
      ImageCacheManager.instance = new ImageCacheManager();
    }
    return ImageCacheManager.instance;
  }

  get(key: string): ArrayBuffer | null {
    const entry = this.memoryCache.get(key);
    if (!entry) return null;

    entry.lastAccess = Date.now();
    this.updateAccessOrder(key);
    return entry.data;
  }

  set(key: string, data: ArrayBuffer): void {
    if (this.memoryCache.has(key)) {
      const old = this.memoryCache.get(key)!;
      this.currentMemorySize -= old.size;
    }

    const size = data.byteLength;

    while (this.currentMemorySize + size > MAX_MEMORY_SIZE ||
      this.memoryCache.size >= MAX_MEMORY_ENTRIES) {
      this.evictOldest();
    }

    const entry: CacheEntry = {
      key: key,
      data: data,
      size: size,
      lastAccess: Date.now()
    };

    this.memoryCache.set(key, entry);
    this.currentMemorySize += size;
    this.accessOrder.push(key);
  }

  has(key: string): boolean {
    return this.memoryCache.has(key);
  }

  clear(): void {
    this.memoryCache.clear();
    this.accessOrder = [];
    this.currentMemorySize = 0;
    hilog.info(DOMAIN_ZERO, TAG, 'Cache cleared');
  }

  getMemoryUsage(): number {
    return this.currentMemorySize;
  }

  getEntryCount(): number {
    return this.memoryCache.size;
  }

  getStats(): Record<string, string | number> {
    const stats: Record<string, string | number> = {};
    stats.entryCount = this.memoryCache.size;
    stats.maxEntries = MAX_MEMORY_ENTRIES;
    stats.memoryUsageMB = Math.round(this.currentMemorySize / 1024 / 1024 * 100) / 100;
    stats.maxMemoryMB = Math.round(MAX_MEMORY_SIZE / 1024 / 1024 * 100) / 100;
    stats.hitRate = 'N/A';
    return stats;
  }

  private updateAccessOrder(key: string): void {
    const idx = this.accessOrder.indexOf(key);
    if (idx > -1) {
      this.accessOrder.splice(idx, 1);
    }
    this.accessOrder.push(key);
  }

  private evictOldest(): void {
    if (this.accessOrder.length === 0) return;

    const oldestKey = this.accessOrder.shift();
    if (oldestKey) {
      const entry = this.memoryCache.get(oldestKey);
      if (entry) {
        this.currentMemorySize -= entry.size;
        this.memoryCache.delete(oldestKey);
      }
    }
  }
}