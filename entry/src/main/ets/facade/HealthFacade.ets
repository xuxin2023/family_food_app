import {
  FamilyProfile, HealthSignal, DailyBudget, FoodLabel,
  AiNutritionAdvice, AiRecipeRecommendationResult, AiRecipeRequest,
  DateUtil, HILOG_DOMAIN, DietRecord
} from 'hsp_core';
import { common } from '@kit.AbilityKit';
import { HistoryRepository } from '../repository/HistoryRepository';
import { EngineManager } from '../EngineManager';
import { ServiceManager } from '../ServiceManager';
import { NutritionTrendEngine, nutritionTrendEngine, DailyNutritionSummary, NutrientTrendData, MealGroup } from '../engine/NutritionTrendEngine';
import { OnDeviceAiEngine } from '../engine/OnDeviceAiEngine';
import { ExerciseNutritionRecommendation } from '../engine/ExerciseNutritionEngine';
import { CheckupReport, HealthArchiveUpdate } from '../engine/CheckupReportEngine';
import { ChildHealthAssessment } from '../engine/ChildHealthAssessmentEngine';
import { PersonalizedRecommendation } from '../engine/PersonalizedRecommendEngine';

export class HealthFacade {
  private readonly historyRepo: HistoryRepository;
  private readonly engines: EngineManager;
  private readonly services: ServiceManager;
  private onDeviceAiEngine: OnDeviceAiEngine | null = null;

  constructor(historyRepo: HistoryRepository, engines: EngineManager, services: ServiceManager) {
    this.historyRepo = historyRepo;
    this.engines = engines;
    this.services = services;
  }

  setOnDeviceAiEngine(engine: OnDeviceAiEngine | null): void {
    this.onDeviceAiEngine = engine;
  }

  getOnDeviceAiEngine(): OnDeviceAiEngine | null {
    return this.onDeviceAiEngine;
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

  async getAiNutritionAdvice(
    member: FamilyProfile, _foodLabel: FoodLabel,
    _signal: HealthSignal, memberId: string, days: number, includeMealPlan: boolean,
    getHealthSignal: (mid: string) => HealthSignal,
    getDailyBudgetSync: (mid: string) => DailyBudget
  ): Promise<AiNutritionAdvice> {
    const dietRecords = await this.historyRepo.getDietRecordsByDateRange(memberId, DateUtil.getToday(), DateUtil.getToday());
    return this.services.aiNutritionist.getAdvice(member, getHealthSignal(memberId),
      getDailyBudgetSync(memberId), dietRecords, days, includeMealPlan);
  }

  async getAiRecipeRecommendation(
    request: AiRecipeRequest,
    membersCache: FamilyProfile[],
    getHealthSignal: (mid: string) => HealthSignal,
    getDailyBudgetSync: (mid: string) => DailyBudget
  ): Promise<AiRecipeRecommendationResult> {
    const signals: Map<string, HealthSignal> = new Map();
    const budgets: Map<string, DailyBudget> = new Map();
    for (const m of membersCache) {
      signals.set(m.memberId, getHealthSignal(m.memberId));
      budgets.set(m.memberId, getDailyBudgetSync(m.memberId));
    }
    return this.services.aiRecipeRecommender.getRecommendations(request, membersCache, signals, budgets);
  }

  async getNutritionTrend(memberId: string, days: number): Promise<DailyNutritionSummary[]> {
    const endDate = DateUtil.getToday();
    const d = new Date();
    d.setDate(d.getDate() - days);
    const startDate = DateUtil.formatDate(d);
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, startDate, endDate);
    return nutritionTrendEngine.aggregateDaily(records);
  }

  async getDailySummaries(memberId: string, days: number): Promise<DailyNutritionSummary[]> {
    return this.getNutritionTrend(memberId, days);
  }

  async getDailyDietGroups(memberId: string, date: string): Promise<MealGroup[]> {
    const records = await this.historyRepo.getDietRecordsByDateRange(memberId, date, date);
    return nutritionTrendEngine.groupByMealType(records);
  }

  async generateWeeklyReport(
    memberId: string, membersCache: FamilyProfile[],
    getDailyBudgetSync: (mid: string) => DailyBudget
  ): Promise<string> {
    return this.engines.generateWeeklyReport(memberId, this.historyRepo, membersCache, getDailyBudgetSync);
  }

  async calculateExerciseNutrition(_memberId: string): Promise<ExerciseNutritionRecommendation> {
    return new ExerciseNutritionRecommendation();
  }

  async parseCheckupReport(content: string, memberId: string): Promise<CheckupReport> {
    const r = new CheckupReport();
    r.memberId = memberId;
    return r;
  }

  async generateHealthArchiveUpdate(memberId: string, _report: CheckupReport): Promise<HealthArchiveUpdate> {
    const u = new HealthArchiveUpdate();
    u.memberId = memberId;
    return u;
  }

  async assessChildHealth(memberId: string, _foodLabel: FoodLabel): Promise<ChildHealthAssessment> {
    const a = new ChildHealthAssessment();
    a.memberId = memberId;
    return a;
  }

  async getPersonalizedRecommendation(_memberId: string): Promise<PersonalizedRecommendation> {
    return new PersonalizedRecommendation();
  }
}
