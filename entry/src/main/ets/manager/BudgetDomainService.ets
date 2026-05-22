// BudgetDomainService.ets
// 预算领域服务 - 从 AppState 剥离的预算/膳食/营养趋势相关业务逻辑

import {
  FamilyProfile, HealthSignal, FoodLabel, DailyBudget, Recommendation, MealBalance, MealScenario, ChildProtection, DateUtil, CacheManager
} from 'hsp_core';
import { PositiveAdvice } from '../engine/PositiveAdviceEngine';
import { DailyNutritionSummary, NutritionTrendEngine, nutritionTrendEngine, MealGroup } from '../engine/NutritionTrendEngine';
import { HistoryRepository, DietRecordInput } from '../repository/HistoryRepository';
import { EngineManager } from '../EngineManager';

export class BudgetDomainService {
  private engs: EngineManager;
  private histRepo: HistoryRepository;
  private cacheMgr: CacheManager;

  constructor(engines: EngineManager, historyRepo: HistoryRepository, cache: CacheManager) {
    this.engs = engines;
    this.histRepo = historyRepo;
    this.cacheMgr = cache;
  }

  getDailyBudgetFromCache(memberId: string): DailyBudget | null {
    return this.cacheMgr.getDailyBudgetFromCache(memberId);
  }

  calculateRecommendation(memberId: string, foodLabel: FoodLabel, members: FamilyProfile[], signal: HealthSignal): Recommendation {
    const member = members.find(m => m.memberId === memberId) || new FamilyProfile();
    const budget = this.cacheMgr.getDailyBudgetFromCache(memberId) ?? new DailyBudget();
    return this.engs.calculateRecommendation(member, signal, foodLabel, budget);
  }

  calculateMealBalance(scenario: MealScenario, memberId: string, members: FamilyProfile[], signal: HealthSignal): MealBalance {
    const member = members.find(m => m.memberId === memberId) || new FamilyProfile();
    return this.engs.calculateMealBalance(scenario, member, signal);
  }

  generatePositiveAdvice(scenario: MealScenario, memberId: string, members: FamilyProfile[]): PositiveAdvice | null {
    const member = members.find(m => m.memberId === memberId) || new FamilyProfile();
    return this.engs.generatePositiveAdvice(scenario, member);
  }

  calculateChildProtection(memberId: string, foodLabel: FoodLabel, members: FamilyProfile[]): ChildProtection {
    const member = members.find(m => m.memberId === memberId) || new FamilyProfile();
    return this.engs.calculateChildProtection(member, foodLabel);
  }

  async saveDietRecord(
    memberId: string, mealType: string, foodId: string, amount: number,
    sodium: number, sugar: number, calories: number, fat: number
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
    await this.histRepo.saveDietRecord(record);
  }

  async getNutritionTrend(memberId: string, days: number): Promise<DailyNutritionSummary[]> {
    const endDate = DateUtil.getToday();
    const d = new Date();
    d.setDate(d.getDate() - days);
    const startDate = DateUtil.formatDate(d);
    const records = await this.histRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    return nutritionTrendEngine.aggregateDaily(records);
  }

  async getDailyDietGroups(memberId: string, date: string): Promise<MealGroup[]> {
    const records = await this.histRepo.getDietRecordsByDateRange(memberId, date, date);
    return nutritionTrendEngine.groupByMealType(records);
  }

  async generateWeeklyReport(memberId: string, members: FamilyProfile[]): Promise<string> {
    return this.engs.generateWeeklyReport(memberId, this.histRepo, members,
      (mid: string): DailyBudget => {
        const b = this.cacheMgr.getDailyBudgetFromCache(mid);
        return b !== null ? b : new DailyBudget();
      });
  }
}