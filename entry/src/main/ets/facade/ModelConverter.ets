import { FamilyProfile, HealthSignal, FoodLabel, DailyBudget, DailyBudgetConfig, TodayIntakeInput } from 'hsp_core';
import { FamilyMemberSimpleInput, FoodNutritionInput, HealthSignalInput, DailyBudgetInput } from 'feature_scan';

export class ModelConverter {
  static toMemberInput(member: FamilyProfile): FamilyMemberSimpleInput {
    const input: FamilyMemberSimpleInput = {
      id: member.memberId,
      name: member.nickname,
      role: member.ageGroup as string,
      age: DailyBudgetConfig.estimateAgeFromGroup(member.ageGroup),
      healthGoal: member.healthGoals.length > 0 ? member.healthGoals[0] : '无特殊',
      dailyBudget: {
        sodium_mg: member.dailyBudget.sodiumBudget,
        sugar_g: member.dailyBudget.sugarBudget,
        energy_kcal: member.dailyBudget.calorieBudget,
        fat_g: member.dailyBudget.fatBudget,
        saturatedFat_g: 0
      } as DailyBudgetInput,
      allergenRedline: member.allergens,
      dislikedAdditives: []
    } as FamilyMemberSimpleInput;
    return input;
  }

  static toFoodInput(food: FoodLabel): FoodNutritionInput {
    const input: FoodNutritionInput = {
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
    } as FoodNutritionInput;
    return input;
  }

  static toHealthInput(signal: HealthSignal): HealthSignalInput {
    const input: HealthSignalInput = {
      steps: signal.stepLevel,
      sleep: signal.sleepStatus,
      weightTrend: signal.weightTrend,
      manualBpStatus: signal.manualBpStatus,
      manualBgStatus: signal.manualBsStatus
    } as HealthSignalInput;
    return input;
  }

  static toTodayIntake(budget: DailyBudget): TodayIntakeInput {
    return {
      sodium_mg: Math.max(0, budget.sodiumBudget - budget.sodiumRemaining),
      sugar_g: Math.max(0, budget.sugarBudget - budget.sugarRemaining),
      energy_kcal: Math.max(0, budget.calorieBudget - budget.calorieRemaining),
      fat_g: Math.max(0, budget.fatBudget - budget.fatRemaining)
    };
  }
}