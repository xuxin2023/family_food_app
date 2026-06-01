// ChildHealthAssessmentEngine 单元测试 - 儿童专属健康评估与推荐引擎
import { describe, it, expect } from '@ohos/hypium';
import { ChildHealthAssessmentEngine, ChildHealthAssessment, SnackImpactAssessment, AdditiveSafetyResult, AdditiveSafetyLevel } from 'feature_report';
import { FamilyProfile, AgeGroup, FoodLabel, NutritionPer100g } from 'hsp_core';

function createChildProfile(): FamilyProfile {
  const profile: FamilyProfile = new FamilyProfile();
  profile.memberId = 'member_child';
  profile.nickname = '小明';
  profile.ageGroup = AgeGroup.CHILD;
  profile.healthGoals = [];
  profile.allergens = [];
  return profile;
}

function createTeenProfile(): FamilyProfile {
  const profile: FamilyProfile = new FamilyProfile();
  profile.memberId = 'member_teen';
  profile.nickname = '小红';
  profile.ageGroup = AgeGroup.TEEN;
  profile.healthGoals = [];
  profile.allergens = [];
  return profile;
}

function createSnackFood(snackName: string, calories: number, sugar: number, sodium: number): FoodLabel {
  const food: FoodLabel = new FoodLabel();
  food.foodId = 'snack_001';
  food.foodName = snackName;
  food.ingredients = ['小麦粉', '白砂糖'];
  food.nutrition = new NutritionPer100g();
  food.nutrition.calories = calories;
  food.nutrition.sugar = sugar;
  food.nutrition.sodium = sodium;
  food.nutrition.protein = 2;
  food.nutrition.fat = 5;
  food.nutrition.carbohydrate = 30;
  return food;
}

function createAdditiveFood(): FoodLabel {
  const food: FoodLabel = new FoodLabel();
  food.foodId = 'additive_001';
  food.foodName = '彩色糖果';
  food.ingredients = ['柠檬黄', '日落黄', '阿斯巴甜', '苯甲酸钠'];
  food.nutrition = new NutritionPer100g();
  food.nutrition.calories = 350;
  food.nutrition.sugar = 40;
  food.nutrition.sodium = 150;
  return food;
}

