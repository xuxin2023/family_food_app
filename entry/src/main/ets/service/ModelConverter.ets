// ModelConverter.ets
// 统一模型转换服务 - 在新旧模型体系之间进行双向转换
//
// 旧模型体系（Class-based）：
//   FamilyProfile, HealthSignal, FoodLabel, Recommendation, NutritionPer100g
//   定义于 model/FamilyProfile.ets, model/HealthSignal.ets, model/FoodLabel.ets, model/Recommendation.ets
//
// 新模型体系（Interface-based）：
//   FamilyMember, FoodNutrition, HealthSignal(interface), FoodRecommendation, DailyBudget
//   定义于 model/FoodAdapterTypes.ets

import { FamilyProfile, HealthGoal, AgeGroup } from '../model/FamilyProfile';
import {
  HealthSignal as OldHealthSignal,
  StepLevel as OldStepLevel,
  SleepStatus as OldSleepStatus,
  WeightTrend as OldWeightTrend,
  BpStatus as OldBpStatus,
  BsStatus as OldBsStatus
} from '../model/HealthSignal';
import { FoodLabel, NutritionPer100g, FoodSource } from '../model/FoodLabel';
import { Recommendation } from '../model/Recommendation';
import {
  FamilyMember,
  FoodNutrition,
  HealthSignal as NewHealthSignal,
  FoodRecommendation,
  DailyBudget as NewDailyBudget,
  RecommendationLevel,
  SimpleDynamicRule,
  FamilyMemberSimple,
  DynamicRule
} from '../model/FoodAdapterTypes';

// ==================== FamilyProfile ↔ FamilyMember ====================

/**
 * 将旧模型 FamilyProfile 转换为新模型 FamilyMember
 */
export function familyProfileToFamilyMember(
  profile: FamilyProfile,
  _oldSignal?: OldHealthSignal
): FamilyMember {
  const budget: NewDailyBudget = {
    sodium_mg: profile.dailyBudget.sodiumBudget,
    sugar_g: profile.dailyBudget.sugarBudget,
    energy_kcal: profile.dailyBudget.calorieBudget,
    fat_g: profile.dailyBudget.fatBudget,
    saturatedFat_g: Math.round(profile.dailyBudget.fatBudget * 0.3) // 饱和脂肪按总脂肪30%估算
  };

  // 将 HealthGoal[] 转换为 healthGoal 字符串
  const healthGoalStr = profile.healthGoals.length > 0
    ? profile.healthGoals[0]
    : '无特殊';

  return {
    memberId: profile.memberId,
    memberName: profile.nickname,
    age: ageGroupToAge(profile.ageGroup),
    healthGoal: healthGoalStr,
    dailyBudget: budget,
    allergenRedline: profile.allergens,
    dynamicAdjustment: [],
    dislikedAdditives: []
  };
}

/**
 * 将新模型 FamilyMember 转换为旧模型 FamilyProfile
 */
export function familyMemberToFamilyProfile(member: FamilyMember): FamilyProfile {
  const profile = new FamilyProfile();
  profile.memberId = member.memberId;
  profile.nickname = member.memberName;
  profile.ageGroup = ageToAgeGroup(member.age);
  profile.healthGoals = [member.healthGoal as string as HealthGoal];
  profile.allergens = member.allergenRedline;
  profile.dailyBudget.sodiumBudget = member.dailyBudget.sodium_mg;
  profile.dailyBudget.sugarBudget = member.dailyBudget.sugar_g;
  profile.dailyBudget.calorieBudget = member.dailyBudget.energy_kcal;
  profile.dailyBudget.fatBudget = member.dailyBudget.fat_g;
  return profile;
}

/**
 * 将 FamilyMember 转换为 FamilyMemberSimple（用于与新引擎交互）
 */
export function familyMemberToSimple(member: FamilyMember): FamilyMemberSimple {
  return {
    id: member.memberId,
    name: member.memberName,
    role: member.healthGoal,
    age: member.age,
    healthGoal: member.healthGoal,
    dailyBudget: {
      sodium_mg: member.dailyBudget.sodium_mg,
      sugar_g: member.dailyBudget.sugar_g,
      energy_kcal: member.dailyBudget.energy_kcal,
      fat_g: member.dailyBudget.fat_g,
      saturatedFat_g: member.dailyBudget.saturatedFat_g
    },
    allergenRedline: member.allergenRedline,
    dynamicAdjustment: member.dynamicAdjustment.map((r: DynamicRule): SimpleDynamicRule => {
      const rule: SimpleDynamicRule = {
        conditionKey: r.conditionKey,
        conditionValue: r.conditionValue,
        targetNutrient: r.targetNutrient,
        adjustmentRatio: r.adjustmentRatio
      };
      return rule;
    }),
    dislikedAdditives: member.dislikedAdditives
  };
}

