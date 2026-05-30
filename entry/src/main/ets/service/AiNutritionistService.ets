import { FamilyProfile, DailyBudget, HealthSignal, NutritionTarget, AiNutritionAdvice, DailyNutritionSummary, MealGroup, DietRecord } from 'hsp_core';
import { AiNutritionistServiceImpl, createAiNutritionistService } from 'hsp_service';
import { getCommonStateProvider } from './CommonStateProvider';

let _impl: AiNutritionistServiceImpl | null = null;
function getImpl(): AiNutritionistServiceImpl {
  if (_impl === null) { _impl = createAiNutritionistService(getCommonStateProvider()); }
  return _impl;
}

export class AiNutritionistService {
  async getAdvice(member: FamilyProfile, signal: HealthSignal, budget: DailyBudget, records: DietRecord[], days: number, includeMealPlan: boolean, preSummaries?: DailyNutritionSummary[], preMealGroups?: MealGroup[]): Promise<AiNutritionAdvice> { return getImpl().getAdvice(member, signal, budget, records, days, includeMealPlan, preSummaries, preMealGroups); }
  async generateAdvice(memberId: string, dietRecords: DietRecord[], days: number, includeMealPlan: boolean, budget: DailyBudget, target: NutritionTarget): Promise<AiNutritionAdvice> { return getImpl().generateAdvice(memberId, dietRecords, days, includeMealPlan, budget, target); }
  async buildContextPrompt(memberId: string, recentSummaries?: DailyNutritionSummary[]): Promise<string> { return getImpl().buildContextPrompt(memberId, recentSummaries); }
  async loadApiKey(): Promise<boolean> { return getImpl().loadApiKey(); }
  async setApiKey(key: string): Promise<boolean> { return getImpl().setApiKey(key); }
  async saveApiKey(context: Context, key: string): Promise<boolean> { return getImpl().saveApiKey(context, key); }
  isAvailable(): boolean { return getImpl().isAvailable(); }
}
