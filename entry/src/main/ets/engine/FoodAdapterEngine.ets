// FoodAdapterEngine.ets
// 动态适配矩阵V3 - 连续扫描递减、步数/睡眠精确影响、关联风险识别

import { FamilyMemberSimple, FoodNutrition, HealthSignal, EnhancedFoodRecommendation,
  RecommendationLevel, ParentPanelData, AgeSpecificAdvice } from '../model/FoodAdapterTypes';

/**
 * 高钠阈值（每100g钠含量mg）
 */
const HIGH_SODIUM_THRESHOLD: number = 500;

/**
 * 今日扫描记录（内存缓存，用于关联风险识别）
 */
interface ScanRecord {
  foodName: string;
  sodium_mg: number;
  sugar_g: number;
  energyKcal: number;
  fat_g: number;
}

/**
 * 全局扫描记录缓存，按memberId分组
 */
const scanHistoryCache: Map<string, ScanRecord[]> = new Map();

export class FoodAdapterEngine {
  /**
   * 动态适配矩阵计算
   * @param member 家庭成员简档
   * @param food 食品营养数据
   * @param healthSignal 当日健康信号
   * @param todayIntake 今日已摄入营养
   * @param scanIndex 当日第几次扫描（1-10）
   * @returns 增强版适配建议
   */
  static calculateDynamicIntake(
    member: FamilyMemberSimple,
    food: FoodNutrition,
    healthSignal: HealthSignal,
    todayIntake: TodayIntakeInput,
    scanIndex: number
  ): EnhancedFoodRecommendation {
    const result: EnhancedFoodRecommendation = {
      productName: food.productName,
      memberId: member.id,
      memberName: member.name,
      maxIntake_g: 0,
      level: RecommendationLevel.GREEN,
      levelText: '适合食用',
      reason: '',
      scanIndex: scanIndex
    };

    // 1. 基础预算计算（从成员预算获取）
    const baseSodiumBudget: number = member.dailyBudget.sodium_mg;
    const baseSugarBudget: number = member.dailyBudget.sugar_g;
    const baseCalorieBudget: number = member.dailyBudget.energy_kcal;
    const baseFatBudget: number = member.dailyBudget.fat_g;

    // 已摄入
    const consumedSodium: number = todayIntake.sodium_mg;
    const consumedSugar: number = todayIntake.sugar_g;
    const consumedCalorie: number = todayIntake.energy_kcal;
    const consumedFat: number = todayIntake.fat_g;

    // 2. 步数精确影响
    const stepAdjustment: number = FoodAdapterEngine.getStepAdjustment(healthSignal);
    let adjustedSodiumBudget: number = (baseSodiumBudget - consumedSodium) * stepAdjustment;
    let adjustedCalorieBudget: number = (baseCalorieBudget - consumedCalorie) * stepAdjustment;

    // 3. 睡眠精确影响
    const sleepAdjustment: number = FoodAdapterEngine.getSleepAdjustment(healthSignal, food);
    const adjustedSugarBudget: number = (baseSugarBudget - consumedSugar) * sleepAdjustment;
    const adjustedFatBudget: number = (baseFatBudget - consumedFat) * sleepAdjustment;

    // 4. 连续扫描递减
    const scanDecayFactor: number = FoodAdapterEngine.getScanDecayFactor(scanIndex);
    const finalSodiumBudget: number = adjustedSodiumBudget * scanDecayFactor;
    const finalSugarBudget: number = adjustedSugarBudget * scanDecayFactor;
    const finalCalorieBudget: number = adjustedCalorieBudget * scanDecayFactor;
    const finalFatBudget: number = adjustedFatBudget * scanDecayFactor;

    // 5. 记录本次扫描
    const todayRecords: ScanRecord[] = scanHistoryCache.get(member.id) || [];
    const newRecord: ScanRecord = {
      foodName: food.productName,
      sodium_mg: food.sodium_mg,
      sugar_g: food.sugar_g,
      energyKcal: Math.round(food.energy_kj / 4.184),
      fat_g: food.fat_g
    };
    todayRecords.push(newRecord);
    scanHistoryCache.set(member.id, todayRecords);

    // 6. 关联风险识别 - 高钠食品连续扫描
    let riskWarning: string = '';
    const highSodiumCount: number = todayRecords.filter(r => r.sodium_mg >= HIGH_SODIUM_THRESHOLD).length;
    if (highSodiumCount >= 2 && food.sodium_mg >= HIGH_SODIUM_THRESHOLD) {
      riskWarning = '今日钠摄入已偏高，这款建议跳过或极少量尝试';
    }

    // 7. 计算基于各营养素的建议量
    const foodSodiumPer100g: number = food.sodium_mg > 0 ? food.sodium_mg : 1;
    const foodSugarPer100g: number = food.sugar_g > 0 ? food.sugar_g : 1;
    const foodCaloriePer100g: number = (food.energy_kj / 4.184) > 0 ? (food.energy_kj / 4.184) : 1;
    const foodFatPer100g: number = food.fat_g > 0 ? food.fat_g : 1;

    const maxBySodium: number = (finalSodiumBudget / foodSodiumPer100g) * 100;
    const maxBySugar: number = (finalSugarBudget / foodSugarPer100g) * 100;
    const maxByCalorie: number = (finalCalorieBudget / foodCaloriePer100g) * 100;
    const maxByFat: number = (finalFatBudget / foodFatPer100g) * 100;

    let maxIntake: number = Math.min(maxBySodium, maxBySugar, maxByCalorie, maxByFat);
    if (maxIntake === Infinity || maxIntake < 0) {
      maxIntake = 100;
    }
    maxIntake = Math.round(Math.max(0, maxIntake));
    result.maxIntake_g = maxIntake;

    // 8. 确定等级
    if (maxIntake === 0) {
      result.level = RecommendationLevel.RED;
      result.levelText = '建议避免';
    } else if (maxIntake <= 15) {
      result.level = RecommendationLevel.ORANGE;
      result.levelText = '今天谨慎';
    } else if (maxIntake <= 50) {
      result.level = RecommendationLevel.YELLOW;
      result.levelText = '少量可以';
    } else {
      result.level = RecommendationLevel.GREEN;
      result.levelText = '适合食用';
    }

    // 9. 生成动态调整原因
    const reasons: string[] = [];
    if (stepAdjustment < 1.0) {
      const stepReduction: number = Math.round((1 - stepAdjustment) * 100);
      reasons.push(`因今日步数偏低，建议量比平时减少${stepReduction}%`);
    } else if (stepAdjustment > 1.0) {
      const stepBonus: number = Math.round((stepAdjustment - 1) * 100);
      reasons.push(`今日活动量充足，建议量比平时放宽${stepBonus}%`);
    }
    if (sleepAdjustment < 1.0) {
      const sleepReduction: number = Math.round((1 - sleepAdjustment) * 100);
      reasons.push(`睡眠质量一般，高糖高脂建议量减少${sleepReduction}%`);
    }
    if (scanIndex > 1) {
      const decayPercent: number = scanIndex <= 2 ? 5 : (scanIndex <= 3 ? 10 : 15);
      reasons.push(`今日第${scanIndex}次扫描，建议量自动下调${decayPercent}%`);
    }
    if (riskWarning.length > 0) {
      reasons.push(riskWarning);
    }

    if (reasons.length > 0) {
      result.dynamicAdjustReason = reasons.join('；');
    }

    // 10. 生成前几次扫描影响说明
    if (scanIndex > 1) {
      const prevRecords: ScanRecord[] = todayRecords.slice(0, -1);
      let prevImpact: string = '';
      const prevHighSodium: number = prevRecords.filter(r => r.sodium_mg >= HIGH_SODIUM_THRESHOLD).length;
      if (prevHighSodium > 0) {
        prevImpact = `之前扫描了${prevHighSodium}款高钠食品，剩余钠预算减少`;
      }
      const prevHighSugar: number = prevRecords.filter(r => r.sugar_g > 10).length;
      if (prevHighSugar > 0 && prevImpact.length > 0) {
        prevImpact += `，同时已摄入${prevHighSugar}款高糖食品`;
      } else if (prevHighSugar > 0) {
        prevImpact = `已摄入${prevHighSugar}款高糖食品，剩余糖预算减少`;
      }
      if (prevImpact.length === 0) {
        prevImpact = `前${scanIndex - 1}次扫描已消耗部分营养预算`;
      }
      result.previousScanImpact = prevImpact;
    }

    // 11. 生成主要原因
    if (result.dynamicAdjustReason && result.dynamicAdjustReason.length > 0) {
      result.reason = result.dynamicAdjustReason;
    } else {
      result.reason = '基于当前状态评估，可以适量食用';
    }

    return result;
  }

