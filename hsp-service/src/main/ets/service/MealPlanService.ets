import { FamilyProfile, FoodLabel, DailyBudget, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MealPlanService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface MealPlanItem {
  mealType: string;
  timeSlot: string;
  foods: FoodLabel[];
  totalCalories: number;
  totalSodium: number;
  totalSugar: number;
  totalFat: number;
  totalProtein: number;
}

export interface MealPlan {
  memberId: string;
  date: string;
  meals: MealPlanItem[];
  dailyTotal: {
    calories: number; sodium: number; sugar: number; fat: number; protein: number;
  };
  budgetUtilization: number;
  suggestions: string[];
}

export class MealPlanService {
  generatePlan(
    memberId: string,
    date: string,
    availableFoods: FoodLabel[],
    budget: DailyBudget,
    profile: FamilyProfile
  ): MealPlan {
    const mealSlots: { type: string; time: string; ratio: number }[] = [
      { type: '早餐', time: '07:00', ratio: 0.3 },
      { type: '午餐', time: '12:00', ratio: 0.4 },
      { type: '晚餐', time: '18:00', ratio: 0.25 },
      { type: '加餐', time: '15:00', ratio: 0.05 }
    ];

    const meals: MealPlanItem[] = [];
    let totalCalories = 0, totalSodium = 0, totalSugar = 0, totalFat = 0, totalProtein = 0;

    for (const slot of mealSlots) {
      const targetCal = budget.calorieBudget * slot.ratio;
      const selectedFoods = this.selectFoodsForMeal(availableFoods, targetCal, profile);
      let mealCal = 0, mealSodium = 0, mealSugar = 0, mealFat = 0, mealProtein = 0;
      for (const food of selectedFoods) {
        mealCal += food.nutrition.calories;
        mealSodium += food.nutrition.sodium;
        mealSugar += food.nutrition.sugar;
        mealFat += food.nutrition.fat;
        mealProtein += food.nutrition.protein;
      }
      totalCalories += mealCal;
      totalSodium += mealSodium;
      totalSugar += mealSugar;
      totalFat += mealFat;
      totalProtein += mealProtein;
      meals.push({
        mealType: slot.type, timeSlot: slot.time, foods: selectedFoods,
        totalCalories: mealCal, totalSodium: mealSodium, totalSugar: mealSugar,
        totalFat: mealFat, totalProtein: mealProtein
      });
    }

    const budgetUtil = Math.min(totalCalories / budget.calorieBudget, 1);
    const suggestions = this.generateSuggestions(totalCalories, totalSodium, totalSugar, budget, profile);

    return {
      memberId, date, meals,
      dailyTotal: { calories: totalCalories, sodium: totalSodium, sugar: totalSugar, fat: totalFat, protein: totalProtein },
      budgetUtilization: budgetUtil, suggestions
    };
  }

  private selectFoodsForMeal(foods: FoodLabel[], targetCal: number, profile: FamilyProfile): FoodLabel[] {
    const safe = foods.filter(f => !profile.allergens.some(a => f.ingredients.includes(a) || f.allergens.includes(a)));
    const sorted = safe.sort((a, b) => b.nutrition.protein - a.nutrition.protein);
    const selected: FoodLabel[] = [];
    let cal = 0;
    for (const food of sorted) {
      if (cal + food.nutrition.calories <= targetCal * 1.1) {
        selected.push(food);
        cal += food.nutrition.calories;
      }
      if (cal >= targetCal * 0.9) break;
    }
    return selected;
  }

  private generateSuggestions(
    totalCal: number, totalSodium: number, totalSugar: number,
    budget: DailyBudget, profile: FamilyProfile
  ): string[] {
    const suggestions: string[] = [];
    if (totalSodium > budget.sodiumBudget) suggestions.push('钠摄入超标，建议减少加工食品');
    if (totalSugar > budget.sugarBudget) suggestions.push('糖摄入超标，建议减少甜食和含糖饮料');
    if (totalCal > budget.calorieBudget * 1.1) suggestions.push('热量超标10%以上，建议控制主食份量');
    if (totalCal < budget.calorieBudget * 0.7) suggestions.push('热量不足70%，建议增加优质蛋白和全谷物');
    return suggestions;
  }
}
