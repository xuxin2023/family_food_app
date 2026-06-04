// CrossRiskAssessor.ets
// 多维度风险交叉评估引擎 — 结合家庭成员画像、营养数据、过敏原、孕期安全进行综合风险评估

import { FoodLabel, FamilyProfile, AgeGroup, HealthGoal, PregnancyStatus, NutritionTarget, NUTRIENT_LIMITS_V2 } from 'hsp_core';

export class PregnancyIngredientRule {
  name: string = '';
  maxDailyMg: number = 0;
  hasMaxDaily: boolean = false;
  severity: string = 'CAUTION';
  reason: string = '';
}

export class PregnancyWarning {
  ingredient: string = '';
  matchedRule: PregnancyIngredientRule = new PregnancyIngredientRule();
}

export class PregnancySafetyResult {
  safe: boolean = true;
  warnings: PregnancyWarning[] = [];
  summary: string = '';
}

const PREGNANCY_AVOID_KEYWORDS: string[] = [
  '酒精', '生鱼片', '生肉', '生蛋', '含汞鱼类', '未经巴氏杀菌', '藏红花', '甘草'
];
const PREGNANCY_CAUTION_KEYWORDS: string[] = [
  '咖啡因', '维生素A', '人参'
];

export class RiskFactor {
  category: string = '';
  severity: string = '';
  description: string = '';
  affectedMembers: string[] = [];
}

export class CrossRiskResult {
  riskFactors: RiskFactor[] = [];
  overallRiskLevel: string = 'low';
  summary: string = '';
}

export class DailyIntakeSnapshot {
  sodium: number = 0;
  sugar: number = 0;
  calorie: number = 0;
  fat: number = 0;
}

/**
 * 多维度风险交叉评估引擎
 *
 * 结合家庭成员画像、营养数据、过敏原、孕期安全进行综合风险评估，
 * 评估维度包括：
 * - 营养风险：针对控压/控糖/减脂/控脂目标检测超标
 * - 过敏原风险：配料表与成员过敏原交叉匹配
 * - 孕期风险：检测孕期/哺乳期避免或谨慎成分
 * - 儿童风险：检测高钠/高糖/咖啡因等不适宜成分
 * - 累计超标风险：今日已摄入+本次是否超标预警
 *
 * @since 1.0.0
 */
export class CrossRiskAssessor {
  private static readonly HIGH_SODIUM_MG: number = 500;
  private static readonly CHILD_HIGH_SUGAR_G: number = 15;
  private static readonly HIGH_FAT_G: number = 20;
  private static readonly HIGH_CALORIE_KCAL: number = 400;
  private static readonly CALORIE_EXCEED_RATIO: number = 1.1;
  private static readonly NEAR_LIMIT_RATIO: number = 0.8;
  private static readonly BELOW_TARGET_RATIO: number = 0.7;

  private static readonly CAFFEINE_KEYWORDS: string[] = [
    '咖啡因', '咖啡', '红茶', '绿茶', '可乐', '能量饮料', '可可', '巧克力'
  ];

  /**
   * 执行多维度风险交叉评估
   *
   * @param foodLabel - 食品标签数据
   * @param members - 家庭成员画像列表
   * @param targets - 各成员营养目标列表
   * @param dailyIntake - 今日已摄入快照
   * @returns 综合风险评估结果，包含各风险因子及整体风险等级
   *
   * @example
   * ```typescript`
   * const assessor = new CrossRiskAssessor();
   * const result = assessor.assess(foodLabel, members, targets, dailyIntake);
   * console.log(result.overallRiskLevel); // 'low' | 'medium' | 'high' | 'critical'
   * ````
   */
  assess(
    foodLabel: FoodLabel,
    members: FamilyProfile[],
    targets: NutritionTarget[],
    dailyIntake: DailyIntakeSnapshot
  ): CrossRiskResult {
    const result = new CrossRiskResult();
    result.riskFactors = [];
    const factors: RiskFactor[] = [];

    if (members.length === 0) {
      result.overallRiskLevel = 'low';
      result.summary = '无家庭成员数据';
      return result;
    }

    for (let mi = 0; mi < members.length; mi++) {
      const member = members[mi];
      const target = this.findTarget(targets, member.memberId);

      // a) 营养风险
      this.assessNutritionRisk(foodLabel, member, target, dailyIntake, factors);

      // b) 过敏原风险
      this.assessAllergenRisk(foodLabel, member, factors);

      // c) 孕期风险
      this.assessPregnancyRisk(foodLabel, member, factors);

      // d) 儿童风险
      this.assessChildRisk(foodLabel, member, factors);
    }

    // e) 关联风险：今日累计+本次是否超标
    this.assessAccumulatedRisk(foodLabel, dailyIntake, targets, members, factors);

    result.riskFactors = factors;
    result.overallRiskLevel = this.computeOverallLevel(factors);
    result.summary = this.buildSummary(factors);
    return result;
  }

