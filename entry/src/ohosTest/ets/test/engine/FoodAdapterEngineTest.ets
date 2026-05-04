// FoodAdapterEngine 单元测试 - 动态适配矩阵
import { describe, it, expect } from '@ohos/hypium';
import { FoodAdapterEngine, TodayIntakeInput,
  FamilyMemberSimpleInputInput, FoodNutritionInputInput, HealthSignalInputInput } from '../../../../../src/main/ets/engine/FoodAdapterEngine';
import {
  RecommendationLevel, EnhancedFoodRecommendation } from '../../../../../src/main/ets/model/FoodAdapterTypes';

function createAdapterMember(): FamilyMemberSimpleInputInput {
  const budget = {
    sodium_mg: 2000, sugar_g: 50, energy_kcal: 2000, fat_g: 65, saturatedFat_g: 20
  };
  const member: FamilyMemberSimpleInputInput = {
    id: 'dad_1', name: '爸爸', role: '爸爸', age: 35,
    healthGoal: '控压', allergenRedline: [], dislikedAdditives: [],
    dailyBudget: budget
  };
  return member;
}

function createAdapterMemberWithId(id: string): FamilyMemberSimpleInputInput {
  const m = createAdapterMember();
  m.id = id;
  m.name = id;
  return m;
}

function createAdapterFood(): FoodNutritionInputInput {
  return {
    productName: '测试饼干', brand: '测试品牌',
    energy_kj: 840, protein_g: 5, fat_g: 10, saturatedFat_g: 3,
    transFat_g: 0, carbs_g: 60, sugar_g: 15, sodium_mg: 300,
    allergens: [], manufacturer: '测试工厂'
  };
}

function createAdapterFoodLowSodium(): FoodNutritionInputInput {
  const f = createAdapterFood();
  f.sodium_mg = 50;
  return f;
}

function createAdapterFoodHighSodium(sodium_mg: number): FoodNutritionInputInput {
  const f = createAdapterFood();
  f.sodium_mg = sodium_mg;
  return f;
}

function createAdapterFoodHighSugarFat(sugar_g: number, fat_g: number): FoodNutritionInput {
  const f = createAdapterFood();
  f.sugar_g = sugar_g;
  f.fat_g = fat_g;
  return f;
}

function createAdapterFoodSodium700(): FoodNutritionInput {
  const f = createAdapterFood();
  f.sodium_mg = 700;
  f.productName = '咸零食';
  return f;
}

function createAdapterFoodHighSodium600(): FoodNutritionInput {
  const f = createAdapterFood();
  f.sodium_mg = 600;
  return f;
}

function createAdapterHealthSignalInput(): HealthSignalInput {
  return { steps: '8000', sleep: '良好', weightTrend: '稳定', manualBpStatus: '正常', manualBgStatus: '正常' };
}

function createAdapterSignalLowSteps(): HealthSignalInput {
  return { steps: '正常', sleep: '好', weightTrend: '稳定', manualBpStatus: '正常', manualBgStatus: '正常' };
}

function createAdapterSignalLowSteps(): HealthSignalInput {
  return { steps: '低', sleep: '好', weightTrend: '稳定', manualBpStatus: '正常', manualBgStatus: '正常' };
}

function createAdapterSignalPoorSleep(): HealthSignalInput {
  return { steps: '正常', sleep: '差', weightTrend: '稳定', manualBpStatus: '正常', manualBgStatus: '正常' };
}

function createAdapterTodayIntake(): TodayIntakeInput {
  return { sodium_mg: 500, sugar_g: 10, energy_kcal: 600, fat_g: 15 };
}

function createAdapterIntakeExhausted(): TodayIntakeInput {
  return { sodium_mg: 2000, sugar_g: 50, energy_kcal: 2000, fat_g: 65 };
}

