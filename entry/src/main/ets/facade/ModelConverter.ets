import { FamilyProfile, HealthSignal, FoodLabel, DailyBudget, DailyBudgetConfig, TodayIntakeInput } from 'hsp_core';
import { FamilyMemberSimpleInput, FoodNutritionInput, HealthSignalInput, DailyBudgetInput } from 'feature_scan';

export class ModelConverter {
  static toMemberInput(member: FamilyProfile): FamilyMemberSimpleInput {
    const input = new FamilyMemberSimpleInput();
    input.id = member.memberId;
    input.name = member.nickname;
    input.role = member.ageGroup as string;
    input.age = DailyBudgetConfig.estimateAgeFromGroup(member.ageGroup);
    input.healthGoal = member.healthGoals.length > 0 ? member.healthGoals[0] : '无特殊';
    const mb = new DailyBudgetInput();
    mb.sodium_mg = member.dailyBudget.sodiumBudget;
    mb.sugar_g = member.dailyBudget.sugarBudget;
    mb.energy_kcal = member.dailyBudget.calorieBudget;
    mb.fat_g = member.dailyBudget.fatBudget;
    mb.saturatedFat_g = 0;
    input.dailyBudget = mb;
    input.allergenRedline = member.allergens;
    input.dislikedAdditives = [];
    return input;
  }

  static toFoodInput(food: FoodLabel): FoodNutritionInput {
    const input = new FoodNutritionInput();
    input.productName = food.foodName;
    input.brand = food.manufacturer;
    input.sodium_mg = food.nutrition.sodium;
    input.sugar_g = food.nutrition.sugar;
    input.energy_kj = Math.round(food.nutrition.calories * 4.184);
    input.fat_g = food.nutrition.fat;
    input.saturatedFat_g = food.nutrition.saturatedFat;
    input.transFat_g = 0;
    input.carbs_g = food.nutrition.carbohydrate;
    input.protein_g = food.nutrition.protein;
    input.allergens = food.ingredients;
    input.manufacturer = food.manufacturer;
    return input;
  }

  static toHealthInput(signal: HealthSignal): HealthSignalInput {
    const input = new HealthSignalInput();
    input.steps = signal.stepLevel;
    input.sleep = signal.sleepStatus;
    input.weightTrend = signal.weightTrend;
    input.manualBpStatus = signal.manualBpStatus;
    input.manualBgStatus = signal.manualBsStatus;
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