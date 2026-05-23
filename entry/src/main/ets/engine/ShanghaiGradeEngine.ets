// ShanghaiGradeEngine.ets
// 上海卫健委营养分级引擎 - 实现A/B/C/D四级分级标准
// 参考《上海市食品营养分级标准》试行版（沪卫食品〔2023〕X号）
// 分级依据：每100g/ml中能量、脂肪、糖、钠的综合判定

import { NutritionPer100g, NutritionThreshold } from 'hsp_core';

/**
 * 上海营养分级
 */
export enum ShanghaiGrade {
  GRADE_A = 'A',
  GRADE_B = 'B',
  GRADE_C = 'C',
  GRADE_D = 'D'
}

/**
 * 分级结果
 */
export class ShanghaiGradeResult {
  grade: ShanghaiGrade = ShanghaiGrade.GRADE_A;
  gradeLabel: string = '';
  gradeColor: string = '';
  score: number = 0;
  energyLevel: string = '';
  fatLevel: string = '';
  sugarLevel: string = '';
  sodiumLevel: string = '';
  details: string = '';

  constructor(grade: ShanghaiGrade, gradeLabel: string, gradeColor: string, score: number,
    energyLevel: string, fatLevel: string, sugarLevel: string, sodiumLevel: string, details: string) {
    this.grade = grade;
    this.gradeLabel = gradeLabel;
    this.gradeColor = gradeColor;
    this.score = score;
    this.energyLevel = energyLevel;
    this.fatLevel = fatLevel;
    this.sugarLevel = sugarLevel;
    this.sodiumLevel = sodiumLevel;
    this.details = details;
  }
}

/**
 * 单项等级
 */
class NutrientLevel {
  level: string = '';
  score: number = 0;
  grade: ShanghaiGrade = ShanghaiGrade.GRADE_A;

  constructor(level: string, score: number, grade: ShanghaiGrade) {
    this.level = level;
    this.score = score;
    this.grade = grade;
  }
}

/**
 * 分级阈值配置
 */
class GradeThreshold {
  energy_kcal: number = 0;
  fat_g: number = 0;
  sugar_g: number = 0;
  sodium_mg: number = 0;

  constructor(energy_kcal: number, fat_g: number, sugar_g: number, sodium_mg: number) {
    this.energy_kcal = energy_kcal;
    this.fat_g = fat_g;
    this.sugar_g = sugar_g;
    this.sodium_mg = sodium_mg;
  }
}

/**
 * 等级显示信息
 */
class GradeDisplayEntry {
  label: string = '';
  color: string = '';
  score: number = 0;

  constructor(label: string, color: string, score: number) {
    this.label = label;
    this.color = color;
    this.score = score;
  }
}

/**
 * 各等级阈值（每100g）
 * A级四项均需满足A级条件
 */
const GRADE_THRESHOLDS: Map<string, GradeThreshold> = new Map();
GRADE_THRESHOLDS.set('A', new GradeThreshold(40, 1.5, 5, 120));
GRADE_THRESHOLDS.set('B', new GradeThreshold(120, 5, 12, 400));
GRADE_THRESHOLDS.set('C', new GradeThreshold(250, 10, 20, 700));
GRADE_THRESHOLDS.set('D', new GradeThreshold(9999, 999, 999, 9999));

/**
 * 各等级显示信息
 */
const GRADE_DISPLAY: Map<string, GradeDisplayEntry> = new Map();
GRADE_DISPLAY.set('A', new GradeDisplayEntry('优', '#4CAF50', 90));
GRADE_DISPLAY.set('B', new GradeDisplayEntry('良', '#66BB6A', 70));
GRADE_DISPLAY.set('C', new GradeDisplayEntry('中', '#FFA726', 45));
GRADE_DISPLAY.set('D', new GradeDisplayEntry('差', '#F44336', 15));

/**
 * 通过属性名获取阈值
 */
function getThresholdByKey(t: GradeThreshold, key: keyof GradeThreshold): number {
  if (key === 'energy_kcal') return t.energy_kcal;
  if (key === 'fat_g') return t.fat_g;
  if (key === 'sugar_g') return t.sugar_g;
  return t.sodium_mg;
}

/**
 * 获取单项营养等级（简化的比较逻辑）
 */
function getSimpleNutrientLevel(value: number, thresholds: GradeThreshold,
  key: keyof GradeThreshold): NutrientLevel {
  if (value <= getThresholdByKey(thresholds, key)) {
    return new NutrientLevel('优', 25, ShanghaiGrade.GRADE_A);
  }

  const bThresholds = GRADE_THRESHOLDS.get('B');
  if (bThresholds !== undefined && value <= getThresholdByKey(bThresholds, key)) {
    return new NutrientLevel('良', 20, ShanghaiGrade.GRADE_B);
  }

  const cThresholds = GRADE_THRESHOLDS.get('C');
  if (cThresholds !== undefined && value <= getThresholdByKey(cThresholds, key)) {
    return new NutrientLevel('中', 10, ShanghaiGrade.GRADE_C);
  }

  return new NutrientLevel('差', 5, ShanghaiGrade.GRADE_D);
}