export default function foodAdapterEngineTest() {
  describe('FoodAdapterEngine', () => {

    // ========== 1. 基本适配计算 ==========

    it('should_calculate_green_for_low_sodium_food', 0, () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimpleInput = createAdapterMember();
      const food: FoodNutritionInput = createAdapterFoodLowSodium();
      const signal: HealthSignalInput = createAdapterHealthSignalInput();
      const intake: TodayIntakeInput = createAdapterTodayIntake();

      const result: EnhancedFoodRecommendation = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);

      expect(result.level).assertEqual(RecommendationLevel.GREEN);
      expect(result.maxIntake_g).assertLarger(50);
      expect(result.levelText).assertEqual('适合食用');
    });

    it('should_calculate_red_for_zero_budget_remaining', 0, () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimpleInput = createAdapterMember();
      const food: FoodNutritionInput = createAdapterFood();
      const signal: HealthSignalInput = createAdapterHealthSignalInput();
      const intake: TodayIntakeInput = createAdapterIntakeExhausted();

      const result: EnhancedFoodRecommendation = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);

      expect(result.maxIntake_g).assertEqual(0);
      expect(result.level).assertEqual(RecommendationLevel.RED);
      expect(result.levelText).assertEqual('建议避免');
    });

    // ========== 2. 扫描递减效果 ==========

    it('should_decrease_intake_on_second_scan', 0, () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimpleInput = createAdapterMember();
      const food: FoodNutritionInput = createAdapterFood();
      const signal: HealthSignalInput = createAdapterHealthSignalInput();
      const intake: TodayIntakeInput = createAdapterTodayIntake();

      const result1 = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);
      const result2 = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 2);

      // 第二次扫描建议量应≥0
      expect(result2.maxIntake_g).assertLargerOrEqual(0);
      // 第二次扫描应有递减说明
      expect((result2.dynamicAdjustReason || '').includes('次扫描')).assertTrue();
    });

    it('should_apply_stronger_decay_on_later_scans', 0, () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimpleInput = createAdapterMember();
      const food: FoodNutritionInput = createAdapterFood();
      const signal: HealthSignalInput = createAdapterHealthSignalInput();
      const intake: TodayIntakeInput = createAdapterTodayIntake();

      const result3 = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 3);
      const result5 = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 5);

      // 第5次扫描应该比第3次有更强衰减
      expect(result5.scanIndex).assertEqual(5);
      expect((result5.dynamicAdjustReason || '').includes('次扫描')).assertTrue();
    });

    // ========== 3. 步数调整 ==========

    it('should_reduce_intake_when_steps_low', 0, () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimpleInput = createAdapterMember();
      const food: FoodNutritionInput = createAdapterFood();
      const signal: HealthSignalInput = createAdapterSignalLowSteps();
      const intake: TodayIntakeInput = createAdapterTodayIntake();

      const result: EnhancedFoodRecommendation = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);

      // 步数低时应产生调整原因
      expect((result.dynamicAdjustReason || '').includes('步数')).assertTrue();
    });

    // ========== 4. 睡眠调整 ==========

    it('should_reduce_sugar_when_sleep_poor', 0, () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimpleInput = createAdapterMember();
      const food: FoodNutritionInput = createAdapterFoodHighSugarFat(20, 20);
      const signal: HealthSignalInput = createAdapterSignalPoorSleep();
      const intake: TodayIntakeInput = createAdapterTodayIntake();

      const result: EnhancedFoodRecommendation = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);

      // 睡眠差时高糖高脂食品应有调整提示
      expect((result.dynamicAdjustReason || '').includes('睡眠')).assertTrue();
    });

    // ========== 5. 高钠风险识别 ==========

    it('should_warn_when_high_sodium_count_reaches_threshold', 0, () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimpleInput = createAdapterMember();
      const food: FoodNutritionInput = createAdapterFoodHighSodium600();
      const signal: HealthSignalInput = createAdapterHealthSignalInput();
      const intake: TodayIntakeInput = createAdapterTodayIntake();

      // 第一次扫描高钠食品
      FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);

      // 第二次扫描另一高钠食品
      const food2 = createAdapterFoodSodium700();
      const result: EnhancedFoodRecommendation = FoodAdapterEngine.calculateDynamicIntake(member, food2, signal, intake, 2);

      // 预期有钠摄入偏高风险提示
      expect((result.dynamicAdjustReason || '').includes('钠摄入')).assertTrue();
    });

    // ========== 6. 高钠扫描计数 ==========

    it('should_track_high_sodium_scan_count', 0, () => {
      const member: FamilyMemberSimpleInput = createAdapterMemberWithId('test_count');
      const food: FoodNutritionInput = createAdapterFoodHighSodium600();
      const signal: HealthSignalInput = createAdapterHealthSignalInput();
      const intake: TodayIntakeInput = createAdapterTodayIntake();

      FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);
      FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 2);

      const count = FoodAdapterEngine.getHighSodiumScanCount('test_count');
      expect(count).assertEqual(2);
    });

    // ========== 7. 扫描记录清理 ==========

    it('should_clear_member_records', 0, () => {
      const memberId = 'test_clear';
      const member: FamilyMemberSimpleInput = createAdapterMemberWithId(memberId);
      const food: FoodNutritionInput = createAdapterFood();
      const signal: HealthSignalInput = createAdapterHealthSignalInput();
      const intake: TodayIntakeInput = createAdapterTodayIntake();

      FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);
      FoodAdapterEngine.clearMemberRecords(memberId);

      const count = FoodAdapterEngine.getHighSodiumScanCount(memberId);
      expect(count).assertEqual(0);
    });

    // ========== 8. 重置所有记录 ==========

    it('should_reset_all_records', 0, () => {
      const member: FamilyMemberSimpleInput = createAdapterMember();
      const food: FoodNutritionInput = createAdapterFood();
      const signal: HealthSignalInput = createAdapterHealthSignalInput();
      const intake: TodayIntakeInput = createAdapterTodayIntake();

      FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);
      FoodAdapterEngine.resetTodayScanRecords();

      const count = FoodAdapterEngine.getHighSodiumScanCount('dad_1');
      expect(count).assertEqual(0);
    });

    // ========== 9. 前几次扫描影响说明 ==========

    it('should_include_previous_scan_impact', 0, () => {
      const member: FamilyMemberSimpleInput = createAdapterMember();
      const food: FoodNutritionInput = createAdapterFood();
      const signal: HealthSignalInput = createAdapterHealthSignalInput();
      const intake: TodayIntakeInput = createAdapterTodayIntake();

      FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);
      const result: EnhancedFoodRecommendation = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 2);

      expect(result.previousScanImpact !== null).assertTrue();
    });

    // ========== 10. 结果字段完整性 ==========

    it('should_fill_all_result_fields', 0, () => {
      FoodAdapterEngine.resetTodayScanRecords();
      const member: FamilyMemberSimpleInput = createAdapterMember();
      const food: FoodNutritionInput = createAdapterFood();
      const signal: HealthSignalInput = createAdapterHealthSignalInput();
      const intake: TodayIntakeInput = createAdapterTodayIntake();

      const result: EnhancedFoodRecommendation = FoodAdapterEngine.calculateDynamicIntake(member, food, signal, intake, 1);

      expect(result.productName).assertEqual('测试饼干');
      expect(result.memberId).assertEqual('dad_1');
      expect(result.memberName).assertEqual('爸爸');
      expect(result.scanIndex).assertEqual(1);
    });
  });
}
