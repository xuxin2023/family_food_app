// PersonalizedRecommendEngine 单元测试 - 个性化数据驱动推荐引擎
import { describe, it, expect } from '@ohos/hypium';
import { PersonalizedRecommendEngine, PersonalizedContext, PersonalizedRecommendation, PersonalizedFactor } from '../../../../../src/main/ets/engine/PersonalizedRecommendEngine';
import { FamilyProfile, AgeGroup, HealthGoal } from '../../../../../src/main/ets/model/FamilyProfile';
import { HealthSignal, StepLevel, BpStatus, BsStatus, HeartRateZone, StressLevel, SleepStatus } from '../../../../../src/main/ets/model/HealthSignal';
import { FoodLabel, NutritionPer100g } from '../../../../../src/main/ets/model/FoodLabel';
import { NutritionTarget } from '../../../../../src/main/ets/model/NutritionTarget';
import { DailyBudget } from '../../../../../src/main/ets/model/DailyBudget';

function createPerProfile(): FamilyProfile {
  const profile: FamilyProfile = new FamilyProfile();
  profile.memberId = 'member_dad';
  profile.nickname = '爸爸';
  profile.ageGroup = AgeGroup.ADULT;
  profile.healthGoals = [HealthGoal.CONTROL_BP];
  profile.allergens = [];
  return profile;
}

function createPerSignal(): HealthSignal {
  const signal: HealthSignal = new HealthSignal();
  signal.memberId = 'member_dad';
  signal.stepLevel = StepLevel.NORMAL;
  signal.sleepStatus = SleepStatus.GOOD;
  signal.manualBpStatus = BpStatus.NORMAL;
  signal.manualBsStatus = BsStatus.NORMAL;
  return signal;
}

function createPerTarget(): NutritionTarget {
  const target: NutritionTarget = new NutritionTarget();
  target.memberId = 'member_dad';
  return target;
}