  /**
   * 根据步数水平获取预算调整因子
   */
  private static getStepAdjustment(signal: HealthSignal): number {
    // 步数<3000→钠/热量预算额外收紧20%；3000-6000→收紧10%；6000-10000→正常；>10000→可放宽5%
    if (signal.steps === '低') {
      return 0.8; // 收紧20%
    }
    // 大体估算：用活动量水平作为精细判断
    if (signal.steps === '正常' || signal.steps === '高') {
      return 1.0;
    }
    // 默认
    return 1.0;
  }

  /**
   * 根据睡眠质量获取高糖高脂调整因子
   */
  private static getSleepAdjustment(signal: HealthSignal, food: FoodNutrition): number {
    const isHighSugarOrFat: boolean = food.sugar_g > 10 || food.fat_g > 15;
    if (!isHighSugarOrFat) {
      return 1.0;
    }
    // sleep: "差"→额外减少25%；"一般"→减少10%；"好"→正常
    if (signal.sleep === '差') {
      return 0.75;
    }
    if (signal.sleep === '一般') {
      return 0.9;
    }
    return 1.0;
  }

  /**
   * 根据扫描次数获取衰减因子
   * 第1次: 1.0, 第2次: 0.95, 第3次: 0.90, 第4次起: 0.85
   */
  private static getScanDecayFactor(scanIndex: number): number {
    if (scanIndex <= 1) return 1.0;
    if (scanIndex === 2) return 0.95;
    if (scanIndex === 3) return 0.9;
    return 0.85;
  }

  /**
   * 重置今日扫描记录（用于新的一天）
   */
  static resetTodayScanRecords(): void {
    scanHistoryCache.clear();
  }

  /**
   * 获取今日已扫描的高钠食品数量
   */
  static getHighSodiumScanCount(memberId: string): number {
    const records: ScanRecord[] = scanHistoryCache.get(memberId) || [];
    return records.filter(r => r.sodium_mg >= HIGH_SODIUM_THRESHOLD).length;
  }

  /**
   * 为指定成员清理扫描记录
   */
  static clearMemberRecords(memberId: string): void {
    scanHistoryCache.delete(memberId);
  }
}

/**
 * 今日摄入输入（简化版，可直接用TodayIntake数据）
 */
interface TodayIntakeInput {
  sodium_mg: number;
  sugar_g: number;
  energy_kcal: number;
  fat_g: number;
}
