// NutritionTrend.ets
// 营养趋势数据模型 — 从 NutritionTrendEngine 提取至 hsp_core

import { DietRecord } from './DietRecord';

export class DailyNutritionSummary {
  date: string = '';
  sodium: number = 0;
  sugar: number = 0;
  calorie: number = 0;
  fat: number = 0;
  recordCount: number = 0;
}

export enum TrendDirection {
  UP = 'up',
  DOWN = 'down',
  STABLE = 'stable'
}

export class NutrientTrendData {
  nutrientName: string = '';
  unit: string = '';
  dailyValues: DailyNutrientPoint[] = [];
  currentValue: number = 0;
  targetValue: number = 0;
  maxValue: number = 0;
  color: string = '';
  trend: TrendDirection = TrendDirection.STABLE;
}

export class DailyNutrientPoint {
  date: string = '';
  value: number = 0;
}

export class MealGroup {
  mealType: string = '';
  mealLabel: string = '';
  records: DietRecord[] = [];
  sodiumTotal: number = 0;
  sugarTotal: number = 0;
  calorieTotal: number = 0;
  fatTotal: number = 0;
}
