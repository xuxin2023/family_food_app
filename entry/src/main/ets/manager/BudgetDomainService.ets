// BudgetDomainService.ets
// 预算领域服务 - 从 AppState 剥离的预算/膳食/营养趋势相关业务逻辑

import { FamilyProfile } from '../model/FamilyProfile';
import { HealthSignal } from '../model/HealthSignal';
import { FoodLabel } from '../model/FoodLabel';
import { DailyBudget } from '../model/DailyBudget';
import { Recommendation } from '../model/Recommendation';
import { MealBalance, MealScenario } from '../model/MealBalance';
import { ChildProtection } from '../model/ChildProtection';
import { PositiveAdvice } from '../engine/PositiveAdviceEngine';
import { DailyNutritionSummary, NutritionTrendEngine, MealGroup } from '../engine/NutritionTrendEngine';
import { HistoryRepository, DietRecordInput } from '../repository/HistoryRepository';
import { EngineManager } from '../EngineManager';
import { DateUtil } from '../utils/DateUtil';
import { CacheManager } from '../utils/CacheManager';

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
    await this.histRepo.saveDietRecord(record);
  }

  async getNutritionTrend(memberId: string, days: number): Promise<DailyNutritionSummary[]> {
    const endDate = DateUtil.getToday();
    const d = new Date();
    d.setDate(d.getDate() - days);
    const startDate = DateUtil.formatDate(d);
    const records = await this.histRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    return NutritionTrendEngine.aggregateDaily(records);
  }

  async getDailyDietGroups(memberId: string, date: string): Promise<MealGroup[]> {
    const records = await this.histRepo.getDietRecordsByDateRange(memberId, date, date);
    return NutritionTrendEngine.groupByMealType(records);
  }

  async generateWeeklyReport(memberId: string, members: FamilyProfile[]): Promise<string> {
    return this.engs.generateWeeklyReport(memberId, this.histRepo, members,
      (mid: string): DailyBudget => {
        const b = this.cacheMgr.getDailyBudgetFromCache(mid);
        return b !== null ? b : new DailyBudget();
      });
  }
}