function createPerBudget(): DailyBudget {
  const budget: DailyBudget = new DailyBudget();
  budget.memberId = 'member_dad';
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

function createPerContext(): PersonalizedContext {
  const ctx: PersonalizedContext = new PersonalizedContext();
  ctx.profile = createPerProfile();
  ctx.signal = createPerSignal();
  ctx.target = createPerTarget();
  ctx.budget = createPerBudget();
  ctx.recentDietSodiumAvg = 0;
  ctx.recentDietSugarAvg = 0;
  ctx.consecutiveHighSodiumDays = 0;
  ctx.checkupAbnormalItems = [];
  return ctx;
}

function createPerFood(): FoodLabel {
  const food: FoodLabel = new FoodLabel();
  food.foodId = 'food_001';
  food.foodName = '低钠全麦面包';
  food.ingredients = ['全麦粉', '酵母', '水'];
  food.nutrition = new NutritionPer100g();
  food.nutrition.sodium = 80;
  food.nutrition.sugar = 3;
  food.nutrition.calories = 200;
  food.nutrition.fat = 2;
  food.nutrition.protein = 8;
  food.nutrition.carbohydrate = 35;
  return food;
}

export default function personalizedRecommendEngineTest() {
  describe('PersonalizedRecommendEngine', () => {

    // ========== 1. recommend 基本推荐 ==========

    it('should_recommend_for_member', 0, () => {
      const engine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();
      const food: FoodLabel = createPerFood();
      const ctx: PersonalizedContext = createPerContext();

      const result: PersonalizedRecommendation = engine.recommend(food, ctx);

      expect(result.memberId).assertEqual('member_dad');
      expect(result.foodId).assertEqual('food_001');
      expect(result.factors.length).assertEqual(5);
      expect(result.overallScore).assertLargerOrEqual(0);
      expect(result.overallScore).assertLessOrEqual(100);
      expect(result.level.length > 0).assertTrue();
    });

    it('should_score_high_for_healthy_food_with_control_bp_goal', 0, () => {
      const engine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();
      const food: FoodLabel = createPerFood();
      const ctx: PersonalizedContext = createPerContext();

      const result: PersonalizedRecommendation = engine.recommend(food, ctx);

      expect(result.overallScore).assertLargerOrEqual(60);
    });

    it('should_score_low_for_high_sodium_food_with_control_bp_goal', 0, () => {
      const engine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();
      const food: FoodLabel = new FoodLabel();
      food.foodId = 'food_high_na';
      food.foodName = '咸鱼';
      food.ingredients = ['鱼', '盐', '味精'];
      food.nutrition = new NutritionPer100g();
      food.nutrition.sodium = 800;
      food.nutrition.sugar = 2;
      food.nutrition.calories = 200;
      food.nutrition.fat = 10;
      food.nutrition.protein = 15;
      const ctx: PersonalizedContext = createPerContext();

      const result: PersonalizedRecommendation = engine.recommend(food, ctx);

      expect(result.overallScore).assertLess(70);
    });

    // ========== 2. 健康目标契合度 ==========

    it('should_align_with_control_sugar_goal', 0, () => {
      const engine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();
      const food: FoodLabel = new FoodLabel();
      food.foodId = 'food_low_sugar';
      food.foodName = '无糖酸奶';
      food.ingredients = ['生牛乳', '乳酸菌'];
      food.nutrition = new NutritionPer100g();
      food.nutrition.sodium = 50;
      food.nutrition.sugar = 2;
      food.nutrition.calories = 80;
      food.nutrition.fat = 3;
      food.nutrition.protein = 10;
      const ctx: PersonalizedContext = createPerContext();
      ctx.profile.healthGoals = [HealthGoal.CONTROL_SUGAR];

      const result: PersonalizedRecommendation = engine.recommend(food, ctx);

      const goalFactor: PersonalizedFactor | undefined = result.factors.find(
        (f: PersonalizedFactor) => f.name === '健康目标契合度'
      );
      expect(goalFactor !== undefined).assertTrue();
      if (goalFactor !== undefined) {
        expect(goalFactor.score).assertLargerOrEqual(80);
      }
    });

    it('should_penalize_high_sugar_for_lose_fat_goal', 0, () => {
      const engine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();
      const food: FoodLabel = new FoodLabel();
      food.foodId = 'food_high_cal';
      food.foodName = '炸鸡';
      food.ingredients = ['鸡肉', '面粉', '油'];
      food.nutrition = new NutritionPer100g();
      food.nutrition.sodium = 400;
      food.nutrition.sugar = 20;
      food.nutrition.calories = 500;
      food.nutrition.fat = 25;
      food.nutrition.protein = 15;
      const ctx: PersonalizedContext = createPerContext();
      ctx.profile.healthGoals = [HealthGoal.LOSE_FAT];

      const result: PersonalizedRecommendation = engine.recommend(food, ctx);

      expect(result.overallScore).assertLess(60);
    });

    // ========== 3. 健康信号影响 ==========

    it('should_penalize_high_sodium_when_bp_high', 0, () => {
      const engine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();
      const food: FoodLabel = new FoodLabel();
      food.foodId = 'food_na';
      food.foodName = '酱油';
      food.ingredients = ['大豆', '小麦', '盐'];
      food.nutrition = new NutritionPer100g();
      food.nutrition.sodium = 500;
      food.nutrition.sugar = 5;
      food.nutrition.calories = 50;
      food.nutrition.fat = 0;
      food.nutrition.protein = 5;
      const ctx: PersonalizedContext = createPerContext();
      ctx.signal.manualBpStatus = BpStatus.HIGH;

      const result: PersonalizedRecommendation = engine.recommend(food, ctx);

      const signalFactor: PersonalizedFactor | undefined = result.factors.find(
        (f: PersonalizedFactor) => f.name === '健康信号影响'
      );
      expect(signalFactor !== undefined).assertTrue();
      if (signalFactor !== undefined) {
        expect(signalFactor.score).assertLess(70);
      }
    });

    it('should_boost_low_sodium_when_bp_high', 0, () => {
      const engine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();
      const food: FoodLabel = createPerFood();
      const ctx: PersonalizedContext = createPerContext();
      ctx.signal.manualBpStatus = BpStatus.HIGH;

      const result: PersonalizedRecommendation = engine.recommend(food, ctx);

      const signalFactor: PersonalizedFactor | undefined = result.factors.find(
        (f: PersonalizedFactor) => f.name === '健康信号影响'
      );
      expect(signalFactor !== undefined).assertTrue();
      if (signalFactor !== undefined) {
        expect(signalFactor.score).assertLarger(70);
      }
    });

    // ========== 4. 体检约束 ==========

    it('should_penalize_when_checkup_bp_abnormal', 0, () => {
      const engine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();
      const food: FoodLabel = new FoodLabel();
      food.foodId = 'food_salt';
      food.foodName = '腊肉';
      food.ingredients = ['猪肉', '盐'];
      food.nutrition = new NutritionPer100g();
      food.nutrition.sodium = 600;
      food.nutrition.sugar = 2;
      food.nutrition.calories = 300;
      food.nutrition.fat = 15;
      food.nutrition.protein = 20;
      const ctx: PersonalizedContext = createPerContext();
      ctx.checkupAbnormalItems = ['收缩压', '舒张压'];

      const result: PersonalizedRecommendation = engine.recommend(food, ctx);

      const checkupFactor: PersonalizedFactor | undefined = result.factors.find(
        (f: PersonalizedFactor) => f.name === '体检约束'
      );
      expect(checkupFactor !== undefined).assertTrue();
      if (checkupFactor !== undefined) {
        expect(checkupFactor.score).assertLess(60);
      }
    });

    it('should_penalize_purine_when_uric_acid_abnormal', 0, () => {
      const engine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();
      const food: FoodLabel = new FoodLabel();
      food.foodId = 'food_purine';
      food.foodName = '海鲜火锅';
      food.ingredients = ['海鲜', '肉汤', '盐'];
      food.nutrition = new NutritionPer100g();
      food.nutrition.sodium = 300;
      food.nutrition.sugar = 3;
      food.nutrition.calories = 200;
      food.nutrition.fat = 8;
      food.nutrition.protein = 15;
      const ctx: PersonalizedContext = createPerContext();
      ctx.checkupAbnormalItems = ['尿酸'];

      const result: PersonalizedRecommendation = engine.recommend(food, ctx);

      const checkupFactor: PersonalizedFactor | undefined = result.factors.find(
        (f: PersonalizedFactor) => f.name === '体检约束'
      );
      expect(checkupFactor !== undefined).assertTrue();
      if (checkupFactor !== undefined) {
        expect(checkupFactor.score).assertLess(60);
      }
    });

    // ========== 5. 行为模式 & 数据置信度 ==========

    it('should_penalize_consecutive_high_sodium_days', 0, () => {
      const engine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();
      const food: FoodLabel = new FoodLabel();
      food.foodId = 'food_mid_na';
      food.foodName = '午餐肉';
      food.ingredients = ['猪肉', '淀粉', '盐'];
      food.nutrition = new NutritionPer100g();
      food.nutrition.sodium = 400;
      food.nutrition.sugar = 3;
      food.nutrition.calories = 250;
      food.nutrition.fat = 12;
      food.nutrition.protein = 10;
      const ctx: PersonalizedContext = createPerContext();
      ctx.consecutiveHighSodiumDays = 5;

      const result: PersonalizedRecommendation = engine.recommend(food, ctx);

      const behaviorFactor: PersonalizedFactor | undefined = result.factors.find(
        (f: PersonalizedFactor) => f.name === '行为模式'
      );
      expect(behaviorFactor !== undefined).assertTrue();
      if (behaviorFactor !== undefined) {
        expect(behaviorFactor.score).assertLess(70);
      }
    });

    it('should_compute_low_confidence_without_data', 0, () => {
      const engine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();
      const food: FoodLabel = createPerFood();
      const ctx: PersonalizedContext = new PersonalizedContext();
      ctx.profile = new FamilyProfile();
      ctx.profile.memberId = 'member_new';
      ctx.profile.nickname = '新用户';
      ctx.profile.ageGroup = AgeGroup.ADULT;
      ctx.profile.healthGoals = [];
      ctx.profile.allergens = [];
      ctx.signal = new HealthSignal();
      ctx.signal.memberId = 'member_new';
      ctx.target = new NutritionTarget();
      ctx.budget = new DailyBudget();

      const result: PersonalizedRecommendation = engine.recommend(food, ctx);

      expect(result.dataConfidence).assertLess(0.5);
    });

    it('should_generate_personalized_summary', 0, () => {
      const engine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();
      const food: FoodLabel = createPerFood();
      const ctx: PersonalizedContext = createPerContext();

      const result: PersonalizedRecommendation = engine.recommend(food, ctx);

      expect(result.personalizedSummary.includes('爸爸')).assertTrue();
    });

    // ========== 6. 边界条件 ==========

    it('should_handle_zero_budget_remaining', 0, () => {
      const engine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();
      const food: FoodLabel = createPerFood();
      const ctx: PersonalizedContext = createPerContext();
      ctx.budget.sodiumRemaining = 0;
      ctx.budget.sugarRemaining = 0;
      ctx.budget.calorieRemaining = 0;

      const result: PersonalizedRecommendation = engine.recommend(food, ctx);

      expect(result.overallScore).assertLargerOrEqual(0);
      expect(result.overallScore).assertLessOrEqual(100);
    });

    it('should_generate_urgency_note_for_critical_context', 0, () => {
      const engine: PersonalizedRecommendEngine = new PersonalizedRecommendEngine();
      const food: FoodLabel = new FoodLabel();
      food.foodId = 'food_bad';
      food.foodName = '高钠高糖食品';
      food.ingredients = ['盐', '糖', '油'];
      food.nutrition = new NutritionPer100g();
      food.nutrition.sodium = 600;
      food.nutrition.sugar = 25;
      food.nutrition.calories = 400;
      food.nutrition.fat = 20;
      food.nutrition.protein = 3;
      const ctx: PersonalizedContext = createPerContext();
      ctx.checkupAbnormalItems = ['收缩压', '空腹血糖'];

      const result: PersonalizedRecommendation = engine.recommend(food, ctx);

      expect(result.urgencyNote.length > 0 || result.overallScore < 40).assertTrue();
    });
  });
}
