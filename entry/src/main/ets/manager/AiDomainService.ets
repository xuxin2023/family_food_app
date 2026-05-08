// AiDomainService.ets
// AI 领域服务 - 从 AppState 剥离的 AI 营养顾问相关业务逻辑

import { FamilyProfile } from '../model/FamilyProfile';
import { HealthSignal } from '../model/HealthSignal';
import { FoodLabel } from '../model/FoodLabel';
import { DailyBudget } from '../model/DailyBudget';
import { AiNutritionAdvice, AiRecipeRecommendationResult, AiRecipeRequest } from '../model/AiModels';
import { HistoryRepository } from '../repository/HistoryRepository';
import { DateUtil } from '../utils/DateUtil';
import { CacheManager } from '../utils/CacheManager';
import { ServiceManager } from '../ServiceManager';

export class AiDomainService {
  private svc: ServiceManager;
  private histRepo: HistoryRepository;
  private cacheMgr: CacheManager;

  constructor(services: ServiceManager, historyRepo: HistoryRepository, cache: CacheManager) {
    this.svc = services;
    this.histRepo = historyRepo;
    this.cacheMgr = cache;
  }

  async getAiNutritionAdvice(
    member: FamilyProfile, _foodLabel: FoodLabel,
    _signal: HealthSignal, memberId: string, days: number, includeMealPlan: boolean
  ): Promise<AiNutritionAdvice> {
    const dietRecords = await this.histRepo.getDietRecordsByDateRange(memberId, DateUtil.getToday(), DateUtil.getToday());
    return this.svc.aiNutritionist.getAdvice(member, this.getHealthSignal(memberId),
      this.getDailyBudgetSync(memberId), dietRecords, days, includeMealPlan);
  }

  async getAiRecipeRecommendation(
    request: AiRecipeRequest,
    members: FamilyProfile[]
  ): Promise<AiRecipeRecommendationResult> {
    const signals: Map<string, HealthSignal> = new Map();
    const budgets: Map<string, DailyBudget> = new Map();
    for (const m of members) {
      signals.set(m.memberId, this.getHealthSignal(m.memberId));
      budgets.set(m.memberId, this.getDailyBudgetSync(m.memberId));
    }
    return this.svc.aiRecipeRecommender.getRecommendations(request, members, signals, budgets);
  }

  private getHealthSignal(memberId: string): HealthSignal {
    const s = this.cacheMgr.getHealthSignalFromCache(memberId);
    if (s === null) {
      return new HealthSignal();
    }
    return s;
  }

  private getDailyBudgetSync(memberId: string): DailyBudget {
    const b = this.cacheMgr.getDailyBudgetFromCache(memberId);
    if (b === null) {
      return new DailyBudget();
    }
    return b;
  }
}
