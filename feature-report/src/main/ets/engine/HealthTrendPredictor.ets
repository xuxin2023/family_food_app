// HealthTrendPredictor.ets
// 健康趋势预测引擎 — 基于历史数据使用简单线性回归预测未来趋势

import { DailyNutritionSummary } from './NutritionTrendEngine';
import { NutritionTarget } from 'hsp_core';

export class TrendPrediction {
  nutrient: string = '';
  currentValue: number = 0;
  predictedValue: number = 0;
  trend: string = 'stable';
  confidence: number = 0;
  advice: string = '';
  unit: string = '';
}

export class HealthTrendPredictor {
  predict(
    dailySummaries: DailyNutritionSummary[],
    target: NutritionTarget
  ): TrendPrediction[] {
    if (dailySummaries.length < 7) {
      return [];
    }

    const predictions: TrendPrediction[] = [];

    const sodiumValues = dailySummaries.map(s => s.sodium);
    const sugarValues = dailySummaries.map(s => s.sugar);
    const calorieValues = dailySummaries.map(s => s.calorie);
    const fatValues = dailySummaries.map(s => s.fat);

    predictions.push(this.predictNutrient('钠', 'mg', sodiumValues, target.sodiumMax_mg, true));
    predictions.push(this.predictNutrient('糖', 'g', sugarValues, target.sugarMax_g, true));
    predictions.push(this.predictNutrient('热量', 'kcal', calorieValues, target.caloriesTarget, false));
    predictions.push(this.predictNutrient('脂肪', 'g', fatValues, target.fatMax_g, true));

    return predictions;
  }

  private predictNutrient(
    name: string,
    unit: string,
    values: number[],
    targetValue: number,
    isUpperLimit: boolean
  ): TrendPrediction {
    const p: TrendPrediction = new TrendPrediction()
    p.nutrient = name;
    p.unit = unit;

    const len = values.length;
    if (len === 0) {
      p.currentValue = 0;
      p.predictedValue = 0;
      p.trend = 'stable';
      p.confidence = 0;
      p.advice = '';
      return p;
    }

    p.currentValue = values[len - 1];

    if (len < 7) {
      p.predictedValue = p.currentValue;
      p.trend = 'stable';
      p.confidence = 0;
      p.advice = '';
      return p;
    }

    if (targetValue <= 0) {
      p.predictedValue = p.currentValue;
      p.trend = 'stable';
      p.confidence = 0;
      p.advice = '';
      return p;
    }

    const recent7 = values.slice(-7);
    let recentAvg = 0;
    for (let i = 0; i < recent7.length; i++) {
      recentAvg += recent7[i];
    }
    recentAvg /= recent7.length;

    let prev7: number[] = [];
    if (len >= 14) {
      prev7 = values.slice(-14, -7);
    } else {
      prev7 = values.slice(0, Math.min(7, len - 7));
    }

    if (prev7.length === 0) {
      p.predictedValue = p.currentValue;
      p.trend = 'stable';
      p.confidence = 0;
      p.advice = '';
      return p;
    }

    let prevAvg = 0;
    for (let i = 0; i < prev7.length; i++) {
      prevAvg += prev7[i];
    }
    prevAvg /= prev7.length;

    const changeRate = prevAvg === 0 ? 0 : (recentAvg - prevAvg) / prevAvg;

    if (changeRate > 0.1) {
      p.trend = 'up';
    } else if (changeRate < -0.1) {
      p.trend = 'down';
    } else {
      p.trend = 'stable';
    }

    p.predictedValue = Math.max(0, recentAvg * (1 + changeRate));

    p.confidence = Math.min(1.0, len / 21);
    if (len >= 14) {
      p.confidence = Math.min(1.0, 0.7 + (len - 14) * 0.02);
    }

    p.advice = this.generateAdvice(name, unit, p, targetValue, isUpperLimit);

    return p;
  }

  private generateAdvice(
    name: string,
    unit: string,
    prediction: TrendPrediction,
    targetValue: number,
    isUpperLimit: boolean
  ): string {
    if (isUpperLimit) {
      if (prediction.trend === 'up' && prediction.predictedValue > targetValue) {
        const overPct = Math.round(((prediction.predictedValue - targetValue) / targetValue) * 100);
        return `${name}摄入呈上升趋势，预计下周将超标${overPct}%，建议从今天开始控制${name}摄入`;
      }
      if (prediction.trend === 'up' && prediction.currentValue > targetValue * 0.8) {
        return `${name}摄入接近上限且呈上升趋势，建议适当控制`;
      }
      if (prediction.trend === 'down' && prediction.currentValue > targetValue) {
        return `${name}摄入虽超标但呈下降趋势，继续保持控量`;
      }
      if (prediction.trend === 'stable' && prediction.currentValue > targetValue) {
        return `${name}摄入持续超标，建议积极调整饮食`;
      }
    } else {
      if (prediction.trend === 'down' && prediction.predictedValue < targetValue * 0.7) {
        return `${name}摄入呈下降趋势，预计下周将低于目标的70%，建议适当补充`;
      }
      if (prediction.trend === 'up' && prediction.currentValue > targetValue * 1.1) {
        return `${name}摄入偏高且呈上升趋势，建议适当控制`;
      }
    }

    return '';
  }
}