  private findTarget(targets: NutritionTarget[], memberId: string): NutritionTarget {
    for (let i = 0; i < targets.length; i++) {
      if (targets[i].memberId === memberId) {
        return targets[i];
      }
    }
    const t = new NutritionTarget();
    t.memberId = memberId;
    return t;
  }

  private assessNutritionRisk(
    foodLabel: FoodLabel,
    member: FamilyProfile,
    target: NutritionTarget,
    dailyIntake: DailyIntakeSnapshot,
    factors: RiskFactor[]
  ): void {
    const nutrition = foodLabel.nutrition;

    if (member.isControlBp() && nutrition.sodium >= CrossRiskAssessor.HIGH_SODIUM_MG) {
      const f = new RiskFactor();
      f.category = '钠过量';
      f.severity = 'high';
      f.description = `${member.nickname}（控压目标）本食品钠${nutrition.sodium}mg/100g，属于高钠食品`;
      f.affectedMembers = [member.memberId];
      factors.push(f);
    }

    if (member.isControlSugar() && nutrition.sugar >= NUTRIENT_LIMITS_V2.SUGAR_HIGH_THRESHOLD_G) {
      const f = new RiskFactor();
      f.category = '糖过量';
      f.severity = 'high';
      f.description = `${member.nickname}（控糖目标）本食品糖${nutrition.sugar}g/100g，属于高糖食品`;
      f.affectedMembers = [member.memberId];
      factors.push(f);
    }

    if (member.isLoseFat() && nutrition.calories >= CrossRiskAssessor.HIGH_CALORIE_KCAL) {
      const f = new RiskFactor();
      f.category = '高热量';
      f.severity = 'medium';
      f.description = `${member.nickname}（减脂目标）本食品热量${nutrition.calories}kcal/100g，属于高热量食品`;
      f.affectedMembers = [member.memberId];
      factors.push(f);
    }

    if (member.isControlFat() && nutrition.fat >= CrossRiskAssessor.HIGH_FAT_G) {
      const f = new RiskFactor();
      f.category = '高脂肪';
      f.severity = 'medium';
      f.description = `${member.nickname}（控脂目标）本食品脂肪${nutrition.fat}g/100g，属于高脂食品`;
      f.affectedMembers = [member.memberId];
      factors.push(f);
    }
  }

  private assessAllergenRisk(foodLabel: FoodLabel, member: FamilyProfile, factors: RiskFactor[]): void {
    if (member.allergens.length === 0) {
      return;
    }
    const matched: string[] = [];
    const ingredientsText = foodLabel.ingredients.join(',');
    const allergenHintsText = foodLabel.allergenHints.join(',');

    for (let i = 0; i < member.allergens.length; i++) {
      const allergen = member.allergens[i];
      if (ingredientsText.includes(allergen) || allergenHintsText.includes(allergen)) {
        matched.push(allergen);
      }
    }

    if (matched.length > 0) {
      const f = new RiskFactor();
      f.category = '过敏原';
      f.severity = 'critical';
      f.description = `${member.nickname}对${matched.join('、')}过敏，本食品含相关成分`;
      f.affectedMembers = [member.memberId];
      factors.push(f);
    }
  }

