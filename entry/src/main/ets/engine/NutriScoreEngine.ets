// NutriScoreEngine.ets
// 营养评分引擎 - 根据食品营养标签计算0-100综合评分
// 评分模型基于中国居民膳食营养素参考摄入量（DRIs 2023）
// 参考Nutri-Score算法思路，调整权重适应中国标准

import { NutritionPer100g } from '../model/FoodLabel';

/**
 * 评分营养数据接口
 */
export interface NutriScoreInput {
  calories: number;      // 能量（kcal/100g）
  sugar: number;         // 糖（g/100g）
  sodium: number;        // 钠（mg/100g）
  fat: number;           // 脂肪（g/100g）
  saturatedFat: number;  // 饱和脂肪（g/100g）
  protein: number;       // 蛋白质（g/100g）
  fiber: number;         // 膳食纤维（g/100g，可选）
}

/**
 * 评分详细分解
 */
export interface NutriScoreBreakdown {
  totalScore: number;     // 综合评分 0-100
  grade: string;          // A/B/C/D/E
  colorHex: string;       // 对应颜色值
  penaltyCalories: number; // 能量扣分
  penaltySugar: number;    // 糖扣分
  penaltySodium: number;   // 钠扣分
  penaltyFat: number;      // 脂肪扣分
  penaltySaturatedFat: number; // 饱和脂肪扣分
  bonusProtein: number;    // 蛋白质加分
  bonusFiber: number;      // 膳食纤维加分
}

/**
 * 评分等级配置
 */
interface ScoreGrade {
  minScore: number;
  grade: string;
  color: string;
  label: string;
}

const SCORE_GRADES: ScoreGrade[] = [
  { minScore: 80, grade: 'A', color: '#4CAF50', label: '优秀' },
  { minScore: 60, grade: 'B', color: '#66BB6A', label: '良好' },
  { minScore: 40, grade: 'C', color: '#FFA726', label: '一般' },
  { minScore: 20, grade: 'D', color: '#FF7043', label: '较差' },
  { minScore: 0, grade: 'E', color: '#F44336', label: '避免' }
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

export class NutriScoreEngine {
  /**
   * 计算综合营养评分（0-100）
   * 
   * 算法思路：
   * - 扣分项：高能量、高糖、高钠、高饱和脂肪
   * - 加分项：高蛋白质、高膳食纤维
   * - 基础分100，扣分上限80，加分上限20
   * 
   * @param input 营养数据
   * @returns 评分分解详情
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

    return {
      totalScore: totalScore,
      grade: gradeInfo.grade,
      colorHex: gradeInfo.color,
      penaltyCalories: penaltyCalories,
      penaltySugar: penaltySugar,
      penaltySodium: penaltySodium,
      penaltyFat: penaltyFat,
      penaltySaturatedFat: penaltySaturatedFat,
      bonusProtein: bonusProtein,
      bonusFiber: bonusFiber
    };
  }

  /**
   * 从FoodLabel的NutritionPer100g计算评分
   */
  static calculateFromNutrition(nutrition: NutritionPer100g): NutriScoreBreakdown {
    const input: NutriScoreInput = {
      calories: nutrition.calories,
      sugar: nutrition.sugar,
      sodium: nutrition.sodium,
      fat: nutrition.fat,
      saturatedFat: nutrition.saturatedFat,
      protein: nutrition.protein,
      fiber: 0 // 膳食纤维通常不在基础营养表中
    };
    return NutriScoreEngine.calculateScore(input);
  }

  /**
   * 获取评分等级文字
   */
  static getGradeLabel(score: number): string {
    return getGrade(score).label;
  }

  /**
   * 获取评分等级颜色
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
    if (protein >= 20) return 8;
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
