// NutritionDomainService.ets
// 营养领域服务 - 编排营养趋势分析、AI 营养师建议、膳食分组等能力
// 从 AppState 拆分，减轻上帝类职责

import { FamilyProfile, DailyBudget, HealthSignal, AiNutritionAdvice, DateUtil, HILOG_DOMAIN, INutritionTrendCalculator, DailyNutritionSummary, NutrientTrendData, MealGroup, DietRecord } from 'hsp_core';
import { HistoryRepository } from '../repository/HistoryRepository';
import { AiNutritionistService } from './AiNutritionistService';

const TAG = 'NutritionDomainService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class NutritionDomainService {
  private historyRepo: HistoryRepository;
  private aiNutritionist: AiNutritionistService;
  private trendCalculator: INutritionTrendCalculator;

  constructor(
    historyRepo: HistoryRepository,
    aiNutritionist: AiNutritionistService,
    trendCalculator: INutritionTrendCalculator
  ) {
    this.historyRepo = historyRepo;
    this.aiNutritionist = aiNutritionist;
    this.trendCalculator = trendCalculator;
  }

  async getAiNutritionAdvice(
    member: FamilyProfile,
    signal: HealthSignal,
    budget: DailyBudget,
    memberId: string,
    days: number,
    includeMealPlan: boolean
  ): Promise<AiNutritionAdvice> {
    const endDate = DateUtil.getToday();
    const startDate = this.getDaysAgo(days);
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    const summaries = this.trendCalculator.aggregateDaily(records);
    const mealGroups = this.trendCalculator.groupByMealType(records);
    return await this.aiNutritionist.getAdvice(member, signal, budget, records, days, includeMealPlan, summaries, mealGroups);
  }

  async getNutritionTrends(
    memberId: string,
    days: number,
    membersCache: FamilyProfile[]
  ): Promise<NutrientTrendData[]> {
    const endDate = DateUtil.getToday();
    const startDate = this.getDaysAgo(days);
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    const member = membersCache.find(m => m.memberId === memberId);
    const targetSodium = member?.dailyBudget.sodiumBudget || 2000;
    const targetSugar = member?.dailyBudget.sugarBudget || 50;
    const targetCalorie = member?.dailyBudget.calorieBudget || 2000;
    const targetFat = member?.dailyBudget.fatBudget || 65;
    return this.trendCalculator.buildNutrientTrends(
      this.trendCalculator.aggregateDaily(records),
      targetSodium, targetSugar, targetCalorie, targetFat);
  }

  async getDailySummaries(memberId: string, days: number): Promise<DailyNutritionSummary[]> {
    const endDate = DateUtil.getToday();
    const startDate = this.getDaysAgo(days);
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    return this.trendCalculator.aggregateDaily(records);
  }

  async getDailyDietGroups(memberId: string, date: string): Promise<MealGroup[]> {
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, date, date);
    return this.trendCalculator.groupByMealType(records);
  }

  private getDaysAgo(days: number): string {
    const date = new Date();
    date.setDate(date.getDate() - days);
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
  }
}