  private assessPregnancyRisk(foodLabel: FoodLabel, member: FamilyProfile, factors: RiskFactor[]): void {
    if (member.pregnancyStatus === PregnancyStatus.NONE) {
      return;
    }
    if (foodLabel.ingredients.length === 0) {
      return;
    }

    const warnings: PregnancyWarning[] = [];
    const ingredientsText = foodLabel.ingredients.join(',');
    for (let i = 0; i < PREGNANCY_AVOID_KEYWORDS.length; i++) {
      if (ingredientsText.includes(PREGNANCY_AVOID_KEYWORDS[i])) {
        const w = new PregnancyWarning();
        w.ingredient = PREGNANCY_AVOID_KEYWORDS[i];
        w.matchedRule.severity = 'AVOID';
        warnings.push(w);
      }
    }
    for (let i = 0; i < PREGNANCY_CAUTION_KEYWORDS.length; i++) {
      if (ingredientsText.includes(PREGNANCY_CAUTION_KEYWORDS[i])) {
        const w = new PregnancyWarning();
        w.ingredient = PREGNANCY_CAUTION_KEYWORDS[i];
        w.matchedRule.severity = 'CAUTION';
        warnings.push(w);
      }
    }

    const avoidCount = warnings.filter((w: PregnancyWarning) => w.matchedRule.severity === 'AVOID').length;
    const cautionCount = warnings.filter((w: PregnancyWarning) => w.matchedRule.severity === 'CAUTION').length;

    if (avoidCount > 0 || cautionCount > 0) {
      const f = new RiskFactor();
      f.category = '孕期不安全';
      f.severity = avoidCount > 0 ? 'high' : 'medium';
      const statusLabel = member.pregnancyStatus === PregnancyStatus.PREGNANT ? '孕期' : '哺乳期';
      f.description = `${member.nickname}（${statusLabel}）：发现${avoidCount}项避免成分、${cautionCount}项谨慎成分`;
      f.affectedMembers = [member.memberId];
      factors.push(f);
    }
  }

  private assessChildRisk(foodLabel: FoodLabel, member: FamilyProfile, factors: RiskFactor[]): void {
    if (!member.isChild()) {
      return;
    }
    const nutrition = foodLabel.nutrition;
    const risks: string[] = [];

    if (nutrition.sodium >= CrossRiskAssessor.HIGH_SODIUM_MG) {
      risks.push(`高钠(${nutrition.sodium}mg)`);
    }
    if (nutrition.sugar >= CrossRiskAssessor.CHILD_HIGH_SUGAR_G) {
      risks.push(`高糖(${nutrition.sugar}g)`);
    }

    const ingredientsText = foodLabel.ingredients.join(',');
    for (let i = 0; i < CrossRiskAssessor.CAFFEINE_KEYWORDS.length; i++) {
      if (ingredientsText.includes(CrossRiskAssessor.CAFFEINE_KEYWORDS[i])) {
        risks.push('含咖啡因');
        break;
      }
    }

    if (risks.length > 0) {
      const f = new RiskFactor();
      f.category = '儿童不适宜';
      f.severity = 'medium';
      f.description = `${member.nickname}（儿童）：本食品${risks.join('、')}，不适宜儿童食用`;
      f.affectedMembers = [member.memberId];
      factors.push(f);
    }
  }