export class ShanghaiGradeEngine {
  /**
   * 根据营养数据计算上海营养分级
   *
   * 规则：
   * - A级：能量≤40kcal、脂肪≤1.5g、糖≤5g、钠≤120mg 四项同时满足
   * - B级：能量≤120kcal、脂肪≤5g、糖≤12g、钠≤400mg 四项同时满足
   * - C级：能量≤250kcal、脂肪≤10g、糖≤20g、钠≤700mg 四项同时满足
   * - D级：任意一项超过C级阈值
   * 
   * @param nutrition 每100g营养数据
   * @returns 分级结果
   */
  static evaluate(nutrition: NutritionPer100g): ShanghaiGradeResult {
    // 评估四项指标分别落在哪个等级
    const aThresholds = GRADE_THRESHOLDS.get('A')!;
    const energyLevel = getSimpleNutrientLevel(nutrition.calories, aThresholds, 'energy_kcal');
    const fatLevel = getSimpleNutrientLevel(nutrition.fat, aThresholds, 'fat_g');
    const sugarLevel = getSimpleNutrientLevel(nutrition.sugar, aThresholds, 'sugar_g');
    const sodiumLevel = getSimpleNutrientLevel(nutrition.sodium, aThresholds, 'sodium_mg');

    // 综合等级 = 四项中最低等级
    const grades: ShanghaiGrade[] = [
      energyLevel.grade,
      fatLevel.grade,
      sugarLevel.grade,
      sodiumLevel.grade
    ];

    let finalGrade = ShanghaiGrade.GRADE_A;
    for (const g of grades) {
      if (g === ShanghaiGrade.GRADE_D) {
        finalGrade = ShanghaiGrade.GRADE_D;
        break;
      }
      if (g === ShanghaiGrade.GRADE_C) {
        finalGrade = ShanghaiGrade.GRADE_C;
      } else if (g === ShanghaiGrade.GRADE_B && finalGrade === ShanghaiGrade.GRADE_A) {
        finalGrade = ShanghaiGrade.GRADE_B;
      }
    }

    const display = GRADE_DISPLAY.get(finalGrade)!;

    // 内部综合评分 = 四项得分之和（每项满分25）
    const totalScore = Math.min(100, energyLevel.score + fatLevel.score + sugarLevel.score + sodiumLevel.score);

    // 生成说明文字
    const details = ShanghaiGradeEngine.buildDetails(finalGrade, nutrition);

    return new ShanghaiGradeResult(
      finalGrade,
      display.label,
      display.color,
      totalScore,
      energyLevel.level,
      fatLevel.level,
      sugarLevel.level,
      sodiumLevel.level,
      details
    );
  }

  /**
   * 从NutriScoreEngine的结果中获取近似的上海分级
   * 用于数据不足时的估算
   */
  static estimateFromScore(nutriScore: number): ShanghaiGrade {
    if (nutriScore >= NutritionThreshold.SCORE_THRESHOLD_A) return ShanghaiGrade.GRADE_A;
    if (nutriScore >= NutritionThreshold.SCORE_THRESHOLD_B) return ShanghaiGrade.GRADE_B;
    if (nutriScore >= NutritionThreshold.SCORE_THRESHOLD_C) return ShanghaiGrade.GRADE_C;
    return ShanghaiGrade.GRADE_D;
  }

  /**
   * 获取等级的中文描述
   */
  static getGradeDescription(grade: ShanghaiGrade): string {
    switch (grade) {
      case ShanghaiGrade.GRADE_A:
        return '该食品各项营养指标均较优，可放心食用';
      case ShanghaiGrade.GRADE_B:
        return '该食品营养指标整体良好，适量食用';
      case ShanghaiGrade.GRADE_C:
        return '该食品部分营养指标偏高，建议少量食用';
      case ShanghaiGrade.GRADE_D:
        return '该食品多项营养指标偏高，建议谨慎选择';
      default:
        return '';
    }
  }

  /**
   * 构建详细的评级说明
   */
  private static buildDetails(grade: ShanghaiGrade, nutrition: NutritionPer100g): string {
    const parts: string[] = [];
    const cThresholds = GRADE_THRESHOLDS.get('C')!;

    if (nutrition.calories > cThresholds.energy_kcal) {
      parts.push(`能量偏高（${nutrition.calories}kcal）`);
    }
    if (nutrition.fat > cThresholds.fat_g) {
      parts.push(`脂肪偏高（${nutrition.fat}g）`);
    }
    if (nutrition.sugar > cThresholds.sugar_g) {
      parts.push(`糖偏高（${nutrition.sugar}g）`);
    }
    if (nutrition.sodium > cThresholds.sodium_mg) {
      parts.push(`钠偏高（${nutrition.sodium}mg）`);
    }

    if (parts.length === 0) {
      return ShanghaiGradeEngine.getGradeDescription(grade);
    }

    return `综合评级${grade}：` + parts.join('，') + '，建议适量食用';
  }
}
