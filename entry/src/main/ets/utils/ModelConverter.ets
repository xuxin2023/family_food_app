// ModelConverter.ets
// 模型转换工具 - 统一管理各模型之间的转换逻辑
// 集中存放 estimateAgeFromGroup 等分散在各引擎/管理器中的转换函数
//
// 鸿蒙6.1 ArkTS 约束：
// - 不使用 undefined 类型，统一使用 null

import { FamilyProfile, AgeGroup, HealthSignal, DailyBudget, FoodLabel } from 'hsp_core';


import { FoodAdapterEngine, FamilyMemberSimpleInput, FoodNutritionInput,
  HealthSignalInput, TodayIntakeInput, DailyBudgetInput } from 'feature_scan';

/** toFoodAdapterInputs 的返回值类型 */
export class FoodAdapterInputs {
  memberInput: FamilyMemberSimpleInput = new FamilyMemberSimpleInput();
  foodInput: FoodNutritionInput = new FoodNutritionInput();
  healthInput: HealthSignalInput = new HealthSignalInput();
  intakeInput: TodayIntakeInput = new TodayIntakeInput();
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
  const memberInput: FamilyMemberSimpleInput = new FamilyMemberSimpleInput()
  memberInput.id = member.memberId;
  memberInput.name = member.nickname;
  memberInput.role = member.ageGroup;
  memberInput.age = estimateAgeFromGroup(member.ageGroup);
  memberInput.healthGoal = member.healthGoals.length > 0 ? member.healthGoals[0] : '无特殊';
  const memberBudget: DailyBudgetInput = new DailyBudgetInput()
  memberBudget.sodium_mg = member.dailyBudget.sodiumBudget;
  memberBudget.sugar_g = member.dailyBudget.sugarBudget;
  memberBudget.energy_kcal = member.dailyBudget.calorieBudget;
  memberBudget.fat_g = member.dailyBudget.fatBudget;
  memberBudget.saturatedFat_g = 0;
  memberInput.dailyBudget = memberBudget;
  memberInput.allergenRedline = member.allergens;
  memberInput.dislikedAdditives = [];

  const foodInput: FoodNutritionInput = new FoodNutritionInput()
  foodInput.productName = food.foodName;
  foodInput.brand = food.manufacturer;
  foodInput.sodium_mg = food.nutrition.sodium;
  foodInput.sugar_g = food.nutrition.sugar;
  foodInput.energy_kj = Math.round(food.nutrition.calories * 4.184);
  foodInput.fat_g = food.nutrition.fat;
  foodInput.saturatedFat_g = food.nutrition.saturatedFat;
  foodInput.transFat_g = 0;
  foodInput.carbs_g = food.nutrition.carbohydrate;
  foodInput.protein_g = food.nutrition.protein;
  foodInput.allergens = food.ingredients;
  foodInput.manufacturer = food.manufacturer;

  const healthInput: HealthSignalInput = new HealthSignalInput()
  healthInput.steps = signal.stepLevel;
  healthInput.sleep = signal.sleepStatus;
  healthInput.weightTrend = signal.weightTrend;
  healthInput.manualBpStatus = signal.manualBpStatus;
  healthInput.manualBgStatus = signal.manualBsStatus;

  let intakeInput: TodayIntakeInput = todayIntake ?? new TodayIntakeInput();
  if (!todayIntake) {
    intakeInput.sodium_mg = Math.max(0, budget.sodiumBudget - budget.sodiumRemaining);
    intakeInput.sugar_g = Math.max(0, budget.sugarBudget - budget.sugarRemaining);
    intakeInput.energy_kcal = Math.max(0, budget.calorieBudget - budget.calorieRemaining);
    intakeInput.fat_g = Math.max(0, budget.fatBudget - budget.fatRemaining);
  }

  const result: FoodAdapterInputs = new FoodAdapterInputs()
  result.memberInput = memberInput;
  result.foodInput = foodInput;
  result.healthInput = healthInput;
  result.intakeInput = intakeInput;
  return result;
}