// ==================== FoodLabel ↔ FoodNutrition ====================

/**
 * 将旧模型 FoodLabel 转换为新模型 FoodNutrition
 */
export function foodLabelToFoodNutrition(label: FoodLabel): FoodNutrition {
  return {
    productName: label.foodName,
    brand: '',               // FoodLabel 没有 brand 字段，默认空
    netWeight_g: 100,        // 默认按每100g计算
    energy_kj: Math.round((label.nutrition.calories || 0) * 4.184), // kcal → kJ
    protein_g: label.nutrition.protein || 0,
    fat_g: label.nutrition.fat || 0,
    saturatedFat_g: label.nutrition.saturatedFat || 0,
    transFat_g: 0,           // FoodLabel 没有反式脂肪字段
    carbs_g: label.nutrition.carbohydrate || 0,
    sugar_g: label.nutrition.sugar || 0,
    sodium_mg: label.nutrition.sodium || 0,
    allergens: label.allergenHints || [],
    isSugarFree: (label.nutrition.sugar || 0) < 0.5,
    isSucroseFree: false,    // 默认不确定
    sweeteners: [],
    manufacturer: label.manufacturer || '',
    entrustInfo: label.principal.length > 0
      ? `委托方:${label.principal} 受托方:${label.trustee}`
      : '',
    scNumber: label.scNumber || '',
    dataCompleteness: label.hasManufacturer() ? 'high' : 'low'
  };
}

/**
 * 将新模型 FoodNutrition 转换为旧模型 FoodLabel
 */
export function foodNutritionToFoodLabel(nutrition: FoodNutrition): FoodLabel {
  const label = new FoodLabel();
  label.foodId = 'nut_' + Date.now();
  label.foodName = nutrition.productName;
  label.manufacturer = nutrition.manufacturer || '';
  label.scNumber = nutrition.scNumber || '';
  label.nutrition = new NutritionPer100g();
  label.nutrition.sodium = nutrition.sodium_mg;
  label.nutrition.sugar = nutrition.sugar_g;
  label.nutrition.calories = Math.round(nutrition.energy_kj / 4.184); // kJ → kcal
  label.nutrition.fat = nutrition.fat_g;
  label.nutrition.saturatedFat = nutrition.saturatedFat_g;
  label.nutrition.carbohydrate = nutrition.carbs_g;
  label.nutrition.protein = nutrition.protein_g;
  label.allergenHints = nutrition.allergens || [];
  label.source = FoodSource.BARCODE_HIT;
  label.identifiedAt = Date.now();
  return label;
}

// ==================== HealthSignal 转换 ====================

/**
 * 将旧模型 HealthSignal（class）转换为新模型 HealthSignal（interface）
 */
export function healthSignalToNew(oldSignal: OldHealthSignal): NewHealthSignal {
  return {
    steps: stepLevelToStr(oldSignal.stepLevel),
    sleep: sleepStatusToStr(oldSignal.sleepStatus),
    weightTrend: weightTrendToStr(oldSignal.weightTrend),
    manualBpStatus: bpStatusToStr(oldSignal.manualBpStatus),
    manualBgStatus: bsStatusToStr(oldSignal.manualBsStatus)
  };
}

/**
 * 将新模型 HealthSignal（interface）转换为旧模型 HealthSignal（class）
 */
export function healthSignalToOld(newSignal: NewHealthSignal): OldHealthSignal {
  const signal = new OldHealthSignal();
  signal.stepLevel = strToStepLevel(newSignal.steps);
  signal.sleepStatus = strToSleepStatus(newSignal.sleep);
  signal.weightTrend = strToWeightTrend(newSignal.weightTrend);
  signal.manualBpStatus = strToBpStatus(newSignal.manualBpStatus || 'normal');
  signal.manualBsStatus = strToBsStatus(newSignal.manualBgStatus || 'normal');
  return signal;
}

// ==================== Recommendation ↔ FoodRecommendation ====================

/**
 * 将旧模型 Recommendation 转换为新模型 FoodRecommendation
 */
