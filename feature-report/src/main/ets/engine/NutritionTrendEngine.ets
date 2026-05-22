// NutritionTrendEngine.ets
// 营养趋势分析引擎 - 从 DietRecord 聚合出日/周/月趋势数据和预算完成度

import { DietRecord, DailyNutritionSummary, TrendDirection, NutrientTrendData, DailyNutrientPoint, MealGroup, INutritionTrendCalculator } from 'hsp_core';

export { DailyNutritionSummary, TrendDirection, NutrientTrendData, DailyNutrientPoint, MealGroup };

const MEAL_LABELS: Record<string, string> = {
  'breakfast': '早餐',
  'lunch': '午餐',
  'dinner': '晚餐',
  'snack': '加餐'
};

const NUTRIENT_CONFIGS: NutrientConfig[] = [
  { name: '钠', unit: 'mg', color: '#EF5350', budgetKey: 'sodium' },
  { name: '糖', unit: 'g', color: '#FFA726', budgetKey: 'sugar' },
  { name: '热量', unit: 'kcal', color: '#66BB6A', budgetKey: 'calorie' },
  { name: '脂肪', unit: 'g', color: '#9C27B0', budgetKey: 'fat' }
];

interface NutrientConfig {
  name: string;
  unit: string;
  color: string;
  budgetKey: string;
}

export class NutritionTrendEngine implements INutritionTrendCalculator {

  aggregateDaily(records: DietRecord[]): DailyNutritionSummary[] {
    const map: Map<string, DailyNutritionSummary> = new Map();

    for (let i = 0; i < records.length; i++) {
      const r = records[i];
      let summary = map.get(r.date);
      if (summary === undefined) {
        summary = new DailyNutritionSummary();
        summary.date = r.date;
        map.set(r.date, summary);
      }
      summary.sodium += r.sodiumIntake;
      summary.sugar += r.sugarIntake;
      summary.calorie += r.calorieIntake;
      summary.fat += r.fatIntake;
      summary.recordCount++;
    }
    return Array.from(map.values()).sort((a, b) => a.date.localeCompare(b.date));
  }

  static computeTrend(values: number[]): TrendDirection {
    if (values.length < 3) return TrendDirection.STABLE;

    const recent3 = values.slice(-3);
    const prev3 = values.slice(-6, -3);

    if (recent3.length < 2 || prev3.length < 2) return TrendDirection.STABLE;

    let recentAvg = 0;
    for (let i = 0; i < recent3.length; i++) {
      recentAvg += recent3[i];
    }
    recentAvg /= recent3.length;

    let prevAvg = 0;
    for (let i = 0; i < prev3.length; i++) {
      prevAvg += prev3[i];
    }
    prevAvg /= prev3.length;

    const change = prevAvg === 0 ? 1 : (recentAvg - prevAvg) / prevAvg;
    if (change > 0.15) return TrendDirection.UP;
    if (change < -0.15) return TrendDirection.DOWN;
    return TrendDirection.STABLE;
  }

  buildNutrientTrends(dailySummaries: DailyNutritionSummary[],
    targetSodium: number, targetSugar: number, targetCalorie: number, targetFat: number): NutrientTrendData[] {

    const result: NutrientTrendData[] = [];
    const targets = [targetSodium, targetSugar, targetCalorie, targetFat];

    for (let ni = 0; ni < NUTRIENT_CONFIGS.length; ni++) {
      const cfg = NUTRIENT_CONFIGS[ni];
      const points: DailyNutrientPoint[] = [];
      const values: number[] = [];

      for (let di = 0; di < dailySummaries.length; di++) {
        const day = dailySummaries[di];
        let val = 0;
        if (cfg.budgetKey === 'sodium') val = day.sodium;
        else if (cfg.budgetKey === 'sugar') val = day.sugar;
        else if (cfg.budgetKey === 'calorie') val = day.calorie;
        else if (cfg.budgetKey === 'fat') val = day.fat;

        points.push({ date: day.date, value: val });
        values.push(val);
      }

      const data = new NutrientTrendData();
      data.nutrientName = cfg.name;
      data.unit = cfg.unit;
      data.color = cfg.color;
      data.dailyValues = points;
      data.targetValue = targets[ni];
      data.trend = NutritionTrendEngine.computeTrend(values);

      if (values.length > 0) {
        data.currentValue = values[values.length - 1];
      }

      let maxVal = targets[ni];
      for (let vi = 0; vi < values.length; vi++) {
        if (values[vi] > maxVal) maxVal = values[vi];
      }
      data.maxValue = Math.max(maxVal * 1.2, targets[ni]);

      result.push(data);
    }
    return result;
  }

  groupByMealType(records: DietRecord[]): MealGroup[] {
    const map: Map<string, DietRecord[]> = new Map();
    map.set('breakfast', []);
    map.set('lunch', []);
    map.set('dinner', []);
    map.set('snack', []);

    for (let i = 0; i < records.length; i++) {
      const r = records[i];
      const mt = r.mealType;
      let group = map.get(mt);
      if (group === undefined) {
        group = [];
        map.set(mt, group);
      }
      group.push(r);
    }

    const result: MealGroup[] = [];
    const mealOrder = ['breakfast', 'lunch', 'dinner', 'snack'];
    for (let mi = 0; mi < mealOrder.length; mi++) {
      const key = mealOrder[mi];
      const groupRecords = map.get(key) || [];
      if (groupRecords.length === 0) continue;

      let sodiumTotal = 0;
      let sugarTotal = 0;
      let calorieTotal = 0;
      let fatTotal = 0;
      for (let ri = 0; ri < groupRecords.length; ri++) {
        const r = groupRecords[ri];
        sodiumTotal += r.sodiumIntake;
        sugarTotal += r.sugarIntake;
        calorieTotal += r.calorieIntake;
        fatTotal += r.fatIntake;
      }

      const mg = new MealGroup();
      mg.mealType = key;
      mg.mealLabel = MEAL_LABELS[key] || key;
      mg.records = groupRecords;
      mg.sodiumTotal = sodiumTotal;
      mg.sugarTotal = sugarTotal;
      mg.calorieTotal = calorieTotal;
      mg.fatTotal = fatTotal;
      result.push(mg);
    }
    return result;
  }

  static getMealLabel(mealType: string): string {
    return MEAL_LABELS[mealType] || mealType;
  }
}

export const nutritionTrendEngine: NutritionTrendEngine = new NutritionTrendEngine();
