// RepositoryManager.ets
// 仓库管理器 - 统一管理所有数据仓库的初始化、生命周期和访问
// 从 AppState 提取，减少上帝类负担
//
// 鸿蒙6.1 ArkTS 约束：
// - 不使用 undefined 类型，统一使用 null

import { FamilyProfile, FoodLabel, HILOG_DOMAIN_DEFAULT, DietRecord } from 'hsp_core';
import { FamilyRepository } from '../repository/FamilyRepository';
import { FoodRepository } from '../repository/FoodRepository';
import { HistoryRepository, ScanHistoryRecord } from '../repository/HistoryRepository';

import { RuleRepository } from '../repository/RuleRepository';
import { FamilyGroupRepository } from '../repository/FamilyGroupRepository';
import { RecipeRepository } from '../repository/RecipeRepository';
import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'RepositoryManager';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class RepositoryManager {
  readonly family: FamilyRepository = new FamilyRepository();
  readonly food: FoodRepository = new FoodRepository();
  readonly history: HistoryRepository = new HistoryRepository();
  readonly rule: RuleRepository = new RuleRepository();
  readonly group: FamilyGroupRepository = new FamilyGroupRepository();
  readonly recipe: RecipeRepository = new RecipeRepository();

  /**
   * 初始化所有仓库
   * @param rdbStore 数据库实例
   * @param context  应用上下文
   */
  async initAll(rdbStore: relationalStore.RdbStore, context: common.Context): Promise<void> {
    await this.family.init(rdbStore);
    await this.food.init(rdbStore);
    await this.history.init(rdbStore);
    await this.group.init(rdbStore);
    await this.group.createTables();
    await this.recipe.init(rdbStore);
    await this.recipe.createTables();
    this.rule.setContext(context);
    hilog.info(DOMAIN_ZERO, TAG, 'All repositories initialized');
  }

  // ========== 成员操作 ==========

  async getAllMembers(): Promise<FamilyProfile[]> {
    return this.family.getAllMembers();
  }

  async saveMember(profile: FamilyProfile): Promise<void> {
    await this.family.saveMember(profile);
  }

  async deleteMember(memberId: string): Promise<void> {
    await this.family.deleteMember(memberId);
  }

  // ========== 食品标签操作 ==========

  async saveFoodLabel(label: FoodLabel): Promise<void> {
    await this.food.saveFoodLabel(label);
  }

  async findFoodByBarcode(barcode: string): Promise<FoodLabel | null> {
    return this.food.findByBarcode(barcode);
  }

  async findFoodById(foodId: string): Promise<FoodLabel | null> {
    return this.food.findById(foodId);
  }

  async findFoodByIds(foodIds: string[]): Promise<Map<string, FoodLabel>> {
    return this.food.findByIds(foodIds);
  }

  // ========== 历史记录操作 ==========

  async getRecentScanHistory(limit?: number): Promise<ScanHistoryRecord[]> {
    return this.history.getRecentScanHistory(limit || 20);
  }

  async getDietRecordsByDateRange(
    memberId: string, startDate: string, endDate: string
  ): Promise<DietRecord[]> {
    return this.history.getDietRecordsByDateRange(memberId, startDate, endDate);
  }
}
