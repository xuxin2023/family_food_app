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
    const input: NutriScoreInput = new NutriScoreInput()
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

/** 扣分上限: 单项最高扣分 */
const PENALTY_MAX_CALORIE = 20;
const PENALTY_MAX_SUGAR = 15;
const PENALTY_MAX_SODIUM = 20;
const PENALTY_MAX_FAT = 15;
const PENALTY_MAX_SATURATED_FAT = 10;
const PENALTY_TOTAL_MAX = 80;

/** 加分阈值: 蛋白质(g/100g) */
const PROTEIN_BONUS_HIGH = 20;
const PROTEIN_BONUS_MID = 10;
const PROTEIN_BONUS_LOW = 6;

/** 加分阈值: 膳食纤维(g/100g) */
const FIBER_BONUS_HIGH = 10;
const FIBER_BONUS_MID = 6;
const FIBER_BONUS_LOW = 3;

/** 加分上限 */
const BONUS_TOTAL_MAX = 20;

const SCORE_GRADES: GradeConfig[] = [
  { minScore: NutritionThreshold.SCORE_THRESHOLD_A, grade: 'A', color: '#4CAF50', label: '优秀' },
  { minScore: NutritionThreshold.SCORE_THRESHOLD_B, grade: 'B', color: '#66BB6A', label: '良好' },
  { minScore: NutritionThreshold.SCORE_THRESHOLD_C, grade: 'C', color: '#FFA726', label: '一般' },
  { minScore: NutritionThreshold.SCORE_THRESHOLD_D, grade: 'D', color: '#FF7043', label: '较差' },
  { minScore: 0, grade: 'E', color: '#F44336', label: '避免' }
];

function getGradeConfig(score: number): GradeConfig {
  for (const g of SCORE_GRADES) {
    if (score >= g.minScore) return g;
  }
  return SCORE_GRADES[SCORE_GRADES.length - 1];
}

/**
 * Nutri-Score 营养评分引擎
 *
 * 参考 Nutri-Score 五级评分体系，适配中国居民膳食营养素参考摄入量（DRIs 2023）。
 * 计算模型: 100 - 负向扣分(热量/糖/钠/脂肪/饱和脂肪) + 正向加分(蛋白质/膳食纤维)
 * 结果范围 0-100，映射 A(>=80) B(>=60) C(>=40) D(>=20) E(<20)
 */
export class NutriScoreEngine {
  /**
   * 从 FoodLabel 计算 NutriScore 综合评分
   * @param food - 食品标签(需含 nutrition 字段)
   * @returns 评分分解结果(总分/等级/颜色/各项得分)
   */
  compute(food: FoodLabel): NutriScoreBreakdown {
    const input = NutriScoreInput.fromNutrition(food.nutrition);
    const result = NutriScoreEngine.calculateScore(input);
    hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'NutriScore: %{public}s(%{public}d) for %{public}s',
      result.grade, result.totalScore, food.foodName);
    return result;
  }

  /**
   * 纯函数: 根据营养输入计算评分
   * @param input - 每100g营养成分
   * @returns 评分分解详情
   */
  static calculateScore(input: NutriScoreInput): NutriScoreBreakdown {
    const penaltyCalories = NutriScoreEngine.calcCaloriePenalty(input.calories);
    const penaltySugar = NutriScoreEngine.calcSugarPenalty(input.sugar);
    const penaltySodium = NutriScoreEngine.calcSodiumPenalty(input.sodium);
    const penaltyFat = NutriScoreEngine.calcFatPenalty(input.fat);
    const penaltySaturatedFat = NutriScoreEngine.calcSaturatedFatPenalty(input.saturatedFat);
    const totalPenalty = Math.min(PENALTY_TOTAL_MAX, penaltyCalories + penaltySugar +
      penaltySodium + penaltyFat + penaltySaturatedFat);

    const bonusProtein = NutriScoreEngine.calcProteinBonus(input.protein);
    const bonusFiber = NutriScoreEngine.calcFiberBonus(input.fiber);
    const totalBonus = Math.min(BONUS_TOTAL_MAX, bonusProtein + bonusFiber);

    let totalScore = Math.max(0, Math.min(100, Math.round(100 - totalPenalty + totalBonus)));
    const gradeCfg = getGradeConfig(totalScore);

    const breakdown: NutriScoreBreakdown = new NutriScoreBreakdown()
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

  /** 获取评分对应的中文标签(A→优秀, B→良好...) */
  static getGradeLabel(score: number): string {
    return getGradeConfig(score).label;
  }

  /** 获取评分对应的颜色十六进制码 */
  static getGradeColor(score: number): string {
    return getGradeConfig(score).color;
  }

  /** 热量扣分(每40kcal递增1分,上限20) */
  private static calcCaloriePenalty(calories: number): number {
    if (calories <= 40) return 0;
    return Math.min(PENALTY_MAX_CALORIE, Math.floor((calories - 40) / 40));
  }

  /** 糖扣分(每2g递增1分,上限15) */
  private static calcSugarPenalty(sugar: number): number {
    if (sugar <= 5) return 0;
    return Math.min(PENALTY_MAX_SUGAR, Math.floor((sugar - 5) / 2));
  }

  /** 钠扣分(每50mg递增1分,上限20) */
  private static calcSodiumPenalty(sodium: number): number {
    if (sodium <= 120) return 0;
    return Math.min(PENALTY_MAX_SODIUM, Math.floor((sodium - 120) / 50));
  }

  /** 脂肪扣分(每g递增1分,上限15) */
  private static calcFatPenalty(fat: number): number {
    if (fat <= 3) return 0;
    return Math.min(PENALTY_MAX_FAT, Math.floor(fat - 3));
  }

  /** 饱和脂肪扣分(每0.5g递增1分,上限10) */
  private static calcSaturatedFatPenalty(saturatedFat: number): number {
    if (saturatedFat <= 1.5) return 0;
    return Math.min(PENALTY_MAX_SATURATED_FAT, Math.floor((saturatedFat - 1.5) / 0.5));
  }

  /**
   * 蛋白质加分(三档)
   * >=20g/100g → +8分, >=10g → +5分, >=6g → +3分
   */
  private static calcProteinBonus(protein: number): number {
    if (protein >= PROTEIN_BONUS_HIGH) return 8;
    if (protein >= PROTEIN_BONUS_MID) return 5;
    if (protein >= PROTEIN_BONUS_LOW) return 3;
    return 0;
  }

  /**
   * 膳食纤维加分(三档)
   * >=10g/100g → +6分, >=6g → +4分, >=3g → +2分
   */
  private static calcFiberBonus(fiber: number): number {
    if (fiber >= FIBER_BONUS_HIGH) return 6;
    if (fiber >= FIBER_BONUS_MID) return 4;
    if (fiber >= FIBER_BONUS_LOW) return 2;
    return 0;
  }
}