export function recommendationToFoodRecommendation(
  rec: Recommendation,
  member: FamilyMember
): FoodRecommendation {
  return {
    productName: rec.foodId,
    memberId: rec.memberId,
    memberName: member.memberName,
    maxIntake_g: rec.maxAmount,
    level: recommendLevelToNew(rec.level),
    levelText: rec.level,
    reason: rec.reasons.length > 0 ? rec.reasons[0] : ''
  };
}

// ==================== 内部辅助方法 ====================

function ageGroupToAge(group: AgeGroup): number {
  switch (group) {
    case AgeGroup.CHILD:
      return 8;
    case AgeGroup.TEEN:
      return 15;
    case AgeGroup.ADULT:
      return 30;
    case AgeGroup.MIDDLE_OLD:
      return 55;
    case AgeGroup.OLD:
      return 70;
    default:
      return 30;
  }
}

function ageToAgeGroup(age: number): AgeGroup {
  if (age <= 12) return AgeGroup.CHILD;
  if (age <= 18) return AgeGroup.TEEN;
  if (age <= 45) return AgeGroup.ADULT;
  if (age <= 60) return AgeGroup.MIDDLE_OLD;
  return AgeGroup.OLD;
}

function stepLevelToStr(level: OldStepLevel): string {
  switch (level) {
    case OldStepLevel.LOW:
      return 'low';
    case OldStepLevel.HIGH:
      return 'high';
    default:
      return 'normal';
  }
}

function sleepStatusToStr(status: OldSleepStatus): string {
  switch (status) {
    case OldSleepStatus.GOOD:
      return 'good';
    case OldSleepStatus.POOR:
      return 'poor';
    default:
      return 'fair';
  }
}

function weightTrendToStr(trend: OldWeightTrend): string {
  switch (trend) {
    case OldWeightTrend.UP:
      return 'up';
    case OldWeightTrend.DOWN:
      return 'down';
    default:
      return 'stable';
  }
}

function bpStatusToStr(status: OldBpStatus): string {
  switch (status) {
    case OldBpStatus.NORMAL:
      return 'normal';
    case OldBpStatus.ELEVATED:
      return 'elevated';
    case OldBpStatus.HIGH:
      return 'high';
    case OldBpStatus.VERY_HIGH:
      return 'very_high';
    default:
      return 'normal';
  }
}

function bsStatusToStr(status: OldBsStatus): string {
  switch (status) {
    case OldBsStatus.NORMAL:
      return 'normal';
    case OldBsStatus.ELEVATED:
      return 'elevated';
    case OldBsStatus.HIGH:
      return 'high';
    case OldBsStatus.VERY_HIGH:
      return 'very_high';
    default:
      return 'normal';
  }
}

function strToStepLevel(str: string): OldStepLevel {
  switch (str) {
    case 'low':
      return OldStepLevel.LOW;
    case 'high':
      return OldStepLevel.HIGH;
    default:
      return OldStepLevel.NORMAL;
  }
}

function strToSleepStatus(str: string): OldSleepStatus {
  switch (str) {
    case 'good':
      return OldSleepStatus.GOOD;
    case 'poor':
      return OldSleepStatus.POOR;
    default:
      return OldSleepStatus.FAIR;
  }
}

function strToWeightTrend(str: string): OldWeightTrend {
  switch (str) {
    case 'up':
      return OldWeightTrend.UP;
    case 'down':
      return OldWeightTrend.DOWN;
    default:
      return OldWeightTrend.STABLE;
  }
}

function strToBpStatus(str: string): OldBpStatus {
  switch (str) {
    case 'elevated':
      return OldBpStatus.ELEVATED;
    case 'high':
      return OldBpStatus.HIGH;
    case 'very_high':
      return OldBpStatus.VERY_HIGH;
    default:
      return OldBpStatus.NORMAL;
  }
}

function strToBsStatus(str: string): OldBsStatus {
  switch (str) {
    case 'elevated':
      return OldBsStatus.ELEVATED;
    case 'high':
      return OldBsStatus.HIGH;
    case 'very_high':
      return OldBsStatus.VERY_HIGH;
    default:
      return OldBsStatus.NORMAL;
  }
}

function recommendLevelToNew(level: string): RecommendationLevel {
  switch (level) {
    case '适合':
      return RecommendationLevel.GREEN;
    case '少量可以':
      return RecommendationLevel.YELLOW;
    case '今天谨慎':
      return RecommendationLevel.ORANGE;
    case '建议避免':
      return RecommendationLevel.RED;
    default:
      return RecommendationLevel.GREEN;
  }
}
