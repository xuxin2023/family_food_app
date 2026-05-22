import {
  FamilyProfile, HealthSignal, DailyBudget, MealBalance, MealScenario, ChildProtection, FoodLabel, Recommendation, DateUtil, CacheManager, DailyNutritionSummary, DietRecord
} from 'hsp_core';
import { PositiveAdvice } from '../engine/PositiveAdviceEngine';

import { HistoryRepository } from '../repository/HistoryRepository';

import { EngineManager } from '../EngineManager';
import { nutritionTrendEngine } from '../engine/NutritionTrendEngine';
import { common } from '@kit.AbilityKit';
import { ServiceManager } from '../ServiceManager';

export class HealthState {
  private cache: CacheManager;
  private engines: EngineManager;
  private services: ServiceManager;
  private historyRepoForTrend: (() => Promise<DietRecord[]>) | null = null;
  private getMembersCache: () => FamilyProfile[];
  // 函数引用：构造函数注入，内部别名避免与方法重名
  private budgetFn: (memberId: string) => DailyBudget;

  constructor(
    cache: CacheManager, engines: EngineManager, services: ServiceManager,
    getMembersCache: () => FamilyProfile[],
    getDailyBudgetSync: (memberId: string) => DailyBudget
  ) {
    this.cache = cache;
    this.engines = engines;
    this.services = services;
    this.getMembersCache = getMembersCache;
    this.budgetFn = getDailyBudgetSync;
  }

  setHistoryRepoAccessor(accessor: () => Promise<DietRecord[]>): void {
    this.historyRepoForTrend = accessor;
  }

  getDailyBudgetSync(memberId: string): DailyBudget {
    return this.budgetFn(memberId);
  }

  getHealthSignal(memberId: string): HealthSignal {
    const cached = this.cache.getHealthSignalFromCache(memberId);
    if (cached) return cached;
    const signal = new HealthSignal();
    signal.memberId = memberId;
    signal.date = DateUtil.getToday();
    this.cache.setHealthSignalToCache(memberId, signal);
    return signal;
  }

  async getHealthSignalAsync(memberId: string): Promise<HealthSignal> {
    return this.getHealthSignal(memberId);
  }

  async switchToHwHealthKit(context: common.Context): Promise<boolean> {
    return this.services.switchToHwHealthKit(context);
  }

  switchToManualProvider(): void {
    this.services.switchToManualProvider();
  }

  isUsingHwHealthKit(): boolean {
    return this.services.useHwHealthKit;
  }

  async requestHealthAuthorization(): Promise<boolean> {
    return this.services.requestHealthAuthorization();
  }

  async checkHealthAuthorization(): Promise<boolean> {
    return this.services.checkHealthAuthorization();
  }

  async getNutritionTrend(memberId: string, days: number): Promise<DailyNutritionSummary[]> {
    if (!this.historyRepoForTrend) return [];
    const endDate = DateUtil.getToday();
    const d = new Date();
    d.setDate(d.getDate() - days);
    const startDate = DateUtil.formatDate(d);
    const records = await this.historyRepoForTrend();
    const summaries = nutritionTrendEngine.aggregateDaily(records);
    return summaries;
  }

  async generateWeeklyReport(memberId: string): Promise<string> {
    const members = this.getMembersCache();
    return this.engines.generateWeeklyReport(memberId,
      new HistoryRepository(),
      members, (mid: string) => this.getDailyBudgetSync(mid));
  }

  calculateMealBalance(scenario: MealScenario, memberId: string): MealBalance {
    const member = this.getMembersCache().find(m => m.memberId === memberId) || new FamilyProfile();
    const budget = this.getDailyBudgetSync(memberId);
    return this.engines.mealBalanceEngine.calculate(scenario, member, this.getHealthSignal(memberId));
  }

  generatePositiveAdvice(scenario: MealScenario, memberId: string): PositiveAdvice | null {
    const member = this.getMembersCache().find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    const budget = this.getDailyBudgetSync(memberId);
    const foodLabel = new FoodLabel();
    this.engines.calculateRecommendation(member, signal, foodLabel, budget);
    return this.engines.positiveAdviceEngine.generateForScenario(scenario, member);
  }

  calculateChildProtection(memberId: string, foodLabel: FoodLabel): ChildProtection {
    const member = this.getMembersCache().find(m => m.memberId === memberId) || new FamilyProfile();
    const signal = this.getHealthSignal(memberId);
    const budget = this.getDailyBudgetSync(memberId);
    const rec = this.engines.calculateRecommendation(member, signal, foodLabel, budget);
    return this.engines.calculateChildProtection(member, foodLabel);
  }

  persistAllHealthSignals(): void {
    this.cache.clearHealthSignalsCache();
  }
}
