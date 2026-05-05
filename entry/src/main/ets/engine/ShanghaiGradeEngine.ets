// ShanghaiGradeEngine.ets
// 上海卫健委营养分级引擎 - 实现A/B/C/D四级分级标准
// 参考《上海市食品营养分级标准》试行版（沪卫食品〔2023〕X号）
// 分级依据：每100g/ml中能量、脂肪、糖、钠的综合判定

import { NutritionPer100g } from '../model/FoodLabel';

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
export interface ShanghaiGradeResult {
  grade: ShanghaiGrade;
  gradeLabel: string;     // 中文标签
  gradeColor: string;     // 颜色
  score: number;          // 内部评分 0-100
  energyLevel: string;    // 能量等级
  fatLevel: string;       // 脂肪等级
  sugarLevel: string;     // 糖等级
  sodiumLevel: string;    // 钠等级
  details: string;        // 说明文字
}

/**
 * 单项等级
 */
interface NutrientLevel {
  level: string;     // 优/良/中/差
  score: number;     // 单项得分 0-25
  grade: ShanghaiGrade;
}

/**
 * 分级阈值配置
 */
interface GradeThreshold {
  energy_kcal: number;
  fat_g: number;
  sugar_g: number;
  sodium_mg: number;
}

/**
 * 各等级阈值（每100g）
 * A级四项均需满足A级条件
 */
const GRADE_THRESHOLDS: Record<string, GradeThreshold> = {
  'A':  { energy_kcal: 40,  fat_g: 1.5, sugar_g: 5,   sodium_mg: 120 },
  'B':  { energy_kcal: 120, fat_g: 5,   sugar_g: 12,  sodium_mg: 400 },
  'C':  { energy_kcal: 250, fat_g: 10,  sugar_g: 20,  sodium_mg: 700 },
  'D':  { energy_kcal: 9999, fat_g: 999, sugar_g: 999, sodium_mg: 9999 }
};

/**
 * 各等级显示信息
 */
const GRADE_DISPLAY: Record<string, { label: string; color: string; score: number }> = {
  'A': { label: '优', color: '#4CAF50', score: 90 },
  'B': { label: '良', color: '#66BB6A', score: 70 },
  'C': { label: '中', color: '#FFA726', score: 45 },
  'D': { label: '差', color: '#F44336', score: 15 }
};

/**
 * 获取单项营养等级（简化的比较逻辑）
 */
function getSimpleNutrientLevel(value: number, thresholds: GradeThreshold, 
  key: keyof GradeThreshold): NutrientLevel {
  if (value <= thresholds[key]) {
    return { level: '优', score: 25, grade: ShanghaiGrade.GRADE_A };
  }
  
  const bThresholds = GRADE_THRESHOLDS.B;
  if (value <= bThresholds[key]) {
    return { level: '良', score: 20, grade: ShanghaiGrade.GRADE_B };
  }
  
  const cThresholds = GRADE_THRESHOLDS.C;
  if (value <= cThresholds[key]) {
    return { level: '中', score: 10, grade: ShanghaiGrade.GRADE_C };
  }
  
  return { level: '差', score: 5, grade: ShanghaiGrade.GRADE_D };
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
    const energyLevel = getSimpleNutrientLevel(nutrition.calories, GRADE_THRESHOLDS.A, 'energy_kcal');
    const fatLevel = getSimpleNutrientLevel(nutrition.fat, GRADE_THRESHOLDS.A, 'fat_g');
    const sugarLevel = getSimpleNutrientLevel(nutrition.sugar, GRADE_THRESHOLDS.A, 'sugar_g');
    const sodiumLevel = getSimpleNutrientLevel(nutrition.sodium, GRADE_THRESHOLDS.A, 'sodium_mg');

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

    const display = GRADE_DISPLAY[finalGrade];
    
    // 内部综合评分 = 四项得分之和（每项满分25）
    const totalScore = Math.min(100, energyLevel.score + fatLevel.score + sugarLevel.score + sodiumLevel.score);

    // 生成说明文字
    const details = ShanghaiGradeEngine.buildDetails(finalGrade, nutrition);

    return {
      grade: finalGrade,
      gradeLabel: display.label,
      gradeColor: display.color,
      score: totalScore,
      energyLevel: energyLevel.level,
      fatLevel: fatLevel.level,
      sugarLevel: sugarLevel.level,
      sodiumLevel: sodiumLevel.level,
      details: details
    };
  }

  /**
   * 从NutriScoreEngine的结果中获取近似的上海分级
   * 用于数据不足时的估算
   */
  static estimateFromScore(nutriScore: number): ShanghaiGrade {
    if (nutriScore >= 80) return ShanghaiGrade.GRADE_A;
    if (nutriScore >= 60) return ShanghaiGrade.GRADE_B;
    if (nutriScore >= 40) return ShanghaiGrade.GRADE_C;
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
    
    if (nutrition.calories > GRADE_THRESHOLDS.C.energy_kcal) {
      parts.push(`能量偏高（${nutrition.calories}kcal）`);
    }
    if (nutrition.fat > GRADE_THRESHOLDS.C.fat_g) {
      parts.push(`脂肪偏高（${nutrition.fat}g）`);
    }
    if (nutrition.sugar > GRADE_THRESHOLDS.C.sugar_g) {
      parts.push(`糖偏高（${nutrition.sugar}g）`);
    }
    if (nutrition.sodium > GRADE_THRESHOLDS.C.sodium_mg) {
      parts.push(`钠偏高（${nutrition.sodium}mg）`);
    }

    if (parts.length === 0) {
      return ShanghaiGradeEngine.getGradeDescription(grade);
    }

    return `综合评级${grade}：` + parts.join('，') + '，建议适量食用';
  }
}
