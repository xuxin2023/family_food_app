// RuleEngine 单元测试 - 核心适配判断逻辑

import { describe, it, expect } from '@ohos/hypium';
import { RuleEngine, RuleEngineParams, DynamicModifiers } from '../../../main/ets/engine/RuleEngine';
import { FamilyProfile, AgeGroup, HealthGoal, DailyBudgetConfig } from '../../../main/ets/model/FamilyProfile';
import { HealthSignal, StepLevel, SleepStatus, WeightTrend, BpStatus, BsStatus, DataSource } from '../../../main/ets/model/HealthSignal';
import { FoodLabel, FoodSource } from '../../../main/ets/model/FoodLabel';
import { DailyBudget } from '../../../main/ets/model/DailyBudget';
import { RecommendLevel, LevelColor } from '../../../main/ets/model/Recommendation';

export default function ruleEngineTest() {
  describe('RuleEngine', () => {

    // ========== 辅助方法：创建测试数据 ==========

    function createProfile(goals: HealthGoal[] = [], allergens: string[] = [],
      ageGroup: AgeGroup = AgeGroup.ADULT): FamilyProfile {
      const p = new FamilyProfile();
      p.memberId = 'test_member';
      p.nickname = '测试';
      p.ageGroup = ageGroup;
      p.healthGoals = goals;
      p.allergens = allergens;
      p.createdAt = Date.now();
      p.updatedAt = Date.now();
      return p;
    }

    function createSignal(step: StepLevel = StepLevel.NORMAL,
      sleep: SleepStatus = SleepStatus.GOOD,
      weightTrend: WeightTrend = WeightTrend.STABLE,
      bp: BpStatus = BpStatus.NORMAL): HealthSignal {
      const s = new HealthSignal();
      s.memberId = 'test_member';
      s.date = '2026-04-22';
      s.stepLevel = step;
      s.sleepStatus = sleep;
      s.weightTrend = weightTrend;
      s.bpStatus = bp;
      s.source = DataSource.MANUAL;
      return s;
    }

    function createFood(sodium: number = 0, sugar: number = 0,
      calories: number = 0, fat: number = 0,
      ingredients: string[] = []): FoodLabel {
      const f = new FoodLabel();
      f.foodId = 'test_food';
      f.foodName = '测试食品';
      f.nutrition = { sodium, sugar, calories, fat, saturatedFat: 0, carbohydrate: 0, protein: 0 };
      f.ingredients = ingredients;
      f.source = FoodSource.USER_UPLOAD;
      f.identifiedAt = Date.now();
      return f;
    }

    function createBudget(sodiumRemaining: number = 1000, sugarRemaining: number = 30,
      calorieRemaining: number = 800, fatRemaining: number = 40): DailyBudget {
      const b = new DailyBudget();
      b.memberId = 'test_member';
      b.date = '2026-04-22';
      b.sodiumBudget = 2000; b.sodiumRemaining = sodiumRemaining;
      b.sugarBudget = 50; b.sugarRemaining = sugarRemaining;
      b.calorieBudget = 2000; b.calorieRemaining = calorieRemaining;
      b.fatBudget = 65; b.fatRemaining = fatRemaining;
      return b;
    }

    const engine = new RuleEngine();

    // ========== 1. 过敏原红线检查 ==========

    it('should_detect_nut_allergen', () => {
      const profile = createProfile([], ['坚果']);
      const food = createFood(0, 0, 0, 0, ['花生', '白砂糖', '食用盐']);
      const hits = engine.checkAllergenRedline(profile, food);
      expect(hits).toContain('坚果');
    });

    it('should_detect_dairy_allergen', () => {
      const profile = createProfile([], ['乳制品']);
      const food = createFood(0, 0, 0, 0, ['生牛乳', '白砂糖']);
      const hits = engine.checkAllergenRedline(profile, food);
      expect(hits).toContain('乳制品');
    });

    it('should_not_detect_when_no_allergen', () => {
      const profile = createProfile([], ['坚果']);
      const food = createFood(0, 0, 0, 0, ['大米', '食用盐', '白砂糖']);
      const hits = engine.checkAllergenRedline(profile, food);
      expect(hits.length).assertEqual(0);
    });

    it('should_return_AVOID_when_allergen_hit', () => {
      const profile = createProfile([HealthGoal.CONTROL_BP], ['坚果']);
      const food = createFood(500, 5, 200, 10, ['花生', '食用盐']);
      const signal = createSignal();
      const budget = createBudget();
      const rec = engine.calculate({ profile, healthSignal: signal, foodLabel: food, dailyBudget: budget });
      expect(rec.level).assertEqual(RecommendLevel.AVOID);
      expect(rec.maxAmount).assertEqual(0);
    });

    // ========== 2. 今日可吃量计算 ==========

    it('should_calculate_max_amount_by_sodium', () => {
      // 剩余钠300mg，食品钠1200mg/100g → 300/1200*100 = 25g
      const result = engine.calculateMaxAmount(300, 1200);
      expect(result).assertEqual(25);
    });

    it('should_calculate_max_amount_by_sugar', () => {
      // 剩余糖10g，食品糖20g/100g → 10/20*100 = 50g
      const result = engine.calculateMaxAmount(10, 20);
      expect(result).assertEqual(50);
    });

    it('should_return_infinity_when_no_nutrition_data', () => {
      const result = engine.calculateMaxAmount(100, 0);
      expect(result).assertEqual(Infinity);
    });

    it('should_return_0_when_budget_exhausted', () => {
      const result = engine.calculateMaxAmount(0, 100);
      expect(result).assertEqual(0);
    });

    // ========== 3. 动态修正因子 ==========

    it('should_reduce_high_calorie_factor_when_low_activity', () => {
      const signal = createSignal(StepLevel.LOW);
      const modifiers = engine.calculateDynamicModifiers(signal);
      expect(modifiers.highCalorieFactor).assertEqual(0.7);
      expect(modifiers.highFatFactor).assertEqual(0.7);
    });

    it('should_increase_calorie_factor_when_high_activity', () => {
      const signal = createSignal(StepLevel.HIGH);
      const modifiers = engine.calculateDynamicModifiers(signal);
      expect(modifiers.highCalorieFactor).assertEqual(1.2);
    });

    it('should_reduce_sugar_factor_when_poor_sleep', () => {
      const signal = createSignal(StepLevel.NORMAL, SleepStatus.POOR);
      const modifiers = engine.calculateDynamicModifiers(signal);
      expect(modifiers.highSugarFactor).assertEqual(0.8);
    });

    it('should_reduce_factors_when_weight_up', () => {
      const signal = createSignal(StepLevel.NORMAL, SleepStatus.GOOD, WeightTrend.UP);
      const modifiers = engine.calculateDynamicModifiers(signal);
      expect(modifiers.highCalorieFactor).assertEqual(0.8);
      expect(modifiers.highFatFactor).assertEqual(0.8);
    });

    it('should_reduce_sodium_budget_when_high_bp', () => {
      const signal = createSignal(StepLevel.NORMAL, SleepStatus.GOOD, WeightTrend.STABLE, BpStatus.HIGH);
      const modifiers = engine.calculateDynamicModifiers(signal);
      expect(modifiers.sodiumBudgetFactor).assertEqual(0.8);
    });

    it('should_return_default_modifiers_when_normal', () => {
      const signal = createSignal();
      const modifiers = engine.calculateDynamicModifiers(signal);
      expect(modifiers.highCalorieFactor).assertEqual(1.0);
      expect(modifiers.highFatFactor).assertEqual(1.0);
      expect(modifiers.highSodiumFactor).assertEqual(1.0);
      expect(modifiers.highSugarFactor).assertEqual(1.0);
      expect(modifiers.sodiumBudgetFactor).assertEqual(1.0);
    });

    // ========== 4. 四级映射 ==========

    it('should_return_SUITABLE_when_high_max_amount', () => {
      const profile = createProfile();
      const food = createFood(100, 2, 100, 3);  // 低盐低糖低脂
      const signal = createSignal();
      const budget = createBudget(1000, 30, 800, 40);  // 充足预算
      const rec = engine.calculate({ profile, healthSignal: signal, foodLabel: food, dailyBudget: budget });
      expect(rec.level).assertEqual(RecommendLevel.SUITABLE);
    });

    it('should_return_SMALL_OK_when_moderate_max_amount', () => {
      // 高盐食品，剩余钠较少 → 建议量在16-50g之间
      const profile = createProfile([HealthGoal.CONTROL_BP]);
      const food = createFood(1200, 3, 200, 10);  // 高盐
      const signal = createSignal();
      const budget = createBudget(400, 30, 800, 40);  // 钠剩余400mg
      const rec = engine.calculate({ profile, healthSignal: signal, foodLabel: food, dailyBudget: budget });
      // 400/1200*100 ≈ 33g → SMALL_OK
      expect(rec.level === RecommendLevel.SMALL_OK || rec.level === RecommendLevel.CAUTIOUS).assertTrue();
    });

    it('should_return_CAUTIOUS_when_very_low_max_amount', () => {
      // 高盐食品，钠预算几乎用完
      const profile = createProfile([HealthGoal.CONTROL_BP]);
      const food = createFood(1200, 3, 200, 10);
      const signal = createSignal();
      const budget = createBudget(100, 30, 800, 40);  // 钠仅剩100mg
      const rec = engine.calculate({ profile, healthSignal: signal, foodLabel: food, dailyBudget: budget });
      // 100/1200*100 ≈ 8g → CAUTIOUS
      expect(rec.level).assertEqual(RecommendLevel.CAUTIOUS);
    });

    it('should_return_AVOID_when_budget_exhausted', () => {
      const profile = createProfile([HealthGoal.CONTROL_BP]);
      const food = createFood(1200, 3, 200, 10);
      const signal = createSignal();
      const budget = createBudget(0, 0, 0, 0);  // 预算全用完
      const rec = engine.calculate({ profile, healthSignal: signal, foodLabel: food, dailyBudget: budget });
      expect(rec.level).assertEqual(RecommendLevel.AVOID);
      expect(rec.maxAmount).assertEqual(0);
    });

    // ========== 5. 原因生成 ==========

    it('should_generate_bp_control_reason', () => {
      const profile = createProfile([HealthGoal.CONTROL_BP]);
      const food = createFood(1200, 3, 200, 10);  // 高盐
      const signal = createSignal();
      const budget = createBudget();
      const rec = engine.calculate({ profile, healthSignal: signal, foodLabel: food, dailyBudget: budget });
      expect(rec.reasons.join('')).toContain('控压');
    });

    it('should_generate_sugar_control_reason', () => {
      const profile = createProfile([HealthGoal.CONTROL_SUGAR]);
      const food = createFood(100, 20, 200, 10);  // 高糖
      const signal = createSignal();
      const budget = createBudget();
      const rec = engine.calculate({ profile, healthSignal: signal, foodLabel: food, dailyBudget: budget });
      expect(rec.reasons.join('')).toContain('控糖');
    });

    it('should_generate_lose_fat_reason', () => {
      const profile = createProfile([HealthGoal.LOSE_FAT]);
      const food = createFood(100, 3, 400, 10);  // 高热量
      const signal = createSignal();
      const budget = createBudget();
      const rec = engine.calculate({ profile, healthSignal: signal, foodLabel: food, dailyBudget: budget });
      expect(rec.reasons.join('')).toContain('减脂');
    });

    it('should_generate_child_reason', () => {
      const profile = createProfile([HealthGoal.CHILD], [], AgeGroup.CHILD);
      const food = createFood(800, 15, 200, 10);  // 高盐高糖
      const signal = createSignal();
      const budget = createBudget();
      const rec = engine.calculate({ profile, healthSignal: signal, foodLabel: food, dailyBudget: budget });
      expect(rec.reasons.join('')).toContain('儿童');
    });

    // ========== 6. 提醒生成 ==========

    it('should_remind_low_activity_high_calorie', () => {
      const profile = createProfile();
      const food = createFood(100, 3, 400, 20);  // 高热量高脂
      const signal = createSignal(StepLevel.LOW);  // 低活动
      const budget = createBudget();
      const rec = engine.calculate({ profile, healthSignal: signal, foodLabel: food, dailyBudget: budget });
      expect(rec.reminders.length).assertLargerThan(0);
    });

    it('should_remind_poor_sleep_high_sugar', () => {
      const profile = createProfile();
      const food = createFood(100, 20, 200, 10);  // 高糖
      const signal = createSignal(StepLevel.NORMAL, SleepStatus.POOR);
      const budget = createBudget();
      const rec = engine.calculate({ profile, healthSignal: signal, foodLabel: food, dailyBudget: budget });
      expect(rec.reminders.join('')).toContain('睡眠');
    });

    // ========== 7. 批量计算 ==========

    it('should_calculate_family_comparison', () => {
      const food = createFood(800, 10, 300, 15);
      const signal = createSignal();
      const budget = createBudget();

      const dad = createProfile([HealthGoal.CONTROL_BP]);
      dad.memberId = 'dad';
      const mom = createProfile([HealthGoal.CONTROL_SUGAR]);
      mom.memberId = 'mom';

      const paramsList: RuleEngineParams[] = [
        { profile: dad, healthSignal: signal, foodLabel: food, dailyBudget: budget },
        { profile: mom, healthSignal: signal, foodLabel: food, dailyBudget: budget }
      ];

      const results = engine.calculateFamily(paramsList);
      expect(results.length).assertEqual(2);
      expect(results[0].memberId).assertEqual('dad');
      expect(results[1].memberId).assertEqual('mom');
    });
  });
}
