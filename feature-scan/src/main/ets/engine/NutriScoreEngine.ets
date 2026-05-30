// NutriScoreEngine.ets
// 营养评分引擎 - 根据食品营养标签计算0-100综合评分
// 评分模型基于中国居民膳食营养素参考摄入量（DRIs 2023）
// 参考Nutri-Score算法思路，调整权重适应中国标准

import { NutritionPer100g, NutritionThreshold } from 'hsp_core';

/**
 * 评分营养数据
 */
export class NutriScoreInput {
  calories: number = 0;
  sugar: number = 0;
  sodium: number = 0;
  fat: number = 0;
  saturatedFat: number = 0;
  protein: number = 0;
  fiber: number = 0;

  constructor(calories: number, sugar: number, sodium: number, fat: number,
    saturatedFat: number, protein: number, fiber: number) {
    this.calories = calories;
    this.sugar = sugar;
    this.sodium = sodium;
    this.fat = fat;
    this.saturatedFat = saturatedFat;
    this.protein = protein;
    this.fiber = fiber;
  }
}

/**
 * 评分详细分解
 */
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

  constructor(totalScore: number, grade: string, colorHex: string,
    penaltyCalories: number, penaltySugar: number, penaltySodium: number,
    penaltyFat: number, penaltySaturatedFat: number, bonusProtein: number, bonusFiber: number) {
    this.totalScore = totalScore;
    this.grade = grade;
    this.colorHex = colorHex;
    this.penaltyCalories = penaltyCalories;
    this.penaltySugar = penaltySugar;
    this.penaltySodium = penaltySodium;
    this.penaltyFat = penaltyFat;
    this.penaltySaturatedFat = penaltySaturatedFat;
    this.bonusProtein = bonusProtein;
    this.bonusFiber = bonusFiber;
  }
}

/**
 * 评分等级配置
 */
class ScoreGrade {
  minScore: number = 0;
  grade: string = '';
  color: string = '';
  label: string = '';

  constructor(minScore: number, grade: string, color: string, label: string) {
    this.minScore = minScore;
    this.grade = grade;
    this.color = color;
    this.label = label;
  }
}

const SCORE_GRADES: ScoreGrade[] = [
  new ScoreGrade(80, 'A', '#4CAF50', '优秀'),
  new ScoreGrade(60, 'B', '#66BB6A', '良好'),
  new ScoreGrade(40, 'C', '#FFA726', '一般'),
  new ScoreGrade(20, 'D', '#FF7043', '较差'),
  new ScoreGrade(0, 'E', '#F44336', '避免')
];

/**
 * 获取评分等级
 */
function getGrade(score: number): ScoreGrade {
  for (const grade of SCORE_GRADES) {
    if (score >= grade.minScore) {
      return grade;
    }
  }
  return SCORE_GRADES[SCORE_GRADES.length - 1];
}

/**
 * NutriScore营养评级引擎
 *
 * 实现中国居民膳食营养素参考摄入量（DRIs 2023）评分模型，
 * 参考Nutri-Score算法思路，调整权重适应中国标准。
 * 评分范围0-100，等级A(≥80)~E(<20)。
 *
 * @since 1.0.0
 */
export class NutriScoreEngine {
  /**
   * 计算综合营养评分（0-100）
   *
   * 算法思路：
   * - 扣分项：高能量、高糖、高钠、高饱和脂肪
   * - 加分项：高蛋白质、高膳食纤维
   * - 基础分100，扣分上限80，加分上限20
   *
   * @param input - 每100g营养成分数据
   * @returns 评分分解详情，包含总分、等级(A~E)及各项扣分/加分明细
   *
   * @example
   * ```typescript
   * const input = new NutriScoreInput(200, 5, 120, 3, 1.5, 10, 6);
   * const result = NutriScoreEngine.calculateScore(input);
   * console.log(result.grade); // 'A' | 'B' | 'C' | 'D' | 'E'
   * ```
   */
  static calculateScore(input: NutriScoreInput): NutriScoreBreakdown {
    // ---- 扣分计算 ----
    const penaltyCalories = NutriScoreEngine.calcCaloriePenalty(input.calories);
    const penaltySugar = NutriScoreEngine.calcSugarPenalty(input.sugar);
    const penaltySodium = NutriScoreEngine.calcSodiumPenalty(input.sodium);
    const penaltyFat = NutriScoreEngine.calcFatPenalty(input.fat);
    const penaltySaturatedFat = NutriScoreEngine.calcSaturatedFatPenalty(input.saturatedFat);

    const totalPenalty = Math.min(80, penaltyCalories + penaltySugar + penaltySodium
      + penaltyFat + penaltySaturatedFat);

    // ---- 加分计算 ----
    const bonusProtein = NutriScoreEngine.calcProteinBonus(input.protein);
    const bonusFiber = NutriScoreEngine.calcFiberBonus(input.fiber);

    const totalBonus = Math.min(20, bonusProtein + bonusFiber);

    // ---- 综合评分 ----
    let totalScore = 100 - totalPenalty + totalBonus;
    totalScore = Math.max(0, Math.min(100, Math.round(totalScore)));

    const gradeInfo = getGrade(totalScore);

    return new NutriScoreBreakdown(
      totalScore,
      gradeInfo.grade,
      gradeInfo.color,
      penaltyCalories,
      penaltySugar,
      penaltySodium,
      penaltyFat,
      penaltySaturatedFat,
      bonusProtein,
      bonusFiber
    );
  }

