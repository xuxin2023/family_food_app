import { AiNutritionAdvice, DailyNutritionSummary, MealGroup, DietRecord, FamilyProfile, HealthSignal, DailyBudget, NutritionTarget } from 'hsp_core';

export interface IAiNutritionistService {
  getAdvice(member: FamilyProfile, signal: HealthSignal, budget: DailyBudget, records: DietRecord[], days: number, includeMealPlan: boolean, preSummaries?: DailyNutritionSummary[], preMealGroups?: MealGroup[]): Promise<AiNutritionAdvice>;
  generateAdvice(memberId: string, dietRecords: DietRecord[], days: number, includeMealPlan: boolean, budget: DailyBudget, target: NutritionTarget): Promise<AiNutritionAdvice>;
  buildContextPrompt(memberId: string, recentSummaries?: DailyNutritionSummary[]): Promise<string>;
  isAvailable(): boolean;
  getRemainingQuota(): number;
}