  private assessAccumulatedRisk(
    foodLabel: FoodLabel,
    dailyIntake: DailyIntakeSnapshot,
    targets: NutritionTarget[],
    members: FamilyProfile[],
    factors: RiskFactor[]
  ): void {
    if (members.length === 0 || targets.length === 0) {
      return;
    }
    const nutrition = foodLabel.nutrition;
    const primaryTarget = targets[0];

    const projectedSodium = dailyIntake.sodium + nutrition.sodium;
    if (projectedSodium > primaryTarget.sodiumMax_mg && dailyIntake.sodium <= primaryTarget.sodiumMax_mg) {
      const f = new RiskFactor();
      f.category = '钠超标预警';
      f.severity = 'medium';
      f.description = `今日钠已摄入${Math.round(dailyIntake.sodium)}mg + 本次${nutrition.sodium}mg = ${Math.round(projectedSodium)}mg，将超过目标${primaryTarget.sodiumMax_mg}mg`;
      f.affectedMembers = members.map((m: FamilyProfile) => m.memberId);
      factors.push(f);
    }

    const projectedSugar = dailyIntake.sugar + nutrition.sugar;
    if (projectedSugar > primaryTarget.sugarMax_g && dailyIntake.sugar <= primaryTarget.sugarMax_g) {
      const f = new RiskFactor();
      f.category = '糖超标预警';
      f.severity = 'medium';
      f.description = `今日糖已摄入${dailyIntake.sugar.toFixed(1)}g + 本次${nutrition.sugar}g = ${projectedSugar.toFixed(1)}g，将超过目标${primaryTarget.sugarMax_g}g`;
      f.affectedMembers = members.map((m: FamilyProfile) => m.memberId);
      factors.push(f);
    }

    const projectedCalorie = dailyIntake.calorie + nutrition.calories;
    if (projectedCalorie > primaryTarget.caloriesTarget * CrossRiskAssessor.CALORIE_EXCEED_RATIO && dailyIntake.calorie <= primaryTarget.caloriesTarget) {
      const f = new RiskFactor();
      f.category = '热量超标预警';
      f.severity = 'low';
      f.description = `今日热量已摄入${Math.round(dailyIntake.calorie)}kcal + 本次${nutrition.calories}kcal = ${Math.round(projectedCalorie)}kcal，将超过目标${primaryTarget.caloriesTarget}kcal`;
      f.affectedMembers = members.map((m: FamilyProfile) => m.memberId);
      factors.push(f);
    }
  }

  private computeOverallLevel(factors: RiskFactor[]): string {
    if (factors.length === 0) {
      return 'low';
    }
    let hasCritical = false;
    let hasHigh = false;
    let hasMedium = false;
    for (let i = 0; i < factors.length; i++) {
      const s = factors[i].severity;
      if (s === 'critical') hasCritical = true;
      if (s === 'high') hasHigh = true;
      if (s === 'medium') hasMedium = true;
    }
    if (hasCritical) return 'critical';
    if (hasHigh) return 'high';
    if (hasMedium) return 'medium';
    return 'low';
  }

  private buildSummary(factors: RiskFactor[]): string {
    if (factors.length === 0) {
      return '当前食品对家庭成员无显著风险';
    }
    const criticalCount = factors.filter((f: RiskFactor) => f.severity === 'critical').length;
    const highCount = factors.filter((f: RiskFactor) => f.severity === 'high').length;
    const mediumCount = factors.filter((f: RiskFactor) => f.severity === 'medium').length;
    const parts: string[] = [];
    if (criticalCount > 0) parts.push(`${criticalCount}项严重风险`);
    if (highCount > 0) parts.push(`${highCount}项高风险`);
    if (mediumCount > 0) parts.push(`${mediumCount}项中等风险`);
    return `发现${parts.join('、')}，请关注受影响成员`;
  }

  /**
   * 获取风险等级对应颜色
   *
   * @param level - 风险等级('critical'|'high'|'medium'|'low')
   * @returns 颜色HEX值
   */
  static getRiskColor(level: string): string {
    switch (level) {
      case 'critical': return '#F44336';
      case 'high': return '#FF5722';
      case 'medium': return '#FF9800';
      case 'low': return '#4CAF50';
      default: return '#999999';
    }
  }

  /**
   * 获取风险等级中文标签
   *
   * @param level - 风险等级('critical'|'high'|'medium'|'low')
   * @returns 中文标签
   */
  static getRiskLabel(level: string): string {
    switch (level) {
      case 'critical': return '严重';
      case 'high': return '高风险';
      case 'medium': return '中等';
      case 'low': return '低风险';
      default: return '未知';
    }
  }
}
