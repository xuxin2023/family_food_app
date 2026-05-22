import {
  FoodLabel, Recommendation, EnhancedFoodRecommendation, DailyBudget,
  NutritionTarget, NutritionSnapshot, ChildProtection, DateUtil, CacheManager,
  HILOG_DOMAIN, DietRecord, FamilyProfile, HealthSignal, MealScenario, MealBalance
} from 'hsp_core';
import { FoodRepository } from '../repository/FoodRepository';
import { HistoryRepository, ScanHistoryRecord, DietRecordInput } from '../repository/HistoryRepository';
import { FavoriteRepository, FavoriteItem } from '../repository/FavoriteRepository';
import { EngineManager } from '../EngineManager';
import { TodayIntakeInput } from '../engine/FoodAdapterEngine';
import { PositiveAdvice } from '../engine/PositiveAdviceEngine';

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

  async saveFoodLabel(label: FoodLabel): Promise<void> {
    await this.foodRepo.saveFoodLabel(label);
  }

  async findFoodByBarcode(barcode: string): Promise<FoodLabel | null> {
    return this.foodRepo.findByBarcode(barcode);
  }

  async findFoodById(foodId: string): Promise<FoodLabel | null> {
    return this.foodRepo.findById(foodId);
  }

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
  }

  async getNutritionSnapshots(memberId: string, limit: number): Promise<NutritionSnapshot[]> {
    return this.historyRepo.getNutritionSnapshots(memberId, limit);
  }

  async getAllFavorites(): Promise<FavoriteItem[]> {
    return this.favoriteRepo.getAllFavorites();
  }

  async removeFavorite(foodId: string): Promise<void> {
    await this.favoriteRepo.removeFavorite(foodId);
  }

  async saveNutritionTarget(target: NutritionTarget): Promise<void> {
    await this.favoriteRepo.storeNutritionTarget(target);
  }

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

  calculateMealBalance(scenario: MealScenario): MealBalance {
    return this.engines.getMealBalance(new FamilyProfile(), new DailyBudget(), scenario, 3);
  }

  generatePositiveAdvice(): PositiveAdvice | null {
    const advices = this.engines.getPositiveAdvice(new FoodLabel(), new Recommendation());
    return advices.length > 0 ? advices[0] : null;
  }

  calculateChildProtection(foodLabel: FoodLabel): ChildProtection {
    return this.engines.getChildProtection(new FamilyProfile(), foodLabel, new Recommendation());
  }
}