export default function childHealthAssessmentEngineTest() {
  describe('ChildHealthAssessmentEngine', () => {

    // ========== 1. assess 零食影响评估 ==========

    it('should_assess_low_calorie_snack_as_minor_impact', 0, () => {
      const engine: ChildHealthAssessmentEngine = new ChildHealthAssessmentEngine();
      const food: FoodLabel = createSnackFood('小饼干', 60, 5, 80);
      const profile: FamilyProfile = createChildProfile();

      const result: ChildHealthAssessment = engine.assess(food, profile, 0, 0);

      expect(result.snackImpact.mealAppetiteLevel).assertEqual('轻微影响');
      expect(result.overallSafetyScore).assertLargerOrEqual(60);
    });

    it('should_assess_high_calorie_snack_as_severe_impact', 0, () => {
      const engine: ChildHealthAssessmentEngine = new ChildHealthAssessmentEngine();
      const food: FoodLabel = createSnackFood('大蛋糕', 200, 15, 200);
      const profile: FamilyProfile = createChildProfile();

      const result: ChildHealthAssessment = engine.assess(food, profile, 0, 0);

      expect(result.snackImpact.mealAppetiteLevel).assertEqual('严重影响');
      expect(result.overallSafetyScore).assertLess(80);
    });

    it('should_detect_sugar_over_limit', 0, () => {
      const engine: ChildHealthAssessmentEngine = new ChildHealthAssessmentEngine();
      const food: FoodLabel = createSnackFood('甜饮料', 100, 20, 10);
      const profile: FamilyProfile = createChildProfile();

      const result: ChildHealthAssessment = engine.assess(food, profile, 0, 10);

      expect(result.snackImpact.sugarImpactLevel).assertEqual('超标');
    });

    // ========== 2. 添加剂安全评估 ==========

    it('should_flag_avoid_for_child_additives', 0, () => {
      const engine: ChildHealthAssessmentEngine = new ChildHealthAssessmentEngine();
      const food: FoodLabel = createAdditiveFood();
      const profile: FamilyProfile = createChildProfile();

      const result: ChildHealthAssessment = engine.assess(food, profile, 0, 0);

      const avoidItems: AdditiveSafetyResult[] = result.additiveResults.filter(
        (a: AdditiveSafetyResult) => a.safetyLevel === AdditiveSafetyLevel.AVOID_FOR_CHILD
      );
      expect(avoidItems.length).assertLarger(0);
    });

    it('should_flag_caution_additives', 0, () => {
      const engine: ChildHealthAssessmentEngine = new ChildHealthAssessmentEngine();
      const food: FoodLabel = new FoodLabel();
      food.foodId = 'caution_001';
      food.foodName = '调味零食';
      food.ingredients = ['山梨酸钾', '味精'];
      food.nutrition = new NutritionPer100g();
      food.nutrition.calories = 200;
      food.nutrition.sugar = 5;
      food.nutrition.sodium = 300;
      const profile: FamilyProfile = createChildProfile();

      const result: ChildHealthAssessment = engine.assess(food, profile, 0, 0);

      const cautionItems: AdditiveSafetyResult[] = result.additiveResults.filter(
        (a: AdditiveSafetyResult) => a.safetyLevel === AdditiveSafetyLevel.CAUTION
      );
      expect(cautionItems.length).assertLarger(0);
    });

    it('should_identify_safe_additives', 0, () => {
      const engine: ChildHealthAssessmentEngine = new ChildHealthAssessmentEngine();
      const food: FoodLabel = new FoodLabel();
      food.foodId = 'safe_001';
      food.foodName = '酸奶';
      food.ingredients = ['黄原胶', '羧甲基纤维素'];
      food.nutrition = new NutritionPer100g();
      food.nutrition.calories = 80;
      food.nutrition.sugar = 8;
      food.nutrition.sodium = 50;
      food.nutrition.protein = 10;
      const profile: FamilyProfile = createChildProfile();

      const result: ChildHealthAssessment = engine.assess(food, profile, 0, 0);

      const safeItems: AdditiveSafetyResult[] = result.additiveResults.filter(
        (a: AdditiveSafetyResult) => a.safetyLevel === AdditiveSafetyLevel.SAFE
      );
      expect(safeItems.length).assertLarger(0);
    });

    // ========== 3. 综合评分与建议 ==========

    it('should_generate_overall_advice_for_safe_food', 0, () => {
      const engine: ChildHealthAssessmentEngine = new ChildHealthAssessmentEngine();
      const food: FoodLabel = new FoodLabel();
      food.foodId = 'safe_food';
      food.foodName = '纯牛奶';
      food.ingredients = ['生牛乳'];
      food.nutrition = new NutritionPer100g();
      food.nutrition.calories = 60;
      food.nutrition.sugar = 5;
      food.nutrition.sodium = 50;
      food.nutrition.protein = 10;
      food.nutrition.calcium = 120;
      const profile: FamilyProfile = createChildProfile();

      const result: ChildHealthAssessment = engine.assess(food, profile, 0, 0);

      expect(result.overallSafetyScore).assertLargerOrEqual(80);
      expect(result.overallAdvice.includes('安全')).assertTrue();
    });

    it('should_generate_overall_advice_for_unsafe_food', 0, () => {
      const engine: ChildHealthAssessmentEngine = new ChildHealthAssessmentEngine();
      const food: FoodLabel = createAdditiveFood();
      const profile: FamilyProfile = createChildProfile();

      const result: ChildHealthAssessment = engine.assess(food, profile, 0, 0);

      expect(result.overallAdvice.length > 0).assertTrue();
    });

    it('should_check_growth_nutrition_for_child', 0, () => {
      const engine: ChildHealthAssessmentEngine = new ChildHealthAssessmentEngine();
      const food: FoodLabel = new FoodLabel();
      food.foodId = 'growth_001';
      food.foodName = '高蛋白钙奶';
      food.ingredients = ['奶粉', '乳钙'];
      food.nutrition = new NutritionPer100g();
      food.nutrition.calories = 100;
      food.nutrition.sugar = 3;
      food.nutrition.sodium = 60;
      food.nutrition.protein = 12;
      food.nutrition.calcium = 200;
      food.nutrition.iron = 3;
      food.nutrition.fiber = 4;
      const profile: FamilyProfile = createChildProfile();

      const result: ChildHealthAssessment = engine.assess(food, profile, 0, 0);

      expect(result.growthNutritionCheck.length > 0).assertTrue();
    });

    // ========== 4. 青少年差异 & 边界条件 ==========

    it('should_use_teen_sugar_limit_for_teen', 0, () => {
      const engine: ChildHealthAssessmentEngine = new ChildHealthAssessmentEngine();
      const food: FoodLabel = createSnackFood('奶茶', 120, 25, 50);
      const profile: FamilyProfile = createTeenProfile();

      const result: ChildHealthAssessment = engine.assess(food, profile, 0, 0);

      expect(result.memberId).assertEqual('member_teen');
      expect(result.snackImpact.dailySugarContribution > 0).assertTrue();
    });

    it('should_handle_zero_snack_calories_today', 0, () => {
      const engine: ChildHealthAssessmentEngine = new ChildHealthAssessmentEngine();
      const food: FoodLabel = createSnackFood('小面包', 80, 3, 60);
      const profile: FamilyProfile = createChildProfile();

      const result: ChildHealthAssessment = engine.assess(food, profile, 0, 0);

      expect(result.snackImpact.sugarImpactLevel).assertEqual('安全');
    });

    it('should_handle_no_matching_additives', 0, () => {
      const engine: ChildHealthAssessmentEngine = new ChildHealthAssessmentEngine();
      const food: FoodLabel = new FoodLabel();
      food.foodId = 'natural_001';
      food.foodName = '新鲜苹果';
      food.ingredients = ['苹果'];
      food.nutrition = new NutritionPer100g();
      food.nutrition.calories = 50;
      food.nutrition.sugar = 10;
      food.nutrition.sodium = 1;
      const profile: FamilyProfile = createChildProfile();

      const result: ChildHealthAssessment = engine.assess(food, profile, 0, 0);

      expect(result.additiveResults.length).assertEqual(0);
      expect(result.overallSafetyScore).assertLargerOrEqual(80);
    });

    it('should_score_between_0_and_100', 0, () => {
      const engine: ChildHealthAssessmentEngine = new ChildHealthAssessmentEngine();
      const food: FoodLabel = createAdditiveFood();
      const profile: FamilyProfile = createChildProfile();

      const result: ChildHealthAssessment = engine.assess(food, profile, 1000, 50);

      expect(result.overallSafetyScore).assertLargerOrEqual(0);
      expect(result.overallSafetyScore).assertLessOrEqual(100);
    });
  });
}
