import {
  FoodLabel, Recommendation, EnhancedFoodRecommendation, DailyBudget,
  NutritionTarget, NutritionSnapshot, ChildProtection, DateUtil, CacheManager,
  HILOG_DOMAIN_DEFAULT, DietRecord, FamilyProfile, HealthSignal, MealScenario, MealBalance,
  serialScheduler
} from 'hsp_core';
import { FoodRepository } from '../repository/FoodRepository';
import { HistoryRepository, ScanHistoryRecord, DietRecordInput } from '../repository/HistoryRepository';
import { FavoriteRepository, FavoriteItem } from '../repository/FavoriteRepository';
import { EngineManager } from '../EngineManager';
import { TodayIntakeInput } from 'feature_scan';
import { PositiveAdvice } from 'feature_report';

/**
 * 食品业务门面
 *
 * 统一封装食品标签存取、扫码查询、饮食记录、收藏管理、
 * 营养推荐计算、增强推荐、膳食平衡、积极建议、儿童保护等操作，
 * 对UI层提供简洁的API入口，隐藏Repository和Engine细节。
 *
 * @since 1.0.0
 */
export class FoodFacade {
  private readonly foodRepo: FoodRepository;
  private readonly historyRepo: HistoryRepository;
  private readonly favoriteRepo: FavoriteRepository;
  private readonly engines: EngineManager;
  private readonly cache: CacheManager;

  constructor(
    foodRepo: FoodRepository, historyRepo: HistoryRepository,
    favoriteRepo: FavoriteRepository, engines: EngineManager, cache: CacheManager
  ) {
    this.foodRepo = foodRepo;
    this.historyRepo = historyRepo;
    this.favoriteRepo = favoriteRepo;
    this.engines = engines;
    this.cache = cache;
  }

  /**
   * 保存食品标签
   *
   * @param label - 食品标签数据
   * @returns Promise<void>
   */
  async saveFoodLabel(label: FoodLabel): Promise<void> {
    await this.foodRepo.saveFoodLabel(label);
  }

  /**
   * 通过条形码查询食品
   *
   * @param barcode - 商品条形码
   * @returns 食品标签，未找到返回null
   */
  async findFoodByBarcode(barcode: string): Promise<FoodLabel | null> {
    return this.foodRepo.findByBarcode(barcode);
  }

  /**
   * 通过食品ID查询
   *
   * @param foodId - 食品ID
   * @returns 食品标签，未找到返回null
   */
  async findFoodById(foodId: string): Promise<FoodLabel | null> {
    return this.foodRepo.findById(foodId);
  }

  /**
   * 批量查询食品
   *
   * @param foodIds - 食品ID列表
   * @returns 食品ID→FoodLabel映射
   */
  async findFoodByIds(foodIds: string[]): Promise<Map<string, FoodLabel>> {
    return this.foodRepo.findByIds(foodIds);
  }

  async getRecentScanHistory(limit?: number): Promise<ScanHistoryRecord[]> {
    return this.historyRepo.getRecentScanHistory(limit || 20);
  }

  async getDietRecordsByDateRange(memberId: string, startDate: string, endDate: string): Promise<DietRecord[]> {
    return this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
  }

  async getTodayDietRecords(memberId: string): Promise<DietRecord[]> {
    const today = DateUtil.getToday();
    return this.historyRepo.getDietRecordsByDateRange(memberId, today, today);
  }

  async saveDietRecord(
    memberId: string, _scenario: MealScenario, mealType: string,
    foodId: string, amount: number, sodium: number, sugar: number,
    calories: number, fat: number
  ): Promise<void> {
    await serialScheduler.enqueue(`diet_${memberId}`, async () => {
      const record: DietRecordInput = {
        memberId: memberId,
        date: DateUtil.getToday(),
        scenario: 'meal_balance',
        mealType: mealType,
        foodId: foodId,
        amountG: amount,
        sodiumIntake: sodium,
        sugarIntake: sugar,
        calorieIntake: calories,
        fatIntake: fat,
        recordedAt: Date.now()
      };
      await this.historyRepo.saveDietRecord(record);
    });
  }

