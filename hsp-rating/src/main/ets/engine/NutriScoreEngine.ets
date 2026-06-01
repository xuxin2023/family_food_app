// hsp-rating: Nutri-Score 营养评级引擎
// 基于中国居民膳食营养素参考摄入量（DRIs 2023）的评分模型
// 参考Nutri-Score算法思路，调整权重适应中国标准

import { FoodLabel, NutritionPer100g, NutritionThreshold, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NutriScoreEngine';

/** 评分输入 */
export class NutriScoreInput {
  calories: number = 0;
  sugar: number = 0;
  sodium: number = 0;
  fat: number = 0;
  saturatedFat: number = 0;
  protein: number = 0;
  fiber: number = 0;

  static fromNutrition(n: NutritionPer100g): NutriScoreInput {
    const input = new NutriScoreInput();
    input.calories = n.calories;
    input.sugar = n.sugar;
    input.sodium = n.sodium;
    input.fat = n.fat;
    input.saturatedFat = n.saturatedFat;
    input.protein = n.protein;
    input.fiber = n.fiber ?? 0;
    return input;
  }
}

/** 评分分解详情 */
export class NutriScoreBreakdown {
  totalScore: number = 0;
  grade: string = '';
  colorHex: string = '';
  penaltyCalories: number = 0;
  penaltySugar: number = 0;
  penaltySodium: number = 0;
  penaltyFat: number = 0;
  penaltySaturatedFat: number = 0;
  bonusProtein: number = 0;
  bonusFiber: number = 0;
}

interface GradeConfig {
  minScore: number;
  grade: string;
  color: string;
  label: string;
}

const SCORE_GRADES: GradeConfig[] = [
  { minScore: 80, grade: 'A', color: '#4CAF50', label: '优秀' },
  { minScore: 60, grade: 'B', color: '#66BB6A', label: '良好' },
  { minScore: 40, grade: 'C', color: '#FFA726', label: '一般' },
  { minScore: 20, grade: 'D', color: '#FF7043', label: '较差' },
  { minScore: 0, grade: 'E', color: '#F44336', label: '避免' }
];

function getGradeConfig(score: number): GradeConfig {
  for (const g of SCORE_GRADES) {
    if (score >= g.minScore) return g;
  }
  return SCORE_GRADES[SCORE_GRADES.length - 1];
}

export class NutriScoreEngine {
  /** 从 FoodLabel 计算 NutriScore 结果 */
  compute(food: FoodLabel): NutriScoreBreakdown {
    const input = NutriScoreInput.fromNutrition(food.nutrition);
    const result = NutriScoreEngine.calculateScore(input);
    hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'NutriScore computed: %{public}s (%{public}d/100) for %{public}s',
      result.grade, result.totalScore, food.foodName);
    return result;
  }

  /** 计算综合营养评分（0-100） */
  static calculateScore(input: NutriScoreInput): NutriScoreBreakdown {
    const penaltyCalories = NutriScoreEngine.calcCaloriePenalty(input.calories);
    const penaltySugar = NutriScoreEngine.calcSugarPenalty(input.sugar);
    const penaltySodium = NutriScoreEngine.calcSodiumPenalty(input.sodium);
    const penaltyFat = NutriScoreEngine.calcFatPenalty(input.fat);
    const penaltySaturatedFat = NutriScoreEngine.calcSaturatedFatPenalty(input.saturatedFat);
    const totalPenalty = Math.min(80, penaltyCalories + penaltySugar + penaltySodium +
      penaltyFat + penaltySaturatedFat);

    const bonusProtein = NutriScoreEngine.calcProteinBonus(input.protein);
    const bonusFiber = NutriScoreEngine.calcFiberBonus(input.fiber);
    const totalBonus = Math.min(20, bonusProtein + bonusFiber);

    let totalScore = Math.max(0, Math.min(100, Math.round(100 - totalPenalty + totalBonus)));
    const gradeCfg = getGradeConfig(totalScore);

    const breakdown = new NutriScoreBreakdown();
    breakdown.totalScore = totalScore;
    breakdown.grade = gradeCfg.grade;
    breakdown.colorHex = gradeCfg.color;
    breakdown.penaltyCalories = penaltyCalories;
    breakdown.penaltySugar = penaltySugar;
    breakdown.penaltySodium = penaltySodium;
    breakdown.penaltyFat = penaltyFat;
    breakdown.penaltySaturatedFat = penaltySaturatedFat;
    breakdown.bonusProtein = bonusProtein;
    breakdown.bonusFiber = bonusFiber;
    return breakdown;
  }

  static getGradeLabel(score: number): string {
    return getGradeConfig(score).label;
  }

  static getGradeColor(score: number): string {
    return getGradeConfig(score).color;
  }

  // ===== 扣分算法 =====
  private static calcCaloriePenalty(calories: number): number {
    if (calories <= 40) return 0;
    return Math.min(20, Math.floor((calories - 40) / 40));
  }

  private static calcSugarPenalty(sugar: number): number {
    if (sugar <= 5) return 0;
    return Math.min(15, Math.floor((sugar - 5) / 2));
  }

  private static calcSodiumPenalty(sodium: number): number {
    if (sodium <= 120) return 0;
    return Math.min(20, Math.floor((sodium - 120) / 50));
  }

  private static calcFatPenalty(fat: number): number {
    if (fat <= 3) return 0;
    return Math.min(15, Math.floor(fat - 3));
  }

  private static calcSaturatedFatPenalty(saturatedFat: number): number {
    if (saturatedFat <= 1.5) return 0;
    return Math.min(10, Math.floor((saturatedFat - 1.5) / 0.5));
  }

  // ===== 加分算法 =====
  private static calcProteinBonus(protein: number): number {
    if (protein >= NutritionThreshold.PROTEIN_BONUS_THRESHOLD) return 8;
    if (protein >= 10) return 5;
    if (protein >= 6) return 3;
    return 0;
  }

  private static calcFiberBonus(fiber: number): number {
    if (fiber >= 10) return 6;
    if (fiber >= 6) return 4;
    if (fiber >= 3) return 2;
    return 0;
  }
}
