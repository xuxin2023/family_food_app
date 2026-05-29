// 预加载服务 - 进入首页时预缓存高频商品库和画像数据

import { FoodLabel, FamilyProfile, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';

const TAG = 'PreloadService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class PreloadCache {
  scanHistory: FoodLabel[] = [];
  members: FamilyProfile[] = [];
  cachedAt: number = 0;
}

let preloadServiceInstance: PreloadService | null = null;

export class PreloadService {
  private appState: AppState = AppState.getInstance();
  private cache: PreloadCache | null = null;

  static getInstance(): PreloadService {
    if (preloadServiceInstance === null) {
      preloadServiceInstance = new PreloadService();
    }
    return preloadServiceInstance;
  }

  /**
   * 预加载数据（首页进入时调用）
   */
  async preload(): Promise<void> {
    const now = Date.now();
    // 缓存有效期5分钟
    if (this.cache !== null && (now - this.cache.cachedAt) < 300000) {
      return;
    }

    try {
      const scanHistoryRecords = await this.appState.getRecentScanHistory(20);
      const members = await this.appState.getAllMembers();

      const labels: FoodLabel[] = [];
      for (const record of scanHistoryRecords) {
        const food = await this.appState.findFoodById(record.foodId);
        if (food !== null) {
          labels.push(food);
        }
      }

      const cache = new PreloadCache();
      cache.scanHistory = labels;
      cache.members = members;
      cache.cachedAt = Date.now();
      this.cache = cache;

      hilog.info(DOMAIN_ZERO, TAG,
        'Preload complete: %{public}d foods, %{public}d members',
        labels.length, members.length);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG,
        'Preload failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 获取缓存的扫描历史
   */
  getCachedHistory(): FoodLabel[] {
    return this.cache?.scanHistory ?? [];
  }

  /**
   * 获取缓存的成员列表
   */
  getCachedMembers(): FamilyProfile[] {
    return this.cache?.members ?? [];
  }

  /**
   * 缓存是否有效
   */
  hasValidCache(): boolean {
    if (this.cache === null) return false;
    return (Date.now() - this.cache.cachedAt) < 300000;
  }

  /**
   * 清除缓存（强制重新加载）
   */
  clear(): void {
    this.cache = null;
    hilog.info(DOMAIN_ZERO, TAG, 'Cache cleared');
  }
}