  /**
   * 从FoodLabel的NutritionPer100g计算评分
   *
   * @param nutrition - 每100g营养成分（来自FoodLabel）
   * @returns 评分分解详情
   */
  static calculateFromNutrition(nutrition: NutritionPer100g): NutriScoreBreakdown {
    const input = new NutriScoreInput(
      nutrition.calories,
      nutrition.sugar,
      nutrition.sodium,
      nutrition.fat,
      nutrition.saturatedFat,
      nutrition.protein,
      nutrition.fiber ?? 0
    );
    return NutriScoreEngine.calculateScore(input);
  }

  /**
   * 获取评分等级文字
   *
   * @param score - 营养评分(0-100)
   * @returns 等级中文标签，如'优秀'、'良好'、'一般'、'较差'、'避免'
   */
  static getGradeLabel(score: number): string {
    return getGrade(score).label;
  }

  /**
   * 获取评分等级颜色
   *
   * @param score - 营养评分(0-100)
   * @returns 等级对应颜色HEX值，如'#4CAF50'(A)~'#F44336'(E)
   */
  static getGradeColor(score: number): string {
    return getGrade(score).color;
  }

  // ==================== 内部扣分/加分算法 ====================

  /**
   * 能量扣分（kcal/100g）
   * ≤40kcal: 0分, 每增加40kcal扣1分, 上限20分
   */
  private static calcCaloriePenalty(calories: number): number {
    if (calories <= 40) return 0;
    const penalty = Math.floor((calories - 40) / 40);
    return Math.min(20, penalty);
  }

  /**
   * 糖扣分（g/100g）
   * ≤5g: 0分, 每增加2g扣1分, 上限15分
   */
  private static calcSugarPenalty(sugar: number): number {
    if (sugar <= 5) return 0;
    const penalty = Math.floor((sugar - 5) / 2);
    return Math.min(15, penalty);
  }

  /**
   * 钠扣分（mg/100g）
   * ≤120mg: 0分, 每增加50mg扣1分, 上限20分
   */
  private static calcSodiumPenalty(sodium: number): number {
    if (sodium <= 120) return 0;
    const penalty = Math.floor((sodium - 120) / 50);
    return Math.min(20, penalty);
  }

  /**
   * 脂肪扣分（g/100g）
   * ≤3g: 0分, 每增加1g扣1分, 上限15分
   */
  private static calcFatPenalty(fat: number): number {
    if (fat <= 3) return 0;
    const penalty = Math.floor(fat - 3);
    return Math.min(15, penalty);
  }

  /**
   * 饱和脂肪扣分（g/100g）
   * ≤1.5g: 0分, 每增加0.5g扣1分, 上限10分
   */
  private static calcSaturatedFatPenalty(saturatedFat: number): number {
    if (saturatedFat <= 1.5) return 0;
    const penalty = Math.floor((saturatedFat - 1.5) / 0.5);
    return Math.min(10, penalty);
  }

  /**
   * 蛋白质加分（g/100g）
   * ≥6g: 加3分, ≥10g: 加5分, ≥20g: 加8分
   */
  private static calcProteinBonus(protein: number): number {
    if (protein >= NutritionThreshold.PROTEIN_BONUS_THRESHOLD) return 8;
    if (protein >= 10) return 5;
    if (protein >= 6) return 3;
    return 0;
  }

  /**
   * 膳食纤维加分（g/100g）
   * ≥3g: 加2分, ≥6g: 加4分, ≥10g: 加6分
   */
  private static calcFiberBonus(fiber: number): number {
    if (fiber >= 10) return 6;
    if (fiber >= 6) return 4;
    if (fiber >= 3) return 2;
    return 0;
  }
}
