// INutritionTrendCalculator.ets
// 营养趋势计算接口 — NutritionTrendEngine 的抽象，供 NutritionDomainService 依赖反转

import { DietRecord } from './DietRecord';
import { DailyNutritionSummary, NutrientTrendData, MealGroup } from './NutritionTrend';

export interface INutritionTrendCalculator {
  aggregateDaily(records: DietRecord[]): DailyNutritionSummary[];
  buildNutrientTrends(
    dailySummaries: DailyNutritionSummary[],
    targetSodium: number,
    targetSugar: number,
    targetCalorie: number,
    targetFat: number
  ): NutrientTrendData[];
  groupByMealType(records: DietRecord[]): MealGroup[];
}
