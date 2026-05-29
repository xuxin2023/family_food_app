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
    if (target.proteinTarget > 0) progress.set('protein', Math.min(this.todayIntakeProtein / target.proteinTarget * 100, 999));
    if (target.fatTarget > 0) progress.set('fat', Math.min(this.todayIntakeFat / target.fatTarget * 100, 999));
    if (target.carbsTarget > 0) progress.set('carbs', Math.min(this.todayIntakeCarbs / target.carbsTarget * 100, 999));
    if (target.saltTarget > 0) progress.set('salt', Math.min(this.todayIntakeSodium / target.saltTarget * 100, 999));
    if (target.fiberTarget > 0) progress.set('fiber', Math.min(this.todayIntakeFiber / target.fiberTarget * 100, 999));
    return progress;
  }

  isOverTarget(target: NutritionTarget): string[] {
    const exceeded: string[] = [];
    if (target.caloriesTarget > 0 && this.todayIntakeCalories > target.caloriesTarget) exceeded.push('热量');
    if (target.saltTarget > 0 && this.todayIntakeSodium > target.saltTarget) exceeded.push('盐');
    if (target.sugarTarget > 0 && this.todayIntakeSugar > target.sugarTarget) exceeded.push('糖');
    if (target.fatTarget > 0 && this.todayIntakeFat > target.fatTarget) exceeded.push('脂肪');
    return exceeded;
  }
}
