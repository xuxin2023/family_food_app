// RecommendationEngine 单元测试 - 适配计算引擎（高层封装）
import { describe, it, expect } from '@ohos/hypium';
import { RecommendationEngine } from '../../../../src/main/ets/engine/RecommendationEngine';
import { FamilyProfile, AgeGroup, HealthGoal } from '../../../../src/main/ets/model/FamilyProfile';
import { FoodLabel, NutritionPer100g } from '../../../../src/main/ets/model/FoodLabel';
import { DailyBudget } from '../../../../src/main/ets/model/DailyBudget';
import { HealthSignal, StepLevel, SleepStatus, WeightTrend } from '../../../../src/main/ets/model/HealthSignal';
import { RecommendLevel, LevelColor } from '../../../../src/main/ets/model/Recommendation';

function createRecProfile(): FamilyProfile {
  const profile: FamilyProfile = new FamilyProfile
  profile.memberId = 'member_1';
  profile.nickname = '爸爸';
  profile.ageGroup = AgeGroup.ADULT;
  profile.healthGoals = [HealthGoal.CONTROL_BP];
  profile.allergens = [];
  return profile;
}

function createRecFoodLabel(): FoodLabel {
  const food: FoodLabel = new FoodLabel
  food.foodId = 'food_001';
  food.foodName = '测试食品';
  food.barcode = '123456789';
  food.ingredients = ['小麦�?, '�?, '�?];
  food.nutrition = new NutritionPer100g();
  food.nutrition.sodium = 300;
  food.nutrition.sugar = 10;
  food.nutrition.calories = 250;
  food.nutrition.fat = 8;
  food.nutrition.protein = 5;
  food.nutrition.carbohydrate = 40;
  food.allergenHints = [];
  return food;
}

function createRecHealthSignal(): HealthSignal {
  const hs: HealthSignal = new HealthSignal
  hs.memberId = 'member_1';
  hs.stepLevel = StepLevel.NORMAL;
  hs.sleepStatus = SleepStatus.GOOD;
  hs.weightTrend = WeightTrend.STABLE;
  return hs;
}

function createRecDailyBudget(): DailyBudget {
  const budget: DailyBudget = new DailyBudget
  budget.memberId = 'member_1';
  budget.date = '2025-12-15';
  budget.sodiumBudget = 2000;
  budget.sodiumRemaining = 1500;
  budget.sugarBudget = 50;
  budget.sugarRemaining = 40;
  budget.calorieBudget = 2000;
  budget.calorieRemaining = 1400;
  budget.fatBudget = 65;
  budget.fatRemaining = 50;
  return budget;
}

function createRecDailyBudgetZero(): DailyBudget {
  const budget: SimpleDailyBudget = createRecDailyBudget();
  budget.sodiumRemaining = 0;
  budget.sugarRemaining = 0;
  budget.calorieRemaining = 0;
  budget.fatRemaining = 0;
  return budget;
}

function createRecDailyBudgetLowSodium(): DailyBudget {
  const budget: SimpleDailyBudget = createRecDailyBudget();
  budget.sodiumRemaining = 100;
  return budget;
}

export default function recommendationEngineTest() {
  describe('RecommendationEngine', () => {

    // ========== 1. 单个成员基本适配 ==========

    it('should_calculate_for_member', () => {
      const engine: RecommendationEngine = new RecommendationEngine();
      const profile: FamilyProfile = createRecProfile();
      const food: FoodLabel = createRecFoodLabel();
      const signal: HealthSignal = createRecHealthSignal();
      const budget: SimpleDailyBudget = createRecDailyBudget();

      const result = engine.calculateForMember(profile, signal, food, budget);

      expect(result.memberId).assertEqual('member_1');
      expect(result.foodId).assertEqual('food_001');
      expect(result.maxAmount).assertLargerThanOrEqual(0);
      expect(result.level !== null).assertTrue();
    });

    it('should_return_avoid_when_allergen_detected', () => {
      const engine: RecommendationEngine = new RecommendationEngine();
      const profile: FamilyProfile = createRecProfile();
      profile.allergens = ['花生'];
      const food: FoodLabel = createRecFoodLabel();
      food.ingredients = ['小麦�?, '花生�?, '�?]; // contain allergen
      const signal: HealthSignal = createRecHealthSignal();
      const budget: SimpleDailyBudget = createRecDailyBudget();

      const result = engine.calculateForMember(profile, signal, food, budget);

      expect(result.level).assertEqual(RecommendLevel.AVOID);
      expect(result.maxAmount).assertEqual(0);
    });

    it('should_return_suitable_for_low_nutrition_food', () => {
      const engine: RecommendationEngine = new RecommendationEngine();
      const profile: FamilyProfile = createRecProfile();
      const food: FoodLabel = createRecFoodLabel();
      food.nutrition.sodium = 20;
      food.nutrition.sugar = 2;
      food.nutrition.calories = 80;
      food.nutrition.fat = 1;
      const signal: HealthSignal = createRecHealthSignal();
      const budget: SimpleDailyBudget = createRecDailyBudget();

      const result = engine.calculateForMember(profile, signal, food, budget);

      expect(result.level).assertEqual(RecommendLevel.SUITABLE);
      expect(result.maxAmount).assertLargerThan(50);
    });

    // ========== 2. 家庭对比 ==========

    it('should_calculate_family_comparison', () => {
      const engine: RecommendationEngine = new RecommendationEngine();
      const profile1 = createRecProfile();
      const profile2: FamilyProfile = new FamilyProfile
      profile2.memberId = 'member_2';
      profile2.nickname = '妈妈';
      profile2.ageGroup = AgeGroup.ADULT;
      profile2.healthGoals = [HealthGoal.CONTROL_SUGAR];
      profile2.allergens = [];

      const food: FoodLabel = createRecFoodLabel();
      const signal1 = createRecHealthSignal();
      const signal2 = createRecHealthSignal();
      const budget1 = createRecDailyBudget();
      const budget2 = createRecDailyBudget();

      const results = engine.calculateFamilyComparison(
        [profile1, profile2],
        [signal1, signal2],
        food,
        [budget1, budget2]
      );

      expect(results.length).assertEqual(2);
      expect(results[0].memberId).assertEqual('member_1');
      expect(results[1].memberId).assertEqual('member_2');
    });

    // ========== 3. 家庭摘要 ==========

    it('should_generate_family_summary_text', () => {
      const engine: RecommendationEngine = new RecommendationEngine();
      const profile1 = createRecProfile();
      const profile2: FamilyProfile = new FamilyProfile
      profile2.memberId = 'member_2';
      profile2.nickname = '妈妈';
      profile2.ageGroup = AgeGroup.ADULT;
      profile2.healthGoals = [HealthGoal.CONTROL_SUGAR];
      profile2.allergens = [];

      const food: FoodLabel = createRecFoodLabel();
      const signal1 = createRecHealthSignal();
      const signal2 = createRecHealthSignal();
      const budget1 = createRecDailyBudget();
      const budget2 = createRecDailyBudget();

      const results = engine.calculateFamilyComparison(
        [profile1, profile2],
        [signal1, signal2],
        food,
        [budget1, budget2]
      );

      const summary = engine.generateFamilySummary(results, [profile1, profile2]);

      expect(summary.includes('爸爸')).assertTrue();
      expect(summary.includes('妈妈')).assertTrue();
    });

    // ========== 4. 各等级覆�?==========

    it('should_return_avoid_for_zero_budget', () => {
      const engine: RecommendationEngine = new RecommendationEngine();
      const profile: FamilyProfile = createRecProfile();
      const food: FoodLabel = createRecFoodLabel();
      const signal: HealthSignal = createRecHealthSignal();
      const budget: SimpleDailyBudget = createRecDailyBudgetZero();

      const result = engine.calculateForMember(profile, signal, food, budget);

      expect(result.level).assertEqual(RecommendLevel.AVOID);
    });

    it('should_return_cautious_when_amount_very_low', () => {
      const engine: RecommendationEngine = new RecommendationEngine();
      const profile: FamilyProfile = createRecProfile();
      const food: FoodLabel = createRecFoodLabel();
      food.nutrition.sodium = 3000; // high sodium
      const signal: HealthSignal = createRecHealthSignal();
      const budget: SimpleDailyBudget = createRecDailyBudgetLowSodium();

      const result = engine.calculateForMember(profile, signal, food, budget);

      expect(result.level).assertEqual(RecommendLevel.AVOID);
    });

    // ========== 5. 动态修正因�?==========

    it('should_apply_low_activity_modifier', () => {
      const engine: RecommendationEngine = new RecommendationEngine();
      const profile: FamilyProfile = createRecProfile();
      const food: FoodLabel = createRecFoodLabel();
      food.nutrition.calories = 450; // high calorie
      const signal: HealthSignal = createRecHealthSignal();
      signal.stepLevel = StepLevel.LOW;
      const budget: SimpleDailyBudget = createRecDailyBudget();

      const result = engine.calculateForMember(profile, signal, food, budget);

      // 应该有活动量相关的提�?
      const hasActivityReminder = result.reminders.some((r: string) => r.includes('活动�?));
      expect(hasActivityReminder).assertTrue();
    });

    it('should_apply_poor_sleep_modifier', () => {
      const engine: RecommendationEngine = new RecommendationEngine();
      const profile: FamilyProfile = createRecProfile();
      const food: FoodLabel = createRecFoodLabel();
      food.nutrition.sugar = 20; // high sugar
      const signal: HealthSignal = createRecHealthSignal();
      signal.sleepStatus = SleepStatus.POOR;
      const budget: SimpleDailyBudget = createRecDailyBudget();

      const result = engine.calculateForMember(profile, signal, food, budget);

      const hasSleepReminder = result.reminders.some((r: string) => r.includes('睡眠'));
      expect(hasSleepReminder).assertTrue();
    });
  });
}

