// ModelConverter.ets
// 模型转换工具 - 统一管理各模型之间的转换逻辑
// 集中存放 estimateAgeFromGroup 等分散在各引擎/管理器中的转换函数
//
// 鸿蒙6.1 ArkTS 约束：
// - 不使用 undefined 类型，统一使用 null

import { FamilyProfile, AgeGroup } from '../model/FamilyProfile';
import { HealthSignal } from '../model/HealthSignal';
import { DailyBudget } from '../model/DailyBudget';
import { FoodLabel } from '../model/FoodLabel';
import { FoodAdapterEngine, FamilyMemberSimpleInput, FoodNutritionInput,
  HealthSignalInput, TodayIntakeInput } from '../engine/FoodAdapterEngine';

/** toFoodAdapterInputs 的返回值类型 */
export interface FoodAdapterInputs {
  memberInput: FamilyMemberSimpleInput;
  foodInput: FoodNutritionInput;
  healthInput: HealthSignalInput;
  intakeInput: TodayIntakeInput;
}

/**
 * 根据 AgeGroup 估算中间年龄（用于 FoodAdapterEngine 输入）
 * 参考年龄分段：
 *   CHILD(儿童)     → 8岁
 *   TEEN(青少年)     → 15岁
 *   ADULT(成年)     → 35岁
 *   MIDDLE_OLD(中老年) → 55岁
 *   OLD(老年)       → 70岁
 */
export function estimateAgeFromGroup(ageGroup: AgeGroup): number {
  switch (ageGroup) {
    case AgeGroup.CHILD:
      return 8;
    case AgeGroup.TEEN:
      return 15;
    case AgeGroup.ADULT:
      return 35;
    case AgeGroup.MIDDLE_OLD:
      return 55;
    case AgeGroup.OLD:
      return 70;
    default:
      return 35;
  }
}

/**
 * 将 FamilyProfile + HealthSignal + FoodLabel + DailyBudget 转换为
 * FoodAdapterEngine 所需的独立输入类型
 * 集中转换逻辑，避免在各处重复
 */
export function toFoodAdapterInputs(
  member: FamilyProfile,
  food: FoodLabel,
  signal: HealthSignal,
  budget: DailyBudget,
  todayIntake?: TodayIntakeInput
): FoodAdapterInputs {
  const memberInput: FamilyMemberSimpleInput = {
    id: member.memberId,
    name: member.nickname,
    role: member.ageGroup,
    age: estimateAgeFromGroup(member.ageGroup),
    healthGoal: member.healthGoals.length > 0 ? member.healthGoals[0] : '无特殊',
    dailyBudget: {
      sodium_mg: member.dailyBudget.sodiumBudget,
      sugar_g: member.dailyBudget.sugarBudget,
      energy_kcal: member.dailyBudget.calorieBudget,
      fat_g: member.dailyBudget.fatBudget,
      saturatedFat_g: 0
    },
    allergenRedline: member.allergens,
    dislikedAdditives: []
  };

  const foodInput: FoodNutritionInput = {
    productName: food.foodName,
    brand: food.manufacturer,
    sodium_mg: food.nutrition.sodium,
    sugar_g: food.nutrition.sugar,
    energy_kj: Math.round(food.nutrition.calories * 4.184),
    fat_g: food.nutrition.fat,
    saturatedFat_g: food.nutrition.saturatedFat,
    transFat_g: 0,
    carbs_g: food.nutrition.carbohydrate,
    protein_g: food.nutrition.protein,
    allergens: food.ingredients,
    manufacturer: food.manufacturer
  };

  const healthInput: HealthSignalInput = {
    steps: signal.stepLevel,
    sleep: signal.sleepStatus,
    weightTrend: signal.weightTrend,
    manualBpStatus: signal.manualBpStatus,
    manualBgStatus: signal.manualBsStatus
  };

  const intakeInput: TodayIntakeInput = todayIntake ?? {
    sodium_mg: Math.max(0, budget.sodiumBudget - budget.sodiumRemaining),
    sugar_g: Math.max(0, budget.sugarBudget - budget.sugarRemaining),
    energy_kcal: Math.max(0, budget.calorieBudget - budget.calorieRemaining),
    fat_g: Math.max(0, budget.fatBudget - budget.fatRemaining)
  };

  return { memberInput, foodInput, healthInput, intakeInput };
}
