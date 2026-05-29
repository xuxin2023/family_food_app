import {
  FamilyProfile, HealthSignal, DailyBudget, FoodLabel,
  AiNutritionAdvice, AiRecipeRecommendationResult, AiRecipeRequest,
  DateUtil, HILOG_DOMAIN_DEFAULT, DietRecord, NutritionTarget
} from 'hsp_core';
import { common } from '@kit.AbilityKit';
import { HistoryRepository } from '../repository/HistoryRepository';
import { EngineManager } from '../EngineManager';
import { ServiceManager } from '../ServiceManager';
import { NutritionTrendEngine, nutritionTrendEngine, DailyNutritionSummary, NutrientTrendData, MealGroup } from 'feature_report';
import { OnDeviceAiEngine } from '../engine/OnDeviceAiEngine';
import { ExerciseNutritionRecommendation, ExerciseSession } from 'feature_report';
import { CheckupReport, HealthArchiveUpdate } from 'feature_report';
import { ChildHealthAssessment } from 'feature_report';
import { PersonalizedRecommendation, PersonalizedContext } from 'feature_report';

export class HealthFacade {
  private readonly historyRepo: HistoryRepository;
  private readonly engines: EngineManager;
  private readonly services: ServiceManager;
  private onDeviceAiEngine: OnDeviceAiEngine | null = null;
  private getMemberById: (memberId: string) => FamilyProfile | undefined = () => undefined;
  private getHealthSignalById: (memberId: string) => HealthSignal = () => new HealthSignal();
  private getNutritionTargetById: (memberId: string) => NutritionTarget = () => new NutritionTarget();

  constructor(historyRepo: HistoryRepository, engines: EngineManager, services: ServiceManager) {
    this.historyRepo = historyRepo;
    this.engines = engines;
    this.services = services;
  }

  setMemberResolvers(
    getMember: (memberId: string) => FamilyProfile | undefined,
    getSignal: (memberId: string) => HealthSignal,
    getTarget: (memberId: string) => NutritionTarget
  ): void {
    this.getMemberById = getMember;
    this.getHealthSignalById = getSignal;
    this.getNutritionTargetById = getTarget;
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
    member: FamilyProfile, foodLabel: FoodLabel,
    signal: HealthSignal, memberId: string, days: number, includeMealPlan: boolean,
    getHealthSignal: (mid: string) => HealthSignal,
    getDailyBudgetSync: (mid: string) => DailyBudget
  ): Promise<AiNutritionAdvice> {
    const dietRecords = await this.historyRepo.getDietRecordsByDateRange(memberId, DateUtil.getToday(), DateUtil.getToday());
    return this.services.aiNutritionist.getAdvice(member, signal,
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

  async calculateExerciseNutrition(memberId: string): Promise<ExerciseNutritionRecommendation> {
    const profile = this.getMemberById(memberId) ?? new FamilyProfile();
    const signal = this.getHealthSignalById(memberId);
    const target = this.getNutritionTargetById(memberId);
    const session = new ExerciseSession();
    return this.engines.exerciseNutritionEngine.recommend(session, profile, signal, target);
  }

  async parseCheckupReport(content: string, memberId: string): Promise<CheckupReport> {
    return this.engines.checkupReportEngine.parseOcrText(content, memberId);
  }

  async generateHealthArchiveUpdate(memberId: string, report: CheckupReport): Promise<HealthArchiveUpdate> {
    const signal = this.getHealthSignalById(memberId);
    return this.engines.checkupReportEngine.generateHealthArchiveUpdate(report, signal);
  }

  async assessChildHealth(memberId: string, foodLabel: FoodLabel): Promise<ChildHealthAssessment> {
    const profile = this.getMemberById(memberId) ?? new FamilyProfile();
    const signal = this.getHealthSignalById(memberId);
    return this.engines.childHealthAssessmentEngine.assess(foodLabel, profile, 0, 0);
  }

  async getPersonalizedRecommendation(memberId: string): Promise<PersonalizedRecommendation> {
    const foodLabel = new FoodLabel();
    const ctx = new PersonalizedContext();
    ctx.profile = this.getMemberById(memberId) ?? new FamilyProfile();
    const signal = this.getHealthSignalById(memberId);
    return this.engines.personalizedRecommendEngine.recommend(foodLabel, ctx);
  }
}
