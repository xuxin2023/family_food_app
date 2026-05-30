import { FamilyProfile, HealthSignal, DailyBudget, NutritionTarget } from 'hsp_core';

export interface IAiStateProvider {
  getAllMembers(): Promise<FamilyProfile[]>;
  getHealthSignal(memberId: string): HealthSignal;
  getDailyBudget(memberId: string): DailyBudget;
  getCurrentMemberId(): string;
  getNutritionTarget(memberId: string): NutritionTarget | null;
}
