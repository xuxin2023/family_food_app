import { MealBalance, NutritionSnapshot, DailyBudget, NutritionTarget, WeeklyReport, NutritionTrend, ChildProtection, CredibilityResult, HealthSignal, HILOG_DOMAIN_DEFAULT, DailyNutritionSummary, MealGroup } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NutritionState';

@ObservedV2
export class NutritionState {
  @Trace todayIntakeCalories: number = 0;
  @Trace todayIntakeSodium: number = 0;
  @Trace todayIntakeSugar: number = 0;
  @Trace todayIntakeFat: number = 0;
  @Trace todayIntakeProtein: number = 0;
  @Trace todayIntakeCarbs: number = 0;
  @Trace todayIntakeFiber: number = 0;
  @Trace latestMealBalance: MealBalance | null = null;
  @Trace latestSnapshot: NutritionSnapshot | null = null;

  addIntake(calories: number, sodium: number, sugar: number, fat: number, protein: number, carbs: number, fiber: number): void {
    this.todayIntakeCalories += calories;
    this.todayIntakeSodium += sodium;
    this.todayIntakeSugar += sugar;
    this.todayIntakeFat += fat;
    this.todayIntakeProtein += protein;
    this.todayIntakeCarbs += carbs;
    this.todayIntakeFiber += fiber;
  }

  resetDailyIntake(): void {
    this.todayIntakeCalories = 0;
    this.todayIntakeSodium = 0;
    this.todayIntakeSugar = 0;
    this.todayIntakeFat = 0;
    this.todayIntakeProtein = 0;
    this.todayIntakeCarbs = 0;
    this.todayIntakeFiber = 0;
  }

  calculateProgressPercent(target: NutritionTarget): Map<string, number> {
    const progress = new Map<string, number>();
    if (target.caloriesTarget > 0) progress.set('calories', Math.min(this.todayIntakeCalories / target.caloriesTarget * 100, 999));
    if (target.proteinTarget_g > 0) progress.set('protein', Math.min(this.todayIntakeProtein / target.proteinTarget_g * 100, 999));
    if (target.fatMax_g > 0) progress.set('fat', Math.min(this.todayIntakeFat / target.fatMax_g * 100, 999));
    if (target.sodiumMax_mg > 0) progress.set('salt', Math.min(this.todayIntakeSodium / target.sodiumMax_mg * 100, 999));
    if (target.fiberTarget_g > 0) progress.set('fiber', Math.min(this.todayIntakeFiber / target.fiberTarget_g * 100, 999));
    return progress;
  }

  isOverTarget(target: NutritionTarget): string[] {
    const exceeded: string[] = [];
    if (target.caloriesTarget > 0 && this.todayIntakeCalories > target.caloriesTarget) exceeded.push('热量');
    if (target.sodiumMax_mg > 0 && this.todayIntakeSodium > target.sodiumMax_mg) exceeded.push('盐');
    if (target.sugarMax_g > 0 && this.todayIntakeSugar > target.sugarMax_g) exceeded.push('糖');
    if (target.fatMax_g > 0 && this.todayIntakeFat > target.fatMax_g) exceeded.push('脂肪');
    return exceeded;
  }
}
