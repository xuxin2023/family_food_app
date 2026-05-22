import {
  FoodLabel, Recommendation, EnhancedFoodRecommendation, FamilyProfile, HealthSignal, DailyBudget, DateUtil, CacheManager, DietRecord
} from 'hsp_core';
import { ScanHistoryRecord, DietRecordInput } from '../repository/HistoryRepository';

import { FoodRepository } from '../repository/FoodRepository';
import { HistoryRepository } from '../repository/HistoryRepository';
import { EngineManager } from '../EngineManager';
import { FoodAdapterEngine, TodayIntakeInput } from '../engine/FoodAdapterEngine';

export class FoodState {
  private foodRepo: FoodRepository;
  private historyRepo: HistoryRepository;
  private engines: EngineManager;
  private cache: CacheManager;
  private getMembersCache: () => FamilyProfile[];
  private getHealthSignal: (memberId: string) => HealthSignal;
  private getDailyBudgetSync: (memberId: string) => DailyBudget;

  constructor(
    foodRepo: FoodRepository, historyRepo: HistoryRepository,
    engines: EngineManager, cache: CacheManager,
    getMembersCache: () => FamilyProfile[],
    getHealthSignal: (memberId: string) => HealthSignal,
    getDailyBudgetSync: (memberId: string) => DailyBudget
  ) {
    this.foodRepo = foodRepo;
    this.historyRepo = historyRepo;
    this.engines = engines;
    this.cache = cache;
    this.getMembersCache = getMembersCache;
    this.getHealthSignal = getHealthSignal;
    this.getDailyBudgetSync = getDailyBudgetSync;
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

  async saveDietRecord(
    memberId: string, mealType: string,
    foodId: string, amount: number, sodium: number, sugar: number,
    calories: number, fat: number
  ): Promise<void> {
    const record = new DietRecordInput();
    record.memberId = memberId;
    record.date = DateUtil.getToday();
    record.scenario = 'meal_balance';
    record.mealType = mealType;
    record.foodId = foodId;
    record.amountG = amount;
    record.sodiumIntake = sodium;
    record.sugarIntake = sugar;
    record.calorieIntake = calories;
    record.fatIntake = fat;
    record.recordedAt = Date.now();
    await this.historyRepo.saveDietRecord(record);
  }

  calculateRecommendation(memberId: string, foodLabel: FoodLabel): Recommendation {
    const member = this.getMembersCache().find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    const budget = this.getDailyBudgetSync(memberId);
    return this.engines.calculateRecommendation(member, signal, foodLabel, budget);
  }

  async calculateEnhancedRecommendation(memberId: string, foodLabel: FoodLabel): Promise<EnhancedFoodRecommendation> {
    const member = this.getMembersCache().find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    const budget = this.getDailyBudgetSync(memberId);
    const rec = this.engines.calculateRecommendation(member, signal, foodLabel, budget);
    const todayIntake = new TodayIntakeInput();
    todayIntake.sodium_mg = Math.max(0, budget.sodiumBudget - budget.sodiumRemaining);
    todayIntake.sugar_g = Math.max(0, budget.sugarBudget - budget.sugarRemaining);
    todayIntake.energy_kcal = Math.max(0, budget.calorieBudget - budget.calorieRemaining);
    todayIntake.fat_g = Math.max(0, budget.fatBudget - budget.fatRemaining);
    return this.engines.calculateEnhancedAdaptation(member, foodLabel, signal, todayIntake, 1);
  }
}
