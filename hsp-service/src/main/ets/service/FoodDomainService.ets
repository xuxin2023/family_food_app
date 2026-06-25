// FoodDomainService.ets
// 食品数据领域服务 - 封装食品标签相关的业务逻辑
// 用途：从 AppState 中提取食品数据管理职责

import { FoodLabel } from 'hsp_core';
import { FoodRepository } from '../repository/FoodRepository';

const TAG = 'FoodDomainService';

export class FoodDomainService {
  private foodRepo: FoodRepository;

  constructor(foodRepo: FoodRepository) {
    this.foodRepo = foodRepo;
  }

  /** 根据条形码查找食品 */
  async findByBarcode(barcode: string): Promise<FoodLabel | null> {
    return await this.foodRepo.findByBarcode(barcode);
  }

  /** 保存食品标签 */
  async saveFoodLabel(foodLabel: FoodLabel): Promise<void> {
    await this.foodRepo.saveFoodLabel(foodLabel);
  }

  /** 获取常用食品列表 */
  async getFrequentItems(limit: number): Promise<FoodLabel[]> {
    return await this.foodRepo.getRecentLabels(limit);
  }
}