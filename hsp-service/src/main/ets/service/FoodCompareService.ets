import { FoodLabel, NutritionPer100g, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'FoodCompareService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface FoodCompareResult {
  foodA: FoodLabel;
  foodB: FoodLabel;
  delta: NutritionDelta;
  winner: 'A' | 'B' | 'tie';
  verdict: string;
}

export interface NutritionDelta {
  calories: number;
  sugar: number;
  sodium: number;
  fat: number;
  protein: number;
  fiber: number;
}

export class FoodCompareService {
  compare(foodA: FoodLabel, foodB: FoodLabel): FoodCompareResult {
    const delta: NutritionDelta = {
      calories: foodB.nutrition.calories - foodA.nutrition.calories,
      sugar: foodB.nutrition.sugar - foodA.nutrition.sugar,
      sodium: foodB.nutrition.sodium - foodA.nutrition.sodium,
      fat: foodB.nutrition.fat - foodA.nutrition.fat,
      protein: foodB.nutrition.protein - foodA.nutrition.protein,
      fiber: foodB.nutrition.fiber - foodA.nutrition.fiber
    };

    const scoreA = this.heuristicScore(foodA);
    const scoreB = this.heuristicScore(foodB);

    const winner: 'A' | 'B' | 'tie' = scoreA > scoreB ? 'A' : scoreB > scoreA ? 'B' : 'tie';
    const verdict = winner === 'A'
      ? `${foodA.foodName} 营养更优（${scoreA}分 vs ${scoreB}分）`
      : winner === 'B'
      ? `${foodB.foodName} 营养更优（${scoreB}分 vs ${scoreA}分）`
      : '两者营养评分相当';

    return { foodA, foodB, delta, winner, verdict };
  }

  private heuristicScore(food: FoodLabel): number {
    let score = 50;
    score -= Math.min(food.nutrition.sodium / 20, 20);
    score -= Math.min(food.nutrition.sugar / 2, 15);
    score -= Math.min(food.nutrition.fat / 3, 10);
    score += Math.min(food.nutrition.protein / 2, 15);
    score += Math.min(food.nutrition.fiber * 3, 10);
    return Math.max(0, Math.min(100, Math.round(score)));
  }

  compareMultiple(foodA: FoodLabel, candidates: FoodLabel[]): FoodCompareResult[] {
    return candidates.map(c => this.compare(foodA, c));
  }

  findBestAlternative(foodA: FoodLabel, candidates: FoodLabel[]): FoodLabel | null {
    if (candidates.length === 0) return null;
    const results = this.compareMultiple(foodA, candidates);
    const betterResults = results.filter(r => r.winner === 'B');
    if (betterResults.length === 0) return null;
    return betterResults.reduce((best, curr) =>
      this.heuristicScore(curr.foodB) > this.heuristicScore(best.foodB) ? curr : best
    ).foodB;
  }
}
