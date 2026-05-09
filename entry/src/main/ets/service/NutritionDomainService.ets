// NutritionDomainService.ets
// 营养领域服务 - 编排营养趋势分析、AI 营养师建议、膳食分组等能力
// 从 AppState 拆分，减轻上帝类职责

import { FamilyProfile } from '../model/FamilyProfile';
import { DailyBudget } from '../model/DailyBudget';
import { HealthSignal } from '../model/HealthSignal';
import { DietRecord } from '../repository/HistoryRepository';
import { HistoryRepository } from '../repository/HistoryRepository';
import { NutritionTrendEngine, DailyNutritionSummary, NutrientTrendData, MealGroup } from '../engine/NutritionTrendEngine';
import { AiNutritionAdvice } from '../model/AiModels';
import { AiNutritionistService } from './AiNutritionistService';
import { DateUtil } from '../utils/DateUtil';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'NutritionDomainService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class NutritionDomainService {
  private historyRepo: HistoryRepository;
  private aiNutritionist: AiNutritionistService;

  constructor(
    historyRepo: HistoryRepository,
    aiNutritionist: AiNutritionistService
  ) {
    this.historyRepo = historyRepo;
    this.aiNutritionist = aiNutritionist;
  }

  /**
   * 获取 AI 营养师建议（编排成员画像、健康信号、预算、膳食记录 → 传给 AI 服务）
   */
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
    return await this.aiNutritionist.getAdvice(member, signal, budget, records, days, includeMealPlan);
  }

  /**
   * 获取营养趋势数据
   */
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
    return NutritionTrendEngine.buildNutrientTrends(
      NutritionTrendEngine.aggregateDaily(records),
      targetSodium, targetSugar, targetCalorie, targetFat);
  }

  /**
   * 获取每日营养汇总
   */
  async getDailySummaries(memberId: string, days: number): Promise<DailyNutritionSummary[]> {
    const endDate = DateUtil.getToday();
    const startDate = this.getDaysAgo(days);
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    return NutritionTrendEngine.aggregateDaily(records);
  }

  /**
   * 获取指定日期的膳食分组
   */
  async getDailyDietGroups(memberId: string, date: string): Promise<MealGroup[]> {
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, date, date);
    return NutritionTrendEngine.groupByMealType(records);
  }

  private getDaysAgo(days: number): string {
    const date = new Date();
    date.setDate(date.getDate() - days);
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
  }
}