  async getNutritionSnapshots(memberId: string, limit: number): Promise<NutritionSnapshot[]> {
    return this.historyRepo.getNutritionSnapshots(memberId, limit);
  }

  async getAllFavorites(): Promise<FavoriteItem[]> {
    return this.favoriteRepo.getAll();
  }

  async removeFavorite(foodId: string): Promise<void> {
    await this.favoriteRepo.removeFavorite(foodId);
  }

  async saveNutritionTarget(target: NutritionTarget): Promise<void> {
    await this.favoriteRepo.storeNutritionTarget(target);
  }

  /**
   * 计算食品适配推荐
   *
   * @param memberId - 家庭成员ID
   * @param foodLabel - 食品标签
   * @param membersCache - 成员缓存列表
   * @param getHealthSignal - 获取健康信号回调
   * @param getDailyBudgetSync - 获取每日预算回调
   * @returns 适配推荐结果
   */
  calculateRecommendation(
    memberId: string, foodLabel: FoodLabel,
    membersCache: FamilyProfile[], getHealthSignal: (mid: string) => HealthSignal,
    getDailyBudgetSync: (mid: string) => DailyBudget
  ): Recommendation {
    const member = membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = getHealthSignal(memberId);
    const budget = getDailyBudgetSync(memberId);
    return this.engines.calculateRecommendation(member, signal, foodLabel, budget);
  }

  async calculateNutriScore(label: FoodLabel): Promise<number> {
    return this.engines.calculateNutriScore(label);
  }

  /**
   * 计算增强推荐（含今日摄入上下文）
   *
   * @param memberId - 家庭成员ID
   * @param foodLabel - 食品标签
   * @param membersCache - 成员缓存列表
   * @param getHealthSignal - 获取健康信号回调
   * @param getDailyBudgetSync - 获取每日预算回调
   * @returns 增强推荐结果
   */
  async calculateEnhancedRecommendation(
    memberId: string, foodLabel: FoodLabel,
    membersCache: FamilyProfile[], getHealthSignal: (mid: string) => HealthSignal,
    getDailyBudgetSync: (mid: string) => DailyBudget
  ): Promise<EnhancedFoodRecommendation> {
    const member = membersCache.find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = getHealthSignal(memberId);
    const budget = getDailyBudgetSync(memberId);
    const todayIntake: TodayIntakeInput = {
      sodium_mg: Math.max(0, budget.sodiumBudget - budget.sodiumRemaining),
      sugar_g: Math.max(0, budget.sugarBudget - budget.sugarRemaining),
      energy_kcal: Math.max(0, budget.calorieBudget - budget.calorieRemaining),
      fat_g: Math.max(0, budget.fatBudget - budget.fatRemaining)
    };
    return this.engines.calculateEnhancedAdaptation(member, foodLabel, signal, todayIntake, 1);
  }

  calculateMealBalance(
    scenario: MealScenario,
    member?: FamilyProfile,
    budget?: DailyBudget
  ): MealBalance {
    return this.engines.getMealBalance(member ?? new FamilyProfile(), budget ?? new DailyBudget(), scenario, 3);
  }

  generatePositiveAdvice(
    foodLabel?: FoodLabel,
    recommendation?: Recommendation
  ): PositiveAdvice | null {
    const advices = this.engines.getPositiveAdvice(foodLabel ?? new FoodLabel(), recommendation ?? new Recommendation());
    return advices.length > 0 ? advices[0] : null;
  }

  calculateChildProtection(
    foodLabel: FoodLabel,
    member?: FamilyProfile,
    recommendation?: Recommendation
  ): ChildProtection {
    return this.engines.getChildProtection(member ?? new FamilyProfile(), foodLabel, recommendation ?? new Recommendation());
  }
}
