// FoodDomainService.ets
// 食品领域服务 - 从 AppState 剥离的食品标签/扫码相关业务逻辑

import { FoodLabel, FoodLabelJson } from '../model/FoodLabel';
import { FoodRepository } from '../repository/FoodRepository';
import { CacheManager } from '../utils/CacheManager';
import { ScanHistoryRecord } from '../repository/HistoryRepository';
import { RepositoryManager } from '../manager/RepositoryManager';

export class FoodDomainService {
  private repos: RepositoryManager;
  private cacheMgr: CacheManager;

  constructor(repos: RepositoryManager, cache: CacheManager) {
    this.repos = repos;
    this.cacheMgr = cache;
  }

  async saveFoodLabel(label: FoodLabel): Promise<void> {
    await this.repos.saveFoodLabel(label);
  }

  async findFoodByBarcode(barcode: string): Promise<FoodLabel | null> {
    return this.repos.findFoodByBarcode(barcode);
  }

  async findFoodById(foodId: string): Promise<FoodLabel | null> {
    return this.repos.findFoodById(foodId);
  }

  async findFoodByIds(foodIds: string[]): Promise<Map<string, FoodLabel>> {
    return this.repos.findFoodByIds(foodIds);
  }

  async getRecentScanHistory(limit?: number): Promise<ScanHistoryRecord[]> {
    return this.repos.getRecentScanHistory(limit || 20);
